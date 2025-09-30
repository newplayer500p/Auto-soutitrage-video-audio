# extract_direct.py (corrigé)
import time
from ..helper.run_cmd_utils import run_check

def extract_direct(input_video, output_wav, sample_rate=44100, channels=2, timeout=900):
    """Décodage + ré-encodage en une passe.
    ffmpeg -i input -vn -ar {sample_rate} -ac {channels} -acodec pcm_s16le output.wav
    """
    cmd = [
        "ffmpeg", "-y", "-nostdin", "-hide_banner",
        "-i", input_video,
        "-vn",
        "-ar", str(sample_rate),
        "-ac", str(channels),
        "-acodec", "pcm_s16le",
        output_wav
    ]
    t0 = time.perf_counter()
    run_check(cmd, capture_output=False, timeout=timeout)
    return {"output": output_wav, "method": "direct_reencode", "time_s": time.perf_counter() - t0}
