def segment_to_dict(s):
    """Normalise un segment qui peut être un objet (avec .start/.end/.text)
       ou un dict {'start':..,'end':..,'text':..}."""
    if s is None:
        return {"start": None, "end": None, "text": None}
    # cas dict-like
    if isinstance(s, dict):
        return {
            "start": s.get("start"),
            "end": s.get("end"),
            "text": s.get("text") or s.get("text_raw") or s.get("sentence") or None
        }
    # cas objet avec attributs
    start = getattr(s, "start", None)
    end = getattr(s, "end", None)
    # plusieurs noms possibles pour le texte selon implémentation
    text = getattr(s, "text", None) or getattr(s, "content", None) or getattr(s, "sentence", None)
    return {"start": start, "end": end, "text": text}