# app.py
from fastapi import FastAPI, UploadFile, File, Form
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from starlette.concurrency import run_in_threadpool


from pathlib import Path
from datetime import datetime
import shutil
import os
import logging
import traceback
from typing import Optional

# importe tes interfaces (adapte si le module s'appelle différemment)
from interfaces.interface import (
    extract_audio_interface,
    get_voice_interface,
    build_phrases_interface,
    segments_to_srt_interface,
    burn_subtitles_into_video_interface,
)
from interfaces.validate_aligned_segment import validate_aligned_segments

logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
logger = logging.getLogger("app")

app = FastAPI(title="Pipeline Audio → Sous-titres")

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
    video_path: Path,
    out_dir: Path,
    *,
    # pipeline parameters (exposés par le endpoint)
    language: str = "en",
    whisper_model: str = "small",
    device: str = "cuda",
    position: str = "bottom-center",
    font_name: str = "Arial",
    font_size: int = 24,
    font_color: str = "#FFFFFF",
    single_model: Optional[str] = None
):
    """
    Appelle les interfaces (bloquantes) dans un thread pool et renvoie un dict résultat.
    """
    result = {"ok": False}
    try:
        # 1) extract audio (WAV)
        wav_out = out_dir / (video_path.stem + ".wav")
        logger.info("Extraction audio -> %s", wav_out)
        extract_info = await run_in_threadpool(
            extract_audio_interface,
            str(video_path),
            str(wav_out),
            44100,
            2
        )
        result["extract_info"] = extract_info
        result["wav_path"] = str(wav_out)
        
        # 2) optionally run spleeter to isolate vocals (get_voice)
        voc = await run_in_threadpool(get_voice_interface, str(wav_out), str(out_dir), single_model)
        # get_voice_interface returns Path or empty string per your code; normalize
        voc_path_str = str(voc) if voc else ""
        result["vocals_path"] = voc_path_str
        

        # 3) transcribe & build phrase segments (from vocals if available else from wav)
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
        
        phrase_segments = validate_aligned_segments(phrase_segments)
            
        result["language_detected"] = detected_lang
        result["n_phrase_segments"] = len(phrase_segments)
                

        # 4) write SRT
        out_dir_str = out_dir / "sous_titre"
        out_dir_str.mkdir(parents=True, exist_ok=True)
        srt_out = out_dir_str / (video_path.stem + ".srt")
        logger.info("Écriture SRT -> %s", srt_out)
        srt_path = await run_in_threadpool(segments_to_srt_interface, phrase_segments, str(srt_out))
        result["srt_path"] = str(srt_path)
        
        


        # 5) burn subtitles
        subtitled_out = out_dir / (video_path.stem + "_sub" + video_path.suffix)
        logger.info("Incrustation SRT -> %s", subtitled_out)
        # remplace la partie où tu appelles burn_subtitles_into_video_interface par :
        await run_in_threadpool(
            burn_subtitles_into_video_interface,
            str(video_path),
            str(srt_out),
            str(subtitled_out),
            position=position,
            font_name=font_name,
            font_size=font_size,
            font_color=font_color,
            outline_color="#000000",
            outline_width=2,
            shadow=0,
            encoding="utf-8",
            ffmpeg_path="ffmpeg",
            overwrite=True,
        )

        
        result["subtitled_video"] = str(subtitled_out)
        
        result["ok"] = True
        return result

    except Exception as e:
        logger.error("Erreur pipeline: %s\n%s", e, traceback.format_exc())
        result["error"] = str(e)
        result["traceback"] = traceback.format_exc()
        return result


@app.post("/video/process")
async def upload_and_process_video(
    language: str = Form("fr"),
    position: str = Form("bottom-center"),
    font_name: str = Form("Arial"),
    font_size: int = Form(24),
    file: UploadFile = File(...),
    transcript: Optional[UploadFile] = File(None)
):
    """
    Endpoint upload + process.
    - Sauvegarde la vidéo (uploads/<timestamp>_<name>/original.ext)
    - Lance la pipeline et retourne JSON avec chemins relatifs si succès.
    NOTE: This endpoint will run the pipeline synchronously (but inside a threadpool).
    """
    # prepare output directory for this job
    job_dir = _unique_output_dir(UPLOAD_DIR, prefix="job")
    # save video
    video_path = job_dir / file.filename
    with open(video_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    transcript_path = None
    if transcript is not None:
        transcript_path = job_dir / transcript.filename
        with open(transcript_path, "wb") as buffer:
            shutil.copyfileobj(transcript.file, buffer)

    # run pipeline
    result = await _run_full_pipeline(
        video_path,
        job_dir,
        language=language,
        whisper_model="small",
        device="cuda",
        position=position,
        font_name=font_name,
        font_size=int(font_size),
        font_color="#FFFFFF",
    )

    # convert paths to URLs served by StaticFiles (if files exist)
    def rel_url(p: str):
        if not p:
            return ""
        p = Path(p)
        try:
            return f"/uploads/{p.relative_to(UPLOAD_DIR).as_posix()}"
        except Exception:
            return str(p)

    resp = {
        "job_dir": str(job_dir),
        "video": f"/uploads/{video_path.relative_to(UPLOAD_DIR).as_posix()}",
        "wav": rel_url(result.get("wav_path", "")),
        "vocals": rel_url(result.get("vocals_path", "")),
        "srt": rel_url(result.get("srt_path", "")),
        "subtitled_video": rel_url(result.get("subtitled_video", "")),
        "language_detected": result.get("language_detected"),
        "extract_info": result.get("extract_info"),
        "ok": result.get("ok", False),
        "error": result.get("error"),
    }
    status = 200 if result.get("ok") else 500
    return JSONResponse(content=resp, status_code=status)
