# api.py
import uuid
import shutil
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware

from utils.helper.notify_job import (
    create_job_queue,
    init_job_state,
    notify_job,
    get_job_state
)

from utils.helper.detect_is_audio import detect_is_audio_trues

from service.crud import get_all_jobs, get_job_serialized
from pipeline import run_full_pipeline, unique_output_dir
from sse import router as sse_router
from service.crud import create_job, add_job_file
from db.db import init_db

app = FastAPI(title="Pipeline Audio → Sous-titres")
init_db()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# dossier uploads accessible via /uploads
UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=str(UPLOAD_DIR)), name="uploads")

# inclure le router SSE
app.include_router(sse_router)


@app.post("/video/process")
async def upload_and_process_video(
    language: str = Form("fr"),
    position: str = Form("bottom-center"),
    font_name: str = Form("Arial"),
    font_size: int = Form(24),
    font_color: str = Form("#FFFFFF"),
    font_outline_color: str = Form("#000000"),
    fond: Optional[str] = Form(None),
    fond_file: Optional[UploadFile] = File(None),
    file: UploadFile = File(...),
):
    # create job id and queue/state
    job_id = str(uuid.uuid4())
    create_job_queue(job_id)
    init_job_state(job_id)
    
    #job dans bdd
    create_job(job_id)

    # prepare output directory for this job
    job_dir = unique_output_dir(UPLOAD_DIR, prefix="job")

    # save upload
    upload_path = job_dir / file.filename
    with open(upload_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    is_audio_detected = False
    try:
        is_audio_detected = detect_is_audio_trues(upload_path, None)  # logger optional
    except Exception:
        # si detection fail, on considère video
        is_audio_detected = False

    # traiter fond_file si fourni
    if fond_file is not None:
        allowed = ("image/png", "image/jpeg", "image/webp")
        if fond_file.content_type not in allowed:
            raise HTTPException(status_code=400, detail="Type d'image de fond non autorisé")

        ext = Path(fond_file.filename).suffix or ".png"
        fond_path = job_dir / f"fond{ext}"
        with open(fond_path, "wb") as buffer:
            shutil.copyfileobj(fond_file.file, buffer)
        fond = str(fond_path)

    # après sauvegarde du fichier upload:
    add_job_file(job_id, "uploaded", str(upload_path))
    
    # notify upload saved
    notify_job(job_id, "task_finished", {
        "task": "upload",
        "info": "Fichier uploadé.",
        "data": str(upload_path),
        "is_audio": is_audio_detected,
        "download": "True"
    })

    # initial snapshot
    initial_state = get_job_state(job_id) or {}
    resp_initial = {
        "job_id": job_id,
        "tasks": list(initial_state.values()),
    }

    # lancer la pipeline en tâche de fond
    # (on peut ajuster whisper_model/device depuis les params si souhaité)
    import asyncio
    asyncio.create_task(
        run_full_pipeline(
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


@app.get("/jobs")
def list_jobs():
    """
    Retourne tous les jobs enregistrés (avec leurs fichiers) sous forme JSON.
    """
    jobs = get_all_jobs()
    return {"count": len(jobs), "jobs": jobs}

@app.get("/jobs/{job_id}")
def get_job(job_id: str):
    """
    Détails d'un job unique.
    """
    job = get_job_serialized(job_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Job non trouvé")
    return job