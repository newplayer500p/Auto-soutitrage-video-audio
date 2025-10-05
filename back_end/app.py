# app.py
import asyncio
import json
import uuid
from fastapi import FastAPI, HTTPException, UploadFile, File, Form, Request
from fastapi.responses import JSONResponse, StreamingResponse
from fastapi.staticfiles import StaticFiles
from starlette.concurrency import run_in_threadpool
from fastapi.middleware.cors import CORSMiddleware


from pathlib import Path
from datetime import datetime
import shutil
import logging
import traceback
from typing import Optional

# importe tes interfaces (adapte si le module s'appelle différemment)
from interfaces.interface import (
    extract_audio_interface,
    get_voice_interface,
    build_phrases_interface,
    segments_to_ass_interface,
    burn_subtitles_into_video_interface
)
from utils.subtitle_config.choose_font_size import choose_font_size_for_video
from utils.helper.notify_job import create_job_queue, init_job_state, notify_job, get_job_state, get_job_queue, cleanup_job
from utils.helper.segment_to_dict import segment_to_dict
from utils.helper.convert_audio_to_wav import convert_audio_to_wav
from utils.helper.prob_video import get_video_resolution
from utils.helper.detect_is_audio import detect_is_audio_trues

logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
logger = logging.getLogger("app")

app = FastAPI(title="Pipeline Audio → Sous-titres")

app.add_middleware(
  CORSMiddleware,
  allow_origins=["*"],  # en dev OK, en prod restreindre aux origines nécessaires
  allow_credentials=True,
  allow_methods=["*"],
  allow_headers=["*"],
)

# dossier uploads accessible via /uploads
UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=str(UPLOAD_DIR)), name="uploads")


def _unique_output_dir(base_dir: Path, prefix: str = "job") -> Path:
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    out = base_dir / f"{prefix}_{ts}"
    out.mkdir(parents=True, exist_ok=True)
    return out


async def _run_full_pipeline(
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
            push(
                "task_finished", 
                {
                    "task": "extraction",
                    "info": "Extraction de l'audio reussit.",
                    "data": str(wav_out),
                    "download": "True",
                }
            )
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
                },
            )

        
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
        
        push(
            "finished", 
            {
                "task": "Terminer",
                "info": "Video sous-titrer pret a telecharger",
                "data": str(subtitled_out),
                "download": "True"
            }
        )

    except Exception as e:
        push("error", {"error": str(e)})
        logger.error("Erreur pipeline: %s\n%s", e, traceback.format_exc())
    
@app.get("/stream/{job_id}")
async def stream_job(job_id: str, request: Request):
    
    q = get_job_queue(job_id)
    if q is None:
        # retourne 404 simple si job inconnu
        return JSONResponse({"error": "job not found"}, status_code=404)
    
    async def event_generator():
        try:
            while True:
                # si le client ferme la connexion, on arrête
                if await request.is_disconnected():
                    break
                try:
                    msg = await asyncio.wait_for(q.get(), timeout=15.0)
                except asyncio.TimeoutError:
                    # envoie un keep-alive commenté (optionnel) pour éviter timeouts intermediaries
                    yield ":\n\n"
                    continue

                # format SSE: data: <json>\n\n
                yield f"data: {msg}\n\n"

                # si event "finished" ou "error", on peut fermer la queue
                try:
                    obj = json.loads(msg)
                    if obj.get("event") in ("finished", "error"):
                        break
                except Exception:
                    pass

        finally:
            # cleanup: supprimer la queue si elle existe
            cleanup_job(job_id)

    return StreamingResponse(event_generator(), media_type="text/event-stream")


@app.post("/video/process")
async def upload_and_process_video(
    language: str = Form("fr"),
    position: str = Form("bottom-center"),
    font_name: str = Form("Arial"),
    font_size: int = Form(24),
    font_color: str = Form("#FFFFFF"),
    font_outline_color: str = Form("#000000"),
    fond: Optional[str] = Form(None),                 # nouveau paramètre (image OU couleur hex)
    fond_file: Optional[UploadFile] = File(None),      # <-- nouveau champ pour image
    file: UploadFile = File(...),
):
    """
    Endpoint upload + process.
    - Sauvegarde la vidéo (uploads/<timestamp>_<name>/original.ext)
    - Lance la pipeline et retourne JSON avec chemins relatifs si succès.
    NOTE: This endpoint will run the pipeline synchronously (but inside a threadpool).
    """
    # create job id and queue/state
    job_id = str(uuid.uuid4())
    create_job_queue(job_id)
    init_job_state(job_id)

    # prepare output directory for this job
    job_dir = _unique_output_dir(UPLOAD_DIR, prefix="job")
    
    
    # save video
    upload_path = job_dir / file.filename
    is_audio_detected = False
    
    with open(upload_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    try:
        is_audio_detected = detect_is_audio_trues(upload_path, logger)
    except Exception as e:
        logger.exception("Impossible de détecter le type de média, on supposera video. Erreur: %s", e)
        
    if fond_file is not None:
        # validation simple
        allowed = ("image/png", "image/jpeg", "image/webp")

        if fond_file.content_type not in allowed:
            raise HTTPException(status_code=400, detail="Type d'image de fond non autorisé")
        
        ext = Path(fond_file.filename).suffix or (".png")
        fond = f"{str(job_dir)}/fond{ext}"
        
        with open(Path(fond), "wb") as buffer:
            shutil.copyfileobj(fond_file.file, buffer)


    # envoyer event upload saved
    notify_job(
        job_id, 
        "task_finished", 
        {
            "task": "upload",
            "info": "Assemble du fichier sous titre et video reussit. ",
            "data": str(upload_path),
            "is_audio": is_audio_detected,
            "download": "True"
        }
    )
    
    # snapshot initial des tasks (pending + upload done)
    initial_state = get_job_state(job_id) or {}
    
    resp_initial = {
        "job_id": job_id,
        "tasks": list(initial_state.values()),
    }
    
    # run pipeline
    asyncio.create_task(
        _run_full_pipeline(
            upload_path,            
            job_dir,
            language=language,
            whisper_model="small",
            device="cuda",
            position=position,
            font_name=font_name,
            font_size=int(font_size),
            font_color=font_color,
            font_outline_colors=font_outline_color,
            is_audio=is_audio_detected,
            fond=fond,
            job_id=job_id
        )
    )

    return JSONResponse(content=resp_initial, status_code=202)

@app.get("/job/{job_id}")
async def get_job_status(job_id: str):
    state = get_job_state(job_id)
    if state is None:
        return JSONResponse({"error": "job not found"}, status_code=404)
    return JSONResponse({"job_id": job_id, "tasks": list(state.values())}, status_code=200)
