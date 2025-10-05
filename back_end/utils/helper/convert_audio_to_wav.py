from pathlib import Path
import shlex
import subprocess
from typing import Union


def convert_audio_to_wav(input_path: Union[str, Path], output_wav: Union[str, Path], sr: int = 44100, channels: int = 2):
    """
    Convertit input audio (mp3/m4a/ogg/...) en WAV PCM linéaire.
    Bloquant; prévu pour être appelé via run_in_threadpool.
    """
    input_path = str(input_path)
    output_wav = str(output_wav)
    cmd = [
        "ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
        "-i", input_path,
        "-ar", str(sr),
        "-ac", str(channels),
        "-vn",  # s'assurer d'ignorer toute piste vidéo
        output_wav
    ]
    subprocess.run(cmd, check=True)