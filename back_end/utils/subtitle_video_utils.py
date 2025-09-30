import subprocess
import shlex
import logging
from pathlib import Path
from typing import Optional, Union

from .subtitle_config.convert_color import hex_to_ass_color
from .subtitle_config.path_sure import escape_path_for_subtitles
from .subtitle_config.subtitle_position import normalize_position

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")

def burn_subtitles_into_video(
    input_video: Union[str, Path],
    input_srt: Union[str, Path],
    output_video: Optional[Union[str, Path]] = None,
    *,
    ffmpeg_path: str = "ffmpeg",
    overwrite: bool = True,
    timeout: Optional[int] = None,
) -> Path:
    """
    Brûle les sous-titres SRT sur la vidéo et renvoie le Path du fichier de sortie.
    - input_video: chemin de la vidéo source
    - input_srt: chemin du fichier .srt (utf-8 recommandé)
    - output_video: si None, un nom basé sur input_video est créé (suffixe _sub)
    - position: 'bottom-center' | 'center' | 'top-center' (ou variantes)
    - font_name: nom de police (doit être installée ou reconnue par libass)
    - font_size: taille de la police (pt)
    - font_color, outline_color: '#RRGGBB'
    - outline_width: épaisseur du contour
    - shadow: ombre (0 = none)
    - retourne Path vers le fichier écrit, ou lève une exception si ffmpeg échoue.
    """

    input_video = Path(input_video)
    input_srt = Path(input_srt)

    if not input_video.exists():
        raise FileNotFoundError(f"Vidéo introuvable: {input_video}")
    if not input_srt.exists():
        raise FileNotFoundError(f"SRT introuvable: {input_srt}")

    out = Path(output_video) if output_video else input_video.with_name(input_video.stem + "_sub" + input_video.suffix)
    # ensure parent
    out.parent.mkdir(parents=True, exist_ok=True)

    # build force_style string
        # escape path for ffmpeg filter
    srt_escaped = escape_path_for_subtitles(input_srt)

    # If input is an .ass file, use the ass filter (ASS contains Styles -> reliable positioning).
    # Otherwise fall back to subtitles=...:force_style=...
    if input_srt.suffix.lower() == ".ass":
        filter_str = f"ass='{srt_escaped}'"
    else:
        # build force_style string (for .srt fallback)
        force_style_items = [
            f"Fontsize={24}"
        ]
        force_style = ",".join(force_style_items)
        filter_str = f"subtitles='{srt_escaped}':force_style='{force_style}'"


    cmd = [
        ffmpeg_path,
        "-y" if overwrite else "-n",
        "-i", str(input_video),
        "-vf", filter_str,
        "-c:a", "copy",   # keep audio stream as-is
        str(out)
    ]

    # For safety, we will join with spaces but keep proper quoting for subprocess on shell=False by passing list.
    logger.info("Lancement ffmpeg pour incrustation sous-titres : %s", " ".join(shlex.quote(c) for c in cmd))
    try:
        proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=timeout)
        if proc.returncode != 0:
            logger.error("ffmpeg a échoué (returncode=%d). stderr:\n%s", proc.returncode, proc.stderr)
            raise subprocess.CalledProcessError(proc.returncode, cmd, output=proc.stdout, stderr=proc.stderr)
    except Exception:
        # re-raise for caller to handle
        raise

    logger.info("Fichier vidéo avec sous-titres écrit : %s", out)
    return out
