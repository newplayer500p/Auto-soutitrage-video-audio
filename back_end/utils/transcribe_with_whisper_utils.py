# pip install faster-whisper
from pathlib import Path
from typing import Any, Dict, Optional, Tuple
import logging

try:
    from faster_whisper import WhisperModel
    HAS_FW = True
except Exception as e:
    HAS_FW = False

def transcribe_with_faster_whisper_auto(
    logger: logging.Logger,
    audio_path: Path,
    model_name: str = "medium",     # mettre "medium" pour meilleure qualité que small
    device: str = "cuda",
    language: str = "en",
    temperature: float = 0.0,
    beam_size: int = 5,
    reuse: bool = True,
    whisper_models: Dict[Tuple[str, str, str], Any] = {}
) -> dict:
    if not HAS_FW:
        raise RuntimeError("faster-whisper non installé. 'pip install faster-whisper'")

    # essayer d'abord la quantisation int8 (meilleur ratio qualité/VRAM)
    try_types = ["int8", "float32"]  # int8 first, fallback to float32 (compatible avec ta GPU)
    last_exc = None

    for compute_type in try_types:
        key = (model_name, device, compute_type)
        try:
            if reuse and key in whisper_models:
                model = whisper_models[key]
            else:
                logger.info("Chargement faster-whisper model=%s compute_type=%s device=%s", model_name, compute_type, device)
                model = WhisperModel(model_name, device=device, compute_type=compute_type)
                if reuse:
                    whisper_models[key] = model

            logger.info("Transcription (faster-whisper) de %s (lang=%s) with %s...", audio_path, language, compute_type)
            segments_iter, info = model.transcribe(
                str(audio_path),
                language=language,
                beam_size=beam_size,
                temperature=temperature,
                task="transcribe"
            )

            out_segments = [
                {"start": float(s.start), "end": float(s.end), "text": s.text.strip()}
                for s in segments_iter
                if (s.text or "").strip()
            ]
            return {"text": " ".join(s["text"] for s in out_segments), "segments": out_segments, "info": info, "compute_type": compute_type}
        except Exception as exc:
            logger.warning("Échec avec compute_type=%s : %s", compute_type, str(exc))
            last_exc = exc
            # essayer suivant

    # si tout échoue, remonter l'erreur
    raise RuntimeError("Impossible de charger/transcrire avec faster-whisper (essayé int8 et float32). Dernière erreur: " + str(last_exc))
