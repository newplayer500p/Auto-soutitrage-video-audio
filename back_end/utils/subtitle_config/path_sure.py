from pathlib import Path


def escape_path_for_subtitles(path: Path) -> str:
    """
    Retourne une représentation sûre du chemin pour le filtre subtitles.
    - Utilise / comme séparateur
    - Double les apostrophes pour l'encapsulation entre quotes simples
    """
    p = Path(path).as_posix()
    # double apostrophe ' → ''
    p_escaped = p.replace("'", "''")
    return p_escaped
