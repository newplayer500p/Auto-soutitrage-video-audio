import datetime
import shutil
from utils.helper.segment_to_dict import segment_to_dict
from utils.helper.convert_audio_to_wav import convert_audio_to_wav
from utils.helper.prob_video import get_video_resolution
from utils.subtitle_config.choose_font_size import choose_font_size_for_video
from starlette.concurrency import run_in_threadpool

# importe tes interfaces (adapte si le module s'appelle différemment)
from interfaces.interface import (
    extract_audio_interface,
    get_voice_interface,
    build_phrases_interface,
    segments_to_ass_interface,
    burn_subtitles_into_video_interface
)

import logging
import traceback
from pathlib import Path
from typing import Optional
from utils.helper.notify_job import notify_job
from service.crud import add_job_file, set_job_status

def unique_output_dir(base_dir: Path, prefix: str = "job") -> Path:
    ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    out = base_dir / f"{prefix}_{ts}"
    out.mkdir(parents=True, exist_ok=True)
    return out



logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
logger = logging.getLogger("app")

async def run_full_pipeline(
    upload_path: Path,   # anciennement video_path ; peut être audio ou video selon is_audio
    out_dir: Path,
    *,
    # pipeline parameters (exposés par le endpoint)
    language: str,
    whisper_model: str,
    device: str,
    position: str,
    font_name: str,
    font_size: int,
    font_color: str,
    font_outline_colors: str,
    single_model: Optional[str] = "OK",
    is_audio: bool = False,
    fond: Optional[str] = None,
    job_id: Optional[str] = None,
):
    """
    Appelle les interfaces (bloquantes) dans un thread pool et renvoie un dict résultat.
    """
    
    if (language == "en"):
        whisper_model += ".en"
    
    def push(event, payload):
        if job_id:
            notify_job(job_id, event, payload)
    
    try:
        # Si l'entrée est audio, on convertit en .wav si nécessaire puis on saute l'étape d'extraction.
        if is_audio:
            push("task_started", {"task": "extraction"})
            logger.info("Upload detecté comme audio. Préparation audio...")
            # wav_out sera le WAV utilisé pour la suite
            wav_out = out_dir / (upload_path.stem + ".wav")
            if upload_path.suffix.lower() != ".wav":
                # conversion
                await run_in_threadpool(
                    convert_audio_to_wav, 
                    upload_path, 
                    wav_out, 
                    44100, 
                    2
                )
            else:
                # si c'est déjà un .wav, on le copie localement (sécurité)
                shutil.copy2(upload_path, wav_out)
            upload_path = wav_out
        else:
            # cas vidéo: extraire l'audio depuis la vidéo (comme avant)
            push("task_started", {"task": "extraction"})
            logger.info("Extraction audio -> %s", out_dir / (upload_path.stem + ".wav"))
            wav_out = out_dir / (upload_path.stem + ".wav")
            # extract_audio_interface peut être lent -> run_in_threadpool
            await run_in_threadpool(
                extract_audio_interface,
                str(upload_path),
                str(wav_out),
                44100,
                2
            )

            push(
                "task_finished", 
                {
                    "task": "extraction",
                    "info": "Extraction de l'audio reussit.",
                    "data": str(wav_out),
                    "download": "True",
                }
            )
            await run_in_threadpool(add_job_file, job_id, "wav", str(wav_out))

        
        # 2) optionally run spleeter to isolate vocals (get_voice)
        push("task_started", {"task": "isolation_voix"})
        voc = await run_in_threadpool(
            get_voice_interface, 
            str(wav_out), 
            str(out_dir), 
            single_model
        )
        # get_voice_interface returns Path or empty string per your code; normalize
        voc_path_str = str(voc) if voc else ""
        push(
            "task_finished", 
            {
                "task": "isolation_voix",
                "info": "Isolation du voix reussit.", 
                "data": voc_path_str,
                "download": "True"
            }
        )    
        if voc_path_str:
            await run_in_threadpool(add_job_file, job_id, "vocals", voc_path_str)    

        # 3) transcribe & build phrase segments (from vocals if available else from wav)
        push("task_started", {"task": "transcription"})
        audio_for_transcribe = Path(voc_path_str) if voc_path_str else wav_out
        logger.info("Transcription & alignement sur -> %s", audio_for_transcribe)
        phrase_segments, detected_lang = await run_in_threadpool(
            build_phrases_interface,
            str(audio_for_transcribe),
            language,
            whisper_model,
            device,
            True,  # reuse_models
        )
        
        safe_preview = [segment_to_dict(s) for s in phrase_segments[:3]]
        
        safe_payload = {
            "n_segments": len(phrase_segments),
            "language_detected": detected_lang,
            "preview": safe_preview,
        }

        push(
            "task_finished", 
            {
                "task": "transcription",
                "info": "Transcription reussie", 
                "data": safe_payload,
                "download": "False"
            }
        )
        
        # Si upload était audio, on fixe une résolution par défaut
        if is_audio:
            video_w, video_h = 1280, 720
        else:
            try:
                video_w, video_h = await run_in_threadpool(get_video_resolution, upload_path)
            except Exception:
                video_w, video_h = 1920, 1080

        adjusted_font_size = choose_font_size_for_video(video_h, font_size)


        push("task_started", {"task": "creation_ass"})
        # 4) write ASS only (we no longer produce .srt)
        out_dir_str = out_dir / "sous_titre"
        out_dir_str.mkdir(parents=True, exist_ok=True)

        ass_out = out_dir_str / (upload_path.stem + ".ass")
        logger.info("Écriture ASS -> %s", ass_out)
        ass_path = await run_in_threadpool(
            segments_to_ass_interface,
            phrase_segments,
            str(ass_out),
            video_w, video_h,           # playres
            font_name,
            adjusted_font_size,
            font_color,
            font_outline_colors,
            position
        )
        push(
            "task_finished", 
            {
                "task": "creation_ass",
                "info": "Creation du fichier sous titre .ass reussit",
                "data": str(ass_path),
                "download": "True"
            }
        )
        await run_in_threadpool(add_job_file, job_id, "ass", str(ass_path))
        

        # si is_audio True -> on doit générer une vidéo depuis le wav + ass (build_video_from_wav)
        subtitled_out = out_dir / (upload_path.stem + "_sub.mp4")
        logger.info("Incrustation SRT -> %s", subtitled_out)
        push("task_started", {"task": "assemblage"})
        
        await run_in_threadpool(
            burn_subtitles_into_video_interface,
            str(upload_path),
            str(ass_path),
            str(subtitled_out),
            is_audio,
            fond,
        )
        push(
            "task_finished", 
            {
                "task": "assemblage",
                "info": "Assemblagww du fichier sous titre et video reussit. ",
                "data": str(subtitled_out),
                "download": "True"
            }
        )
        await run_in_threadpool(add_job_file, job_id, "final", str(subtitled_out))
        
        push(
            "finished", 
            {
                "task": "Terminer",
                "info": "Video sous-titrer pret a telecharger",
                "data": str(subtitled_out),
                "download": "True"
            }
        )
        await run_in_threadpool(set_job_status, job_id, "finished", "Done")

    except Exception as e:
        push("error", {"error": str(e)})
        logger.error("Erreur pipeline: %s\n%s", e, traceback.format_exc())