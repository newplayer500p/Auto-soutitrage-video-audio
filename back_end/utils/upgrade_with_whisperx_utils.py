import logging
from pathlib import Path
from typing import Optional, Tuple, Dict, Any, List

import torch
import whisperx

from .transcribe_with_whisper_utils import transcribe_with_faster_whisper_auto

torch.backends.cuda.matmul.allow_tf32 = True
torch.backends.cudnn.allow_tf32 = True


# caches pour éviter de recharger les modèles à chaque appel
_WHISPER_MODELS: Dict[Tuple[str, str, Optional[str]], Any] = {}
_ALIGN_MODELS: Dict[Tuple[str, str, Optional[str]], Any] = {}

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)



def _resolve_device(device: str) -> str:
    if device.startswith("cuda") and not torch.cuda.is_available():
        logger.warning("CUDA demandé mais pas disponible : basculement vers cpu.")
        return "cpu"
    return device


def _load_align_model(language_code: str, device: str, reuse: bool = True):
    key = (language_code, device)
    if reuse and key in _ALIGN_MODELS:
        return _ALIGN_MODELS[key]

    logger.info("Chargement du modèle d'alignement pour `%s` sur %s ...", language_code, device)
    model_a, metadata = whisperx.load_align_model(language_code=language_code, device=device)
    if reuse:
        _ALIGN_MODELS[key] = (model_a, metadata)
    return model_a, metadata


def transcribe_and_align(
    audio_clear_path: Path,
    language: str = "en",                     # <-- par défaut EN si tu utilises whisper CLI en anglais
    whisper_model: str = "medium",
    device: str = "cuda",
    reuse_models: bool = True,
) -> Tuple[Any, str]:
   
   
    device = _resolve_device(device)

    # charger l'audio (toujours nécessaire pour l'alignement)
    try:
        logger.info("Chargement audio depuis %s", audio_clear_path)
        audio = whisperx.load_audio(str(audio_clear_path))
    except Exception as e:
        logger.exception("Impossible de charger l'audio: %s", e)
        raise

    # -------------- 1) Transcription (choix du back-end) -----------------------
    try:
        logger.info("Transcription via whisper lib (transcribe_with_whisper_small)...")
        result = transcribe_with_faster_whisper_auto(
            logger,
            audio_path=audio_clear_path,
            model_name=whisper_model,
            device=device,
            language=language,
            temperature=0.0,
            beam_size=5,
            reuse=reuse_models,
            whisper_models = _WHISPER_MODELS
        )
    except Exception as e:
        logger.exception("Erreur durant la transcription avec whisper lib: %s", e)
        raise

    if "segments" not in result or not result["segments"]:
        logger.error("La transcription n'a pas renvoyé de segments.")
        raise SystemExit("Arrêt du programme : aucun segment trouvé.")

    # -------------- 2) Alignement mot-à-mot avec whisperx ---------------------
    try:
        model_a, metadata = _load_align_model(language, device, reuse=reuse_models)
        logger.info("Alignement en cours...")
        aligned = whisperx.align(result["segments"], model_a, metadata, audio, device=device)
    except Exception as e:
        logger.exception("Erreur durant l'alignement: %s", e)
        raise

    segments = aligned.get("segments", result.get("segments"))
    detected_language = result.get("language", language)
    logger.info("Terminé: %d segments, langue détectée: %s", len(segments) if segments else 0, detected_language)
    
    return segments, detected_language