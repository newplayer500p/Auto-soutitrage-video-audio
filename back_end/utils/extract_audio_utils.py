# extrait principal : extract_audio
import time
import os
from pathlib import Path
from typing import Union
from .prob_audio_utils import probe_first_audio
from .run_cmd_utils import run_check
from .extract_audio.extract_direct import extract_direct
from .extract_audio.extract_using_tmp import extract_copy_then_convert_tmpfile
from .extract_audio.extract_copy_then_convert import extract_fifo_copy_then_convert_safe

def extract_audio(input_video, output_wav, sample_rate: Union[int,None]=44100, channels: int = 2,
                  duration_threshold_seconds: int = 600, timeout: int = 900):
    """
    Wrapper pour extraire l'audio :
    - sample_rate=None => préserver sample rate d'origine (ne pas forcer la ré-échantillonnage)
    - Par défaut on sort en 44100 stereo (bon pour Demucs).
    """
    info = probe_first_audio(input_video)
    if not info:
        raise RuntimeError("Aucune piste audio détectée.")
    codec = (info.get("codec_name") or "").lower()
    duration = float(info.get("duration") or 0.0)
    orig_sr = int(info.get("sample_rate")) if info.get("sample_rate") else None
    orig_ch = int(info.get("channels")) if info.get("channels") else None

    # si on veut préserver l'original, passer sample_rate=None et channels=None
    target_sr = orig_sr if sample_rate is None else sample_rate
    target_ch = orig_ch if channels is None else channels

    compressed_set = {"aac", "mp3", "opus", "vorbis", "ac3", "eac3"}

    # PCM case: only copy if sample_rate & channels match exactly
    if codec.startswith("pcm"):
        sr = info.get("sample_rate")
        ch = info.get("channels")
        if sr == target_sr and ch == target_ch:
            cmd = [
                "ffmpeg", "-y", "-nostdin", "-hide_banner",
                "-i", input_video,
                "-map", "0:a:0",
                "-c:a", "copy",
                output_wav
            ]
            t0 = time.perf_counter()
            run_check(cmd, capture_output=False, timeout=timeout)
            return {"output": output_wav, "method": "copy_pcm", "time_s": time.perf_counter() - t0}
        else:
            return extract_direct(input_video, output_wav, sample_rate=target_sr, channels=target_ch, timeout=timeout)

    # compressed
    if codec in compressed_set:
        if duration < duration_threshold_seconds:
            return extract_direct(input_video, output_wav, sample_rate=target_sr, channels=target_ch, timeout=timeout)
        else:
            # Long compressed file: try FIFO on Unix, tmpfile on Windows
            try:
                if os.name == "nt":
                    return extract_copy_then_convert_tmpfile(input_video, output_wav, sample_rate=target_sr, channels=target_ch, timeout=timeout)
                else:
                    return extract_fifo_copy_then_convert_safe(input_video, output_wav, sample_rate=target_sr, channels=target_ch, timeout=timeout)
            except Exception as e:
                # fallback to direct re-encode
                print("Streaming method failed, fallback to direct_reencode:", e)
                return extract_direct(input_video, output_wav, sample_rate=target_sr, channels=target_ch, timeout=timeout)

    # default fallback
    return extract_direct(input_video, output_wav, sample_rate=target_sr, channels=target_ch, timeout=timeout)
