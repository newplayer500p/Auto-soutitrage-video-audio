#!/usr/bin/env python3
from pathlib import Path
import os
import logging
import typing

import torch

# demucs API
from demucs.pretrained import get_model
from demucs.separate import load_track
from demucs.apply import apply_model
from demucs.audio import save_audio

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# Cache global pour les modèles chargés : {model_key: model_object}
_MODEL_CACHE: dict[str, torch.nn.Module] = {}


def _ensure_model(model_key: str, device: typing.Union[torch.device, str]):
    """
    Récupère (ou charge) le modèle et le met sur `device`.
    model_key : nom du modèle (ex: "htdemucs" ou signature)
    Retourne le modèle (déjà en eval()).
    """
    dev = torch.device(device)
    cached = _MODEL_CACHE.get(model_key)
    if cached is not None:
        # Si déjà chargé, assure-toi qu'il est sur le bon device
        try:
            cached.to(dev)
        except Exception:
            # certains objets "bag" peuvent nécessiter un move pour chaque sous-modèle
            try:
                for m in getattr(cached, "models", []):
                    m.to(dev)
            except Exception:
                pass
        cached.eval()
        return cached

    logger.info("Chargement du modèle demucs '%s' sur %s ...", model_key, dev)
    try:
        model = get_model(model_key)
    except Exception as e:
        logger.exception("Impossible de charger le modèle %s : %s", model_key, e)
        raise

    # move model (bag) to device
    try:
        model.to(dev)
    except Exception:
        # si c'est un 'bag' avec sous-modèles
        try:
            for m in getattr(model, "models", []):
                m.to(dev)
        except Exception:
            pass

    model.eval()
    _MODEL_CACHE[model_key] = model
    return model


def run_demucs(
    wav_path: Path,
    out_target: Path,
    *,
    single_sig: str = None,    # sig unique, ex: 'a1d90b5c' (si fourni on l'utilise comme clé de modèle)
    model: str = "mdx_q",  # modèle par défaut si single_sig=None
    device: str = "cuda",
    shifts: int = 0,
    jobs: int = 1,
):
    """
    Lance la séparation via l'API Demucs (pas de subprocess).
    - single_sig: si fourni, on utilisera cette clé pour get_model(single_sig)
    - model: nom du modèle sinon (ex: mdx_extra, htdemucs, ...)
    - device: 'cuda' ou 'cpu' (ou torch.device)
    - shifts: nombre de shifts (influence la qualité / temps)
    - jobs: nombre de threads utilisés par torch (torch.set_num_threads)
    Retourne le Path vers le fichier vocals wav (ou None si échec).
    """

    wav_path = Path(wav_path)
    out_target = Path(out_target)

    # optimisation du nombre de threads
    try:
        jobs_int = int(jobs)
        torch.set_num_threads(max(1, jobs_int))
    except Exception:
        pass

    model_key = "htdemucs" if (single_sig and single_sig != "") else model
    # nom de dossier pour la sortie (mimique CLI)
    model_folder = model_key

    # create base output folder similar to CLI behaviour
    output_base = out_target / model_folder / wav_path.stem
    output_base.mkdir(parents=True, exist_ok=True)

    try:
        # Charger (ou récupérer depuis cache) le modèle
        demucs_model = _ensure_model(model_key, device)

        # Charger l'audio (load_track gère ffmpeg & resampling si besoin)
        logger.info("Chargement du wav : %s", wav_path)
        wav = load_track(str(wav_path), audio_channels=2, samplerate=44100)

        # appliquer le modèle
        logger.info("Application du modèle (shifts=%s) ...", shifts)
        with torch.no_grad():
            # apply_model accepte bag (ou modèle) et renvoie (batch, n_sources, channels, samples)
            # on passe wav[None] pour batch=1
            sources = apply_model(demucs_model, wav[None], device=device, shifts=shifts, split=True, progress=False)
            sources = sources[0]  # (n_sources, channels, samples)

        # déterminer les noms de stems fournis par le modèle
        stems = getattr(demucs_model, "sources", None)
        if stems is None:
            # fallback connu
            stems = ["vocals", "drums", "bass", "other"][: sources.shape[0]]

        logger.info("Stems détectés: %s", stems)

        # Si le modèle fournit plusieurs stems mais que l'on veut deux stems (vocals + accompaniment),
        # on recrée vocals + sum(others) pour "no_vocals"
        # Ici on suit la logique CLI '--two-stems=vocals' toujours utilisée dans ton code initial.
        # Si le modèle a un stem 'vocals', on isole; sinon on prend stems[0] comme vocals.
        try:
            idx_vocals = stems.index("vocals")
        except ValueError:
            # pas de stem nommé 'vocals' -> on prend le premier comme voix
            idx_vocals = 0

        vocals_tensor = sources[idx_vocals]  # (channels, samples)
        # sum des autres stems pour l'accompagnement
        other_tensors = [sources[i] for i in range(sources.shape[0]) if i != idx_vocals]
        if other_tensors:
            # sommation (assure compatibilité shape)
            accompaniment = sum(other_tensors)
        else:
            accompaniment = None

        # samplerate (si le bag expose samplerate)
        samplerate = getattr(demucs_model, "samplerate", 44100)

        # Sauvegarde : noms identiques au CLI --filename '{stem}.wav'
        vocals_out = output_base / "vocals.wav"
        save_audio(vocals_tensor.cpu(), str(vocals_out), samplerate=samplerate)
        logger.info("Saved vocals: %s", vocals_out)

        if accompaniment is not None:
            no_vocals_out = output_base / "no_vocals.wav"
            save_audio(accompaniment.cpu(), str(no_vocals_out), samplerate=samplerate)
            logger.info("Saved accompaniment: %s", no_vocals_out)

        # retourne le chemin du fichier vocals (mimique de l'ancien comportement)
        return vocals_out if vocals_out.exists() else None

    except Exception as e:
        logger.exception("Erreur durant la séparation Demucs: %s", e)
        return None


# Petit test rapide si on exécute directement
if __name__ == "__main__":
    import sys
    if len(sys.argv) < 3:
        print("Usage: python demucs_runner_api.py input.wav out_dir [sig_unique]")
        sys.exit(1)

    input_wav = Path(sys.argv[1])
    out_dir = Path(sys.argv[2])
    sig_unique = sys.argv[3] if len(sys.argv) > 3 else None

    res = run_demucs(input_wav, out_dir, single_sig=sig_unique, shifts=0, device=("cuda" if torch.cuda.is_available() else "cpu"), jobs=1)
    print("Result:", res)
