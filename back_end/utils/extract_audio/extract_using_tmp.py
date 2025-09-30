import tempfile
from ..helper.run_cmd_utils import run_check
import time
import shutil
from .extract_direct import extract_direct
import os

def _safe_remove(path):
    try:
        if path and os.path.exists(path):
            os.remove(path)
    except Exception:
        pass


def extract_copy_then_convert_tmpfile(input_video, output_wav, sample_rate=16000, channels=1, timeout=900):
    """Fallback cross-platform : copie la piste compressée dans un fichier temporaire,
    puis ré-encode ce fichier en WAV. Simple et compatible Windows.
    """
    if shutil.which("ffmpeg") is None:
        raise RuntimeError("ffmpeg introuvable dans le PATH.")

    tmp = tempfile.NamedTemporaryFile(suffix=".mka", delete=False)
    tmp_path = tmp.name
    tmp.close()
    t0 = time.perf_counter()
    try:
        # 1) copy compressed audio into tmp file
        run_check([
            "ffmpeg", "-y", "-nostdin", "-hide_banner",
            "-i", input_video,
            "-map", "0:a:0",
            "-c:a", "copy",
            tmp_path
        ], capture_output=False, timeout=timeout)

        # 2) convert tmp to wav
        result = extract_direct(tmp_path, output_wav, sample_rate, channels, timeout=timeout)
        result["method"] = "copy_then_convert_tmpfile"
        result["time_s"] = time.perf_counter() - t0
        return result
    finally:
        _safe_remove(tmp_path)