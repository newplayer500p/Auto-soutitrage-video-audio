#!/usr/bin/env python3
from pathlib import Path
import subprocess
import shlex
import tempfile
import json
import shutil
import logging
import re

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

def _check_tool(name="ffmpeg"):
    if shutil.which(name) is None:
        raise FileNotFoundError(f"{name} introuvable dans le PATH. Installe/ajoute ffmpeg.")

def _ffprobe_duration(path: Path) -> float:
    """Retourne la durée en secondes du fichier média via ffprobe."""
    cmd = [
        "ffprobe", "-v", "error", "-show_entries",
        "format=duration", "-of", "json", str(path)
    ]
    out = subprocess.check_output(cmd)
    data = json.loads(out)
    return float(data["format"]["duration"])

def _is_hex_color(s: str) -> bool:
    return bool(re.fullmatch(r"#?[0-9A-Fa-f]{6}", s))

def build_video_from_wav(
    wav_path,
    ass_path,
    *,
    fond: str = None,              # chemin vers image OU code hex (#RRGGBB)
    show_wav_signal: bool = False, # affiche forme d'onde si True
    out_path: str = None,          # chemin final (si None utilisera tmp)
    width: int = 1280,
    height: int = 720,
    fps: int = 25,
    nvenc_preset: str = "p5"       # change si tu veux (p1..p7 selon ffmpeg build)
) -> Path:
    """
    Génère une vidéo à partir d'un .wav + .ass (sous-titres).
    - fond: chemin image OU couleur hex (#RRGGBB). Si None -> noir.
    - show_wav_signal: si True, ajoute la forme d'onde animée au-dessus du fond.
    - Retourne Path vers le fichier vidéo final.
    """
    _check_tool("ffmpeg")
    _check_tool("ffprobe")

    wav_path = Path(wav_path)
    ass_path = Path(ass_path)
    if not wav_path.exists():
        raise FileNotFoundError(f"Fichier audio introuvable: {wav_path}")
    if not ass_path.exists():
        raise FileNotFoundError(f"Fichier de sous-titres introuvable: {ass_path}")

    duration = _ffprobe_duration(wav_path)
    logger.info("Durée audio détectée: %.2f s", duration)

    final_out = Path(out_path) if out_path else Path(tempfile.gettempdir()) / f"out_subtitled_{wav_path.stem}.mp4"
    final_out = final_out.resolve()

    # tmp base video (sans sous-titres)
    tmp_base = Path(tempfile.gettempdir()) / f"tmp_base_{wav_path.stem}.mp4"

    # Decide inputs order and ffmpeg args
    ff_args = ["ffmpeg", "-y", "-hide_banner", "-loglevel", "error"]

    # Determine background input: image or color
    if fond:
        # si fond ressemble à un code hex -> color lavfi
        if _is_hex_color(fond):
            c = fond if fond.startswith("#") else f"#{fond}"
            color_filter = f"color=c={c}:s={width}x{height}:d={duration}"
            ff_args += ["-f", "lavfi", "-i", color_filter]
            # audio input next
            ff_args += ["-i", str(wav_path)]
            bg_input_index = 0
            audio_input_index = 1
        else:
            # treat as image file
            fond_path = Path(fond)
            if not fond_path.exists():
                raise FileNotFoundError(f"Image de fond introuvable: {fond}")
            # loop image
            ff_args += ["-loop", "1", "-i", str(fond_path)]
            ff_args += ["-i", str(wav_path)]
            bg_input_index = 0
            audio_input_index = 1
    else:
        color_filter = f"color=c=#000000:s={width}x{height}:d={duration}"
        ff_args += ["-f", "lavfi", "-i", color_filter]
        ff_args += ["-i", str(wav_path)]
        bg_input_index = 0
        audio_input_index = 1

    # Build filter_complex for waveform overlay if demandé
    filter_complex_parts = []
    map_video_label = None

    if show_wav_signal:
        # create waveform from audio input (audio is at input index audio_input_index)
        # We'll create a labeled out video [wv] then overlay on background [bg]
        # Note: showwaves uses the audio stream -> refer to input index with [<idx>:a]
        wv_label = "wv"
        out_label = "outv"
        # waveform
        filter_complex_parts.append(
            f"[{audio_input_index}:a]showwaves=s={width}x{height}:mode=line:rate={fps},format=yuv420p[{wv_label}]"
        )
        # overlay waveform onto the background video stream (bg is input 0:v)
        filter_complex_parts.append(
            f"[{bg_input_index}:v][{wv_label}]overlay=0:0:shortest=1[{out_label}]"
        )
        map_video_label = out_label
    else:
        # no waveform: just take the background video (input bg_input_index:v)
        # but ensure format is okay (yuv420p) and we have label
        bg_label = "bg"
        out_label = "outv"
        filter_complex_parts.append(f"[{bg_input_index}:v]format=yuv420p[{out_label}]")
        map_video_label = out_label

    filter_complex = ";".join(filter_complex_parts)

    # assemble ffmpeg command to create base video (audio + background/wave)
    ff_args += ["-filter_complex", filter_complex, "-map", f"[{map_video_label}]", "-map", f"{audio_input_index}:a"]
    # encoder NVENC H.264
    ff_args += ["-c:v", "h264_nvenc", "-preset", nvenc_preset, "-rc", "vbr_hq", "-cq", "19", "-b:v", "6M"]
    ff_args += ["-c:a", "aac", "-b:a", "192k", "-shortest", str(tmp_base)]

    # Run step 1
    logger.info("Lancement ffmpeg (étape 1 base vidéo) : %s", " ".join(shlex.quote(a) for a in ff_args))
    try:
        subprocess.run(ff_args, check=True)
    except subprocess.CalledProcessError as e:
        logger.exception("Erreur ffmpeg étape 1")
        raise

    # Step 2: apply ASS subtitles (libass) and re-encode with nvenc, keep audio copy
    final_args = [
        "ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
        "-i", str(tmp_base),
        "-vf", f"ass={shlex.quote(str(ass_path))}",
        "-c:v", "h264_nvenc", "-preset", nvenc_preset, "-rc", "vbr_hq", "-cq", "19", "-b:v", "6M",
        "-c:a", "copy",
        str(final_out)
    ]

    logger.info("Lancement ffmpeg (étape 2 subtitles) : %s", " ".join(shlex.quote(a) for a in final_args))
    try:
        subprocess.run(final_args, check=True)
    except subprocess.CalledProcessError:
        logger.exception("Erreur ffmpeg étape 2")
        # cleanup tmp_base if exists
        raise

    # Optionally remove tmp_base (on succès)
    try:
        tmp_base.unlink(missing_ok=True)
    except Exception:
        pass

    logger.info("Fini. Vidéo créée: %s", final_out)
    return final_out
