# utils/video_info.py
import subprocess
from pathlib import Path
from typing import Tuple

def get_video_resolution(path: Path) -> Tuple[int, int]:
    """
    Retourne (width, height) en int pour la première piste vidéo.
    Nécessite ffprobe disponible dans PATH.
    """
    p = str(path)
    cmd = [
        "ffprobe", "-v", "error",
        "-select_streams", "v:0",
        "-show_entries", "stream=width,height",
        "-of", "csv=p=0:s=x",
        p
    ]
    out = subprocess.check_output(cmd, stderr=subprocess.DEVNULL).decode().strip()
    w,h = out.split("x")
    return int(w), int(h)
