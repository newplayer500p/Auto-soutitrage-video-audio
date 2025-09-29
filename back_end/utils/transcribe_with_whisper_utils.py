# Utiliser whisper "small" (même qualité que la commande CLI)
from pathlib import Path
from typing import Any, Dict, Optional, Tuple

import whisper


def transcribe_with_whisper_small(
    logger,
    audio_path: Path,
    model_name: str = "small",
    device: str = "cuda",
    language: str = "en",
    temperature: float = 0.0,
    beam_size: int = 5,
    reuse: bool = True,
    whisper_models: Dict[Tuple[str, str, Optional[str]], Any] = {}
) -> dict:
    """
    Retourne un dict similaire à la sortie de model.transcribe() CLI,
    contenant notamment la clé 'segments' : liste de {'start','end','text'}.
    """
    key = (model_name, device)
    if reuse and key in whisper_models:
        model = whisper_models[key]
    else:
        logger.info("Chargement modèle whisper (lib) `%s` sur %s...", model_name, device)
        # whisper.load_model accepte device="cpu" or "cuda"
        model = whisper.load_model(model_name, device=device)
        if reuse:
            whisper_models[key] = model

    logger.info("Transcription (whisper lib) de %s (lang=%s)...", audio_path, language)
    # on passe le chemin du fichier (comportement identique à la CLI)
    # temperature et beam_size sont optionnels; tu peux adapter
    result = model.transcribe(str(audio_path), language=language, temperature=temperature, beam_size=beam_size)

    segments = [
        {
            "start": float(s.get("start", s.get("t0", 0.0))),
            "end":   float(s.get("end",   s.get("t1", s.get("start", 0.0)))),
            "text":  (s.get("text") or s.get("caption") or "").strip()
        }
        for s in result.get("segments", [])
        if (s.get("text") or s.get("caption") or "").strip()
    ]

    result["segments"] = segments

    return result