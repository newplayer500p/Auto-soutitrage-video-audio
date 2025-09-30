# utils/fontsize_utils.py  (crée ce fichier ou colle la fonction dans app.py)
def choose_font_size_for_video(video_h: int, user_font_size: int) -> int:
    """
    Retourne une fontsize ASS recommandée selon la hauteur de la vidéo (video_h).
    - user_font_size : la taille souhaitée par l'utilisateur (valeur minimale à respecter).
    L'idée : fournir tailles 'designer-friendly' pour 480/720/1080/1440/2160.
    """
    # recommandations empiriques — tu peux les ajuster
    if video_h <= 480:
        suggested = 18
    elif video_h <= 720:
        suggested = 44   # 720p → ~44-56 classique. on prend 44 comme plancher.
    elif video_h <= 1080:
        suggested = 56
    elif video_h <= 1440:
        suggested = 78
    elif video_h <= 2160:
        suggested = 110
    else:
        # pour plus grand que 4K, on scale linéairement
        suggested = int(56 * (video_h / 1080.0))

    # on prend au moins la taille que l'utilisateur demande,
    # mais on laisse aussi un petit marge où on peut monter jusqu'à suggested.
    # si user demande plus grand, on garde sa demande.
    return max(int(user_font_size), suggested)
