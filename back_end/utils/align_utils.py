from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple
import re

from .upgrade_with_whisperx_utils import transcribe_and_align

PUNCT_END_RE = re.compile(r"[,.?!…]+$")

def _float(x):
    try:
        return float(x)
    except Exception:
        return 0.0

def _word_text(w):
    return (w.get("word") or w.get("text") or "").strip()

def _word_start(w, seg_start=None):
    return _float(w.get("start") if w.get("start") is not None else (seg_start if seg_start is not None else 0.0))

def _word_end(w, seg_end=None, seg_start=None):
    if w.get("end") is not None:
        return _float(w.get("end"))
    # fallback: if no end, use start or segment end
    s = w.get("start")
    if s is not None:
        return _float(s) + 0.05
    return _float(seg_end if seg_end is not None else (seg_start if seg_start is not None else 0.0))


def build_phrase_segments_from_aligned_smart(
    aligned_segments: List[Dict[str, Any]],
    min_words: int = 3,
    max_words: int = 12,
    max_phrase_duration: float = 8.0,
    punctuation_split: bool = True,
) -> List[Dict[str, Any]]:
    phrase_segments: List[Dict[str, Any]] = []
    
    for seg in aligned_segments:
        words = seg.get("words")
        seg_start = _float(seg.get("start", 0.0))
        seg_end = _float(seg.get("end", seg_start))
        
        if not words:
            continue
            
        # Traiter les mots en groupes cohérents
        current_group = []
        
        for word in words:
            current_group.append(word)
            word_text = _word_text(word)
            
            # Vérifier si on doit fermer le groupe actuel
            should_close = False
            
            # Vérifier la ponctuation de fin
            if punctuation_split and PUNCT_END_RE.search(word_text):
                should_close = True
                
            # Vérifier la durée maximale
            group_start = _word_start(current_group[0], seg_start)
            group_end = _word_end(current_group[-1], seg_end, seg_start)
            if (group_end - group_start) >= max_phrase_duration:
                should_close = True
                
            # Vérifier le nombre maximum de mots
            if len(current_group) >= max_words:
                should_close = True
                
            if should_close and len(current_group) >= min_words:
                # Créer le segment
                phrase_segments.append({
                    "start": group_start,
                    "end": group_end,
                    "text": " ".join(_word_text(w) for w in current_group).strip(),
                    "words": current_group.copy()
                })
                current_group = []
                
        # Traiter les mots restants
        if current_group:
            group_start = _word_start(current_group[0], seg_start)
            group_end = _word_end(current_group[-1], seg_end, seg_start)
            
            # Éviter les segments trop courts en les fusionnant avec le précédent
            if len(current_group) < min_words and phrase_segments:
                last_segment = phrase_segments[-1]
                last_segment["end"] = group_end
                last_segment["text"] = (last_segment["text"] + " " + 
                                      " ".join(_word_text(w) for w in current_group)).strip()
            else:
                phrase_segments.append({
                    "start": group_start,
                    "end": group_end,
                    "text": " ".join(_word_text(w) for w in current_group).strip(),
                    "words": current_group
                })
    
    # Post-processing: éliminer les chevauchements
    return _remove_overlapping_segments(phrase_segments)

def _remove_overlapping_segments(segments: List[Dict]) -> List[Dict]:
    """Élimine les chevauchements entre segments"""
    if not segments:
        return segments
        
    segments_sorted = sorted(segments, key=lambda x: x["start"])
    result = [segments_sorted[0]]
    
    for current in segments_sorted[1:]:
        previous = result[-1]
        
        # Si chevauchement, ajuster le début du segment courant
        if current["start"] < previous["end"]:
            current["start"] = previous["end"] + 0.001  # Petit décalage
            
        # S'assurer que start < end
        if current["start"] < current["end"]:
            result.append(current)
            
    return result


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

    phrase_segments = build_phrase_segments_from_aligned_smart(aligned_segments=aligned_segments,)

    return phrase_segments, lang