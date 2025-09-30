# tools/interfaces.py
from pathlib import Path
from typing import Optional, List, Dict, Any, Tuple, Union
import logging

from utils.align_utils import build_phrases
from utils.extract_audio_utils import extract_audio
from utils.subtitle_video_utils import burn_subtitles_into_video
from utils.extract_voice_utils import run_demucs
from utils.subtitle_config.segment_to_ass import segments_to_ass



logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")


def _ensure_parent(path: Union[str, Path]) -> Path:
    p = Path(path)
    if not p.parent.exists():
        p.parent.mkdir(parents=True, exist_ok=True)
    return p


# 1) Interface pour extract_audio
def extract_audio_interface(
    input_video: Union[str, Path],
    output_wav: Union[str, Path],
    sample_rate: int = 44100,
    channels: int = 2,
    duration_threshold_seconds: int = 600,
    timeout: int = 7200,
) -> Dict[str, Any]:
    """
    Wrapper safe pour extract_audio.
    - Vérifie que input_video existe.
    - Crée le dossier parent de output_wav si nécessaire.
    - Retourne le dict produit par extract_audio (output, method, time_s).
    """
    input_video = Path(input_video)
    if not input_video.exists():
        raise FileNotFoundError(f"input_video introuvable: {input_video}")

    output_wav = _ensure_parent(output_wav)

    result = extract_audio(
        str(input_video),
        str(output_wav),
        sample_rate=sample_rate,
        channels=channels,
        duration_threshold_seconds=duration_threshold_seconds,
        timeout=timeout,
    )
    logger.info("extract_audio -> %s", result)
    return result


# 2) Interface pour get_voice (retour Path | None)
def get_voice_interface(wath_path: Union[str, Path], out_voice_path: Union[str, Path], single_model: Optional[str]) -> Optional[Path]:
    """
    Wrapper pour get_voice.
    - Vérifie l'existence du fichier d'entrée.
    - Crée le dossier de sortie si nécessaire.
    - Retourne le Path du fichiers nettoyé ou None.
    """
    logger.info("Separation voix: -> %s", out_voice_path)
    
    wath_path = Path(wath_path)
    out_voice_path = Path(out_voice_path)
    if not wath_path.exists():
        raise FileNotFoundError(f"Fichier d'entrée introuvable: {wath_path}")
    out_voice_path.parent.mkdir(parents=True, exist_ok=True)

    result = run_demucs(str(wath_path), str(out_voice_path), single_sig=single_model)
    # result est soit Path soit None selon ton implémentation
    logger.info("get_voice -> %s", result)
    return Path(result) if result is not None else ""


# 3) Interface pour transcribe_align_and_build_phrases (phrase_segments, lang)
def build_phrases_interface(
    audio_clear_path: Union[str, Path],
    language: str = "fr",
    whisper_model: str = "small",
    device: str = "cuda",
    reuse_models: bool = True
) -> Tuple[List[Dict[str, Any]], str]:
    """
    Wrapper pour transcribe_align_and_build_phrases.
    - Vérifie que le fichier audio existe.
    - Retourne (phrase_segments, detected_language) où phrase_segments = list de {start,end,text}.
    """
    audio_clear_path = Path(audio_clear_path)
    if not audio_clear_path.exists():
        raise FileNotFoundError(f"Audio introuvable: {audio_clear_path}")

    phrase_segments, lang = build_phrases(
        audio_clear_path=audio_clear_path,
        language=language,
        whisper_model=whisper_model,
        device=device,
        reuse_models=reuse_models,
    )
    logger.info("transcribe_align_and_build_phrases -> %d phrase segments, lang=%s", len(phrase_segments), lang)
    return phrase_segments, lang


# 4) Interface pour segments_to_ass(écrit fichier .srt puis retourne Path)
def segments_to_ass_interface(
    segments: List[Dict[str, Any]],
    output_ass_path: Union[str, Path],
    playresx: int = 1920,
    playresy: int = 1080,
    font_name: str = "Arial",
    font_size: int = 36,
    font_color: str = "#FFFFFF",
    outline_color: str = "#000000",
    position: str = "top-center",
) -> Path:
    out = _ensure_parent(output_ass_path)
    # convert hex colors to ASS color string if you have hex_to_ass_color
    from utils.subtitle_video_utils import hex_to_ass_color
    primary = hex_to_ass_color(font_color)
    outline = hex_to_ass_color(outline_color)
    segments_to_ass(
        segments=segments,
        output_ass_path=str(out),
        playresx=playresx,
        playresy=playresy,
        fontname=font_name,
        fontsize=font_size,
        font_color_ass=primary,
        outline_color_ass=outline,
        outline_width=2,
        position=position,
        margin_v=30,
    )
    return out

# 5) Interface pour burn_subtitles_into_video (retourne Path)
def burn_subtitles_into_video_interface(
    input_video: Union[str, Path],
    input_srt: Union[str, Path],
    output_video: Optional[Union[str, Path]] = None
) -> Path:
    """
    Wrapper safer pour burn_subtitles_into_video.
    - Vérifie que input_video et input_srt existent.
    - Crée parent de output si nécessaire.
    - Retourne Path du fichier vidéo produit.
    """
    input_video = Path(input_video)
    input_srt = Path(input_srt)
    if not input_video.exists():
        raise FileNotFoundError(f"Vidéo introuvable: {input_video}")
    if not input_srt.exists():
        raise FileNotFoundError(f"SRT introuvable: {input_srt}")

    out = burn_subtitles_into_video(
        input_video=input_video,
        input_srt=input_srt,
        output_video=output_video
    )
    logger.info("Vidéo sous-titrée écrite: %s", out)
    return out
