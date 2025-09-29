_ALIGNMENT_MAP = {
    "bottom-left": 1,
    "bottom-center": 2,
    "bottom-right": 3,
    "center-left": 4,
    "center": 5,
    "center-right": 6,
    "top-left": 7,
    "top-center": 8,
    "top-right": 9,
}

def normalize_position(pos: str) -> int:
    """Retourne code ASS Alignment à partir d'une position courte."""
    p = (pos or "").lower().strip()
    if p in ("bottom", "bottom-center", "bcenter", "bc"):
        return _ALIGNMENT_MAP["bottom-center"]
    if p in ("center", "middle", "center-center"):
        return _ALIGNMENT_MAP["center"]
    if p in ("top", "top-center", "tcenter", "tc"):
        return _ALIGNMENT_MAP["top-center"]
    # fallback: bottom-center
    return _ALIGNMENT_MAP["bottom-center"]