import json
from pathlib import Path
import subprocess
from typing import Union

def detect_is_audio_trues(file_path: Union[str, Path], logger) -> bool:
    """
    Retourne True si le fichier n'a PAS de piste vidéo (i.e. audio-only).
    Utilise ffprobe pour inspecter les streams.
    """
    file_path = Path(file_path)
    if not file_path.exists():
        raise FileNotFoundError(f"Fichier introuvable: {file_path}")
    cmd = [
        "ffprobe", "-v", "error",
        "-select_streams", "v",  # chercher streams vidéo
        "-show_entries", "stream=codec_type",
        "-of", "json",
        str(file_path)
    ]
    try:
        out = subprocess.check_output(cmd, stderr=subprocess.DEVNULL)
        data = json.loads(out)
        streams = data.get("streams", [])
        # Si streams vidéo trouvés -> ce n'est pas audio-only
        return len(streams) == 0
    except subprocess.CalledProcessError:
        # ffprobe a échoué -> par sécurité considérer comme vidéo (False)
        logger.warning("ffprobe failed on %s, assuming not audio-only.", file_path)
        return False
    except Exception as e:
        logger.exception("Erreur detect_is_audio: %s", e)
        return False

