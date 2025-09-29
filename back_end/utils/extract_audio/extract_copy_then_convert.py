import tempfile
import shutil
import os
import time
import subprocess
import signal

def _safe_remove(path):
    try:
        if path and os.path.exists(path):
            os.remove(path)
    except Exception:
        pass


def extract_fifo_copy_then_convert_safe(input_video, output_wav, sample_rate=44100, channels=2, timeout=900):

    
    if os.name == "nt":
        raise RuntimeError("FIFO method not supported on Windows via os.mkfifo().")
    if shutil.which("ffmpeg") is None:
        raise RuntimeError("ffmpeg introuvable dans le PATH.")

    fifo_dir = tempfile.mkdtemp(prefix="fffifo_")
    fifo_path = os.path.join(fifo_dir, "audio_fifo")
    os.mkfifo(fifo_path)
    t0 = time.perf_counter()

    writer_cmd = [
        "ffmpeg", "-y", "-nostdin", "-hide_banner",
        "-i", input_video,
        "-map", "0:a:0",
        "-c:a", "copy",
        "-f", "matroska",
        fifo_path
    ]
    reader_cmd = [
        "ffmpeg", "-y", "-nostdin", "-hide_banner",
        "-i", fifo_path,
        "-ar", str(sample_rate),
        "-ac", str(channels),
        "-acodec", "pcm_s16le",
        output_wav
    ]
    
    # Prépare kwargs pour Popen : preexec_fn uniquement sur Unix
    popen_kwargs = {"stdout": subprocess.DEVNULL, "stderr": subprocess.PIPE, "text": True}
    if hasattr(os, "setsid"):
        popen_kwargs_unix = dict(popen_kwargs, preexec_fn=os.setsid)
    else:
        popen_kwargs_unix = popen_kwargs

    # Start reader first (plus sûr)
    reader = subprocess.Popen(reader_cmd, **popen_kwargs_unix)
    writer = subprocess.Popen(writer_cmd, **popen_kwargs_unix)

    try:
        # Attendre le reader (le plus long en général)
        r_stdout, r_stderr = reader.communicate(timeout=timeout)
        # Maintenant attendre writer, petit timeout car il doit normalement s'arrêter
        try:
            w_stdout, w_stderr = writer.communicate(timeout=10)
        except subprocess.TimeoutExpired:
            # writer peut encore être actif: on attend encore un peu
            writer.kill()
            w_stdout, w_stderr = writer.communicate()

        if reader.returncode != 0:
            raise subprocess.CalledProcessError(reader.returncode, reader_cmd, output=r_stdout, stderr=r_stderr)
        if writer.returncode not in (0, None):
            raise subprocess.CalledProcessError(writer.returncode, writer_cmd, output=w_stdout, stderr=w_stderr)

    except subprocess.TimeoutExpired:
        # Timeout : tuer les groupes de processus si possible
        try:
            os.killpg(os.getpgid(reader.pid), signal.SIGTERM)
        except Exception:
            try:
                reader.kill()
            except Exception:
                pass
        try:
            os.killpg(os.getpgid(writer.pid), signal.SIGTERM)
        except Exception:
            try:
                writer.kill()
            except Exception:
                pass
        # vider les pipes
        reader.communicate()
        writer.communicate()
        raise
    finally:
        _safe_remove(fifo_path)
        try:
            os.rmdir(fifo_dir)
        except Exception:
            pass

    return {"output": output_wav, "method": "fifo_copy_then_convert", "time_s": time.perf_counter() - t0}
