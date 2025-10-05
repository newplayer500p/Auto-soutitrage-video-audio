#!/usr/bin/env python3
from pathlib import Path
import subprocess
import shlex
import json
import shutil
import logging
import re
from PIL import Image

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def resize_image(input_path, width, height) -> Path:
    img = Image.open(input_path)
    img_resized = img.resize((width, height), Image.LANCZOS)
    img_resized.save(input_path)  # écrase l'original
    return input_path



def _check_tool(name="ffmpeg"):
    if shutil.which(name) is None:
        raise FileNotFoundError(f"{name} introuvable dans le PATH. Installe/ajoute {name}.")


def _ffprobe_duration(path: Path) -> float:
    """Retourne la durée en secondes du fichier média via ffprobe."""
    cmd = ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "json", str(path)]
    out = subprocess.check_output(cmd)
    data = json.loads(out)
    return float(data["format"]["duration"])


def _is_hex_color(s: str) -> bool:
    return bool(re.fullmatch(r"#?[0-9A-Fa-f]{6}", s))



def build_video_from_wav(
    wav_path,
    *,
    fond: str = None,          # chemin image ou couleur hex (#RRGGBB)
    out_path: str = None,      # chemin final
    width: int = 1280,
    height: int = 720,
    nvenc_preset: str = "p1",  # rapide, pour audio + image fixe
) -> Path:
    """
    Génère une vidéo à partir d'un audio + fond fixe (image ou couleur) + sous-titres optionnels.
    """
    _check_tool("ffmpeg")
    _check_tool("ffprobe")

    wav_path = Path(wav_path)
    if not wav_path.exists():
        raise FileNotFoundError(f"Fichier audio introuvable: {wav_path}")

    out = Path(out_path) if out_path else Path.cwd() / f"out_{wav_path.stem}.mp4"
    out = out.resolve()

    duration = _ffprobe_duration(wav_path)

    ff_args = ["ffmpeg", "-y", "-hide_banner", "-loglevel", "error"]

    # fond fixe
    if fond:
        if _is_hex_color(fond):
            c = fond if fond.startswith("#") else f"#{fond}"
            ff_args += ["-f", "lavfi", "-i", f"color=c={c}:s={width}x{height}:d={duration}"]
        else:
            fond_path = Path(fond)
            if not fond_path.exists():
                raise FileNotFoundError(f"Image de fond introuvable: {fond}")
            # redimensionner avant encodage
            fond_path = resize_image(fond_path, width, height)
            ff_args += ["-loop", "1", "-framerate", "1", "-i", str(fond_path)]
    else:
        ff_args += ["-f", "lavfi", "-i", f"color=c=#000000:s={width}x{height}:d={duration}"]


    # audio
    ff_args += ["-i", str(wav_path)]
    ff_args += ["-map", "0:v", "-map", "1:a"]

    # encodage vidéo + audio
    ff_args += [
        "-c:v", "h264_nvenc",
        "-preset", nvenc_preset,
        "-rc", "vbr_hq",
        "-cq", "28",           # qualité adaptée pour image fixe
        "-bf", "0",            # pas de B-frames pour accélérer
        "-c:a", "aac",
        "-b:a", "128k",         # bitrate audio bas, suffisant pour voix
        "-shortest",
        str(out),
    ]

    logger.info("Commande ffmpeg: %s", ff_args)

    subprocess.run(ff_args, check=True)

    logger.info("Vidéo créée: %s", out)
    return out
