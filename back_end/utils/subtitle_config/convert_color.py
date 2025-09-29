def hex_to_ass_color(hex_color: str) -> str:
    """
    Convertit '#RRGGBB' ou 'RRGGBB' en couleur ASS &H00BBGGRR (alpha 00 = opaque).
    Exemple: '#FF0000' -> '&H000000FF' (rouge)
    """
    h = hex_color.lstrip("#")
    if len(h) != 6:
        raise ValueError("hex_color doit être au format RRGGBB ou #RRGGBB")
    rr = h[0:2]
    gg = h[2:4]
    bb = h[4:6]
    # ASS demande &HAA BB GG RR ; on met AA=00 (opaque) -> &H00BBGGRR
    return f"&H00{bb}{gg}{rr}"