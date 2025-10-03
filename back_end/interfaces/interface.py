# tools/interfaces.py
from pathlib import Path
from typing import Optional, List, Dict, Any, Tuple, Union
import logging

from utils.subtitle_audio_utils import build_video_from_wav
from utils.align_utils import build_phrases
from utils.extract_audio_utils import extract_audio
from utils.subtitle_video_utils import burn_subtitles_into_video
from utils.extract_voice_utils import run_demucs
from utils.subtitle_config.segment_to_ass import segments_to_ass
from utils.subtitle_config.convert_color import hex_to_ass_color



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
    language: str,
    whisper_model: str,
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
    input: Union[str, Path],
    input_srt: Union[str, Path],
    output_video: Optional[Union[str, Path]] = None,
    *,
    is_audio: bool = False,
    fond: Optional[str] = None,
    show_wav_signal: bool = False,
) -> Path:
    """
    Wrapper safe pour deux cas :
      - si is_audio == True : l'input est un fichier audio -> on appelle build_video_from_wav
      - sinon : l'input est une vidéo -> on appelle burn_subtitles_into_video

    Paramètres :
      - input : chemin vers la vidéo ou l'audio (str | Path)
      - input_srt : chemin vers le .srt/.ass (str | Path)
      - output_video : chemin de sortie optionnel (str | Path). Si None, un fichier temporaire est créé.
      - is_audio : bool, si True considère `input` comme audio.
      - fond : optionnel, chemin vers image de fond OU couleur hex (transmis à build_video_from_wav si is_audio True)
      - show_wav_signal : bool, transmis à build_video_from_wav si is_audio True
    Retourne :
      - Path vers le fichier vidéo généré.
    """
    input = Path(input)
    input_srt = Path(input_srt)

    if not input.exists():
        raise FileNotFoundError(f"Fichier d'entrée introuvable: {input}")
    if not input_srt.exists():
        raise FileNotFoundError(f"Fichier de sous-titres introuvable: {input_srt}")

    out_path = Path(output_video)
    
    # crée le répertoire parent si nécessaire
    out_path.parent.mkdir(parents=True, exist_ok=True)

    # Choix de la voie selon is_audio
    if is_audio:
        # input est un fichier audio -> on génère une vidéo depuis l'audio
        logger.info("Input considéré comme audio. Génération vidéo depuis l'audio avec les sous-titres.")
        # build_video_from_wav attend (wav_path, ass_path, fond=..., show_wav_signal=..., out_path=...)
        # ATTENTION: build_video_from_wav doit être importée dans le scope où tu colles cette interface.
        try:
            out = build_video_from_wav(
                wav_path=input,
                ass_path=input_srt,
                fond=fond,
                show_wav_signal=show_wav_signal,
                out_path=str(out_path)
            )
        except Exception as e:
            logger.exception("Erreur lors de build_video_from_wav: %s", e)
            raise
    else:
        # input est une vidéo -> on brûle les sous-titres sur la vidéo existante
        logger.info("Input considéré comme vidéo. Incrustation des sous-titres sur la vidéo.")
        if fond is not None or show_wav_signal:
            logger.warning("Les options 'fond' et 'show_wav_signal' sont ignorées pour le mode vidéo (is_audio=False).")
        # burn_subtitles_into_video doit être importée dans le scope où tu colles cette interface.
        try:
            out = burn_subtitles_into_video(
                input_video=input,
                input_srt=input_srt,
                output_video=str(out_path)
            )
        except Exception as e:
            logger.exception("Erreur lors de burn_subtitles_into_video: %s", e)
            raise

    out_path = Path(out)
    if not out_path.exists():
        # si la fonction appelée n'a pas levé d'erreur mais n'a pas produit le fichier
        raise FileNotFoundError(f"Le fichier de sortie attendu n'a pas été trouvé: {out_path}")

    logger.info("Vidéo produite: %s", out_path)
    return out_path