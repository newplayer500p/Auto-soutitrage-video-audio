import shutil
import subprocess

def probe_first_audio(input_file, timeout=10):
    """Retourne dict simple de la première piste audio (codec, sr, channels, duration).

    Renvoie None si aucune piste audio trouvée.
    """
    if shutil.which("ffprobe") is None:
        raise RuntimeError("ffprobe introuvable.")
    cmd = ["ffprobe", "-v", "quiet", "-print_format", "json", "-show_streams", "-select_streams", "a", input_file]
    cp = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=timeout)
    import json
    data = json.loads(cp.stdout or "{}")
    streams = data.get("streams", [])
    if not streams:
        return None
    s = streams[0]
    return {
        "codec_name": s.get("codec_name"),
        "sample_rate": int(s["sample_rate"]) if s.get("sample_rate") else None,
        "channels": int(s["channels"]) if s.get("channels") else None,
        "duration": float(s.get("duration")) if s.get("duration") else None,
        "index": s.get("index"),
        "tags": s.get("tags", {})
    }