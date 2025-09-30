import logging
from pathlib import Path
from typing import List, Dict, Any, Tuple

from utils.decoupage.segmenter import segment_phrases_punct_based
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

    phrase_segments = segment_phrases_punct_based(
        aligned_segments,
        silence_threshold=0.6,
        min_duration_for_punct_split=1.0,
        max_words_per_segment=16,
        max_segment_duration=6.0,
        punctuation_chars=",.!?;:"
    )

    return phrase_segments, lang