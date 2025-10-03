import subprocess
import shlex
import logging
from pathlib import Path
from typing import Optional, Union, Sequence

from .subtitle_config.path_sure import escape_path_for_subtitles

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")


def _ffmpeg_has_encoder(ffmpeg_path: str, encoder_name: str) -> bool:
    try:
        out = subprocess.run([ffmpeg_path, "-hide_banner", "-encoders"],
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=False)
        return encoder_name in out.stdout
    except Exception:
        return False


def _ffmpeg_has_hwaccel(ffmpeg_path: str, hwaccel_name: str) -> bool:
    try:
        out = subprocess.run([ffmpeg_path, "-hide_banner", "-hwaccels"],
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=False)
        return hwaccel_name in out.stdout
    except Exception:
        return False


def burn_subtitles_into_video(
    input_video: Union[str, Path],
    input_srt: Union[str, Path],
    output_video: Optional[Union[str, Path]] = None,
    *,
    ffmpeg_path: str = "ffmpeg",
    overwrite: bool = True,
    timeout: Optional[int] = None,
    use_gpu: bool = True,
    hwaccel_name: str = "cuda",  # 'cuda' for NVIDIA; could be 'vaapi' for Intel (different flags)
    preferred_gpu_encoders: Sequence[str] = ("h264_nvenc", "hevc_nvenc"),
    sw_encoder: str = "libx264",
    video_bitrate: str = "5M",
    nvenc_preset: str = "fast",
) -> Path:
    """
    Brûle les sous-titres SRT sur la vidéo en essayant d'utiliser le GPU si possible.
    - use_gpu: tenter NVENC / hwaccel si disponible
    - preferred_gpu_encoders: ordre de préférence pour NV encoders
    - sw_encoder: fallback logiciel (libx264)
    """

    input_video = Path(input_video)
    input_srt = Path(input_srt)

    if not input_video.exists():
        raise FileNotFoundError(f"Vidéo introuvable: {input_video}")
    if not input_srt.exists():
        raise FileNotFoundError(f"SRT introuvable: {input_srt}")

    out = Path(output_video) if output_video else input_video.with_name(input_video.stem + "_sub" + input_video.suffix)
    out.parent.mkdir(parents=True, exist_ok=True)

    srt_escaped = escape_path_for_subtitles(input_srt)

    if input_srt.suffix.lower() == ".ass":
        filter_str = f"ass='{srt_escaped}'"
    else:
        force_style_items = [f"Fontsize={24}"]
        force_style = ",".join(force_style_items)
        filter_str = f"subtitles='{srt_escaped}':force_style='{force_style}'"

    # decide whether hwaccel and nvenc are available
    hwaccel_available = False
    chosen_gpu_encoder = None
    if use_gpu:
        hwaccel_available = _ffmpeg_has_hwaccel(ffmpeg_path, hwaccel_name)
        logger.info("hwaccel '%s' disponible: %s", hwaccel_name, hwaccel_available)

        for enc in preferred_gpu_encoders:
            if _ffmpeg_has_encoder(ffmpeg_path, enc):
                chosen_gpu_encoder = enc
                break
        logger.info("Encodeur GPU choisi: %s", chosen_gpu_encoder)

    # build cmd
    cmd = [ffmpeg_path, "-y" if overwrite else "-n"]

    # hwaccel flag goes BEFORE -i
    if use_gpu and hwaccel_available:
        # For CUDA this is usually: -hwaccel cuda
        cmd += ["-hwaccel", hwaccel_name]

    cmd += ["-i", str(input_video)]

    # filter (subtitles)
    cmd += ["-vf", filter_str]

    # encoder selection
    if chosen_gpu_encoder:
        # Use NVENC
        cmd += ["-c:v", chosen_gpu_encoder, "-preset", nvenc_preset, "-b:v", video_bitrate]
        logger.info("Utilisation NVENC: %s (preset=%s, bitrate=%s)", chosen_gpu_encoder, nvenc_preset, video_bitrate)
    else:
        # fallback logiciel
        cmd += ["-c:v", sw_encoder, "-preset", "fast", "-crf", "23"]
        logger.info("Fallback logiciel: %s", sw_encoder)

    # Keep audio as-is
    cmd += ["-c:a", "copy", str(out)]

    logger.info("Lancement ffmpeg pour incrustation sous-titres : %s", " ".join(shlex.quote(c) for c in cmd))
    try:
        proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=timeout)
        if proc.returncode != 0:
            logger.error("ffmpeg a échoué (returncode=%d). stderr:\n%s", proc.returncode, proc.stderr)
            raise subprocess.CalledProcessError(proc.returncode, cmd, output=proc.stdout, stderr=proc.stderr)
    except Exception:
        raise

    logger.info("Fichier vidéo avec sous-titres écrit : %s", out)
    return out
