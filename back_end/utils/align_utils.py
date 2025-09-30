import logging
from pathlib import Path
from typing import List, Dict, Any, Tuple
import re

from utils.decoupage.segmenter import segment_phrases
from .upgrade_with_whisperx_utils import transcribe_and_align


logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")

def build_phrases(
    audio_clear_path: Path,
    language: str = "en",
    whisper_model: str = "small",
    device: str = "cuda",
    reuse_models: bool = True,
) -> Tuple[List[Dict[str, Any]], str]:
    """
    Wrapper pratique : appelle transcribe_and_align puis reconstruit des segments par phrase précis.
    Retour: (phrase_segments, detected_language)
    """
    aligned_segments, lang = transcribe_and_align(
        audio_clear_path=audio_clear_path,
        language=language,
        whisper_model=whisper_model,
        device=device,
        reuse_models=reuse_models,
    )

    phrase_segments = segment_phrases(
        aligned_segments,
        silence_threshold=0.5,
        min_words=5,
        max_words=14,
        max_chars=80,
        max_duration=6,
    )

    return phrase_segments, lang