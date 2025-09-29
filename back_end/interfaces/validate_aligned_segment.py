from typing import Dict, List
from utils.align_utils import _float


def validate_aligned_segments(segments: List[Dict]) -> List[Dict]:
    """Valide et corrige les segments alignés"""
    validated = []
    
    for seg in segments:
        start = _float(seg.get("start", 0))
        end = _float(seg.get("end", start))
        
        # Corriger les timestamps invalides
        if end <= start:
            end = start + 0.1  # Durée minimale
            
        if end - start > 30:  # Durée maximale raisonnable
            end = start + 8.0  # Limiter à 8 secondes
            
        seg_copy = seg.copy()
        seg_copy["start"] = start
        seg_copy["end"] = end
        validated.append(seg_copy)
        
    return validated