# pip install git+https://github.com/openai/whisper.git
from pathlib import Path
from typing import Any, Dict, Tuple
import logging

try:
    import whisper
    import torch
    HAS_WHISPER = True
except Exception as e:
    HAS_WHISPER = False

def transcribe_with_whisper_auto(
    logger: logging.Logger,
    audio_path: Path,
    model_name: str,     # e.g. "small", "base", "medium"
    device: str,         # "cuda", "cuda:0" or "cpu"
    language: str,
    temperature: float = 0.0,
    beam_size: int = 5,
    reuse: bool = True,
    whisper_models: Dict[Tuple[str, str, str], Any] = {}
) -> dict:
    if not HAS_WHISPER:
        raise RuntimeError("whisper non installé. 'pip install git+https://github.com/openai/whisper.git'")

    # normalize device and check availability
    requested_device = device.lower()
    if "cuda" in requested_device and not torch.cuda.is_available():
        logger.warning("CUDA demandé mais indisponible. Passage en CPU.")
        requested_device = "cpu"

    compute_type = "float32"
    
    key = (model_name, requested_device, compute_type)
    try:
        # récupération du modèle en cache si demandé
        if reuse and key in whisper_models:
            model = whisper_models[key]
        else:
            logger.info("Chargement whisper model=%s compute_type=%s device=%s", model_name, compute_type, requested_device)
            # load_model accepte un paramètre device dans certaines versions,
            # mais pour être sûr on load sur CPU puis on déplace sur device.
            model = whisper.load_model(model_name, download_root=None)  # charge par défaut
            # déplacer sur device
            torch_device = torch.device(requested_device)
            model.to(torch_device)
            
            if reuse:
                whisper_models[key] = model

        logger.info("Transcription (whisper) de %s (lang=%s) with %s...", audio_path, language, compute_type)
        # whisper.Model.transcribe retourne dict avec 'text' et 'segments'
        result = model.transcribe(
            str(audio_path),
            language=language,
            temperature=temperature,
            beam_size=beam_size,
            task="transcribe"
        )

        # normaliser les segments au même format que faster-whisper
        segments = []
        for s in result.get("segments", []):
            segments.append({
                "start": float(s["start"]),
                "end": float(s["end"]),
                "text": s["text"].strip()
            })

        return {
            "text": result.get("text", "").strip(),
            "segments": segments,
            "info": {k: result.get(k) for k in ("language", "language_probs") if k in result},
            "compute_type": compute_type
        }

    except Exception as exc:
        logger.warning("Échec avec compute_type=%s : %s", compute_type, str(exc))
        last_exc = exc
        # essayer suivant compute_type

    raise RuntimeError("Impossible de charger/transcrire avec whisper (essayé float16 et float32). Dernière erreur: " + str(last_exc))
