# crud.py
from db.db import SessionLocal
from model.models_db import Job, JobFile
from sqlalchemy.orm import Session, joinedload
from datetime import datetime

def create_job(job_id: str, db: Session = None):
    close = False
    if db is None:
        db = SessionLocal()
        close = True
    job = Job(id=job_id, status="started", start_time=datetime.utcnow())
    db.add(job)
    db.commit()
    db.refresh(job)
    if close:
        db.close()
    return job

def set_job_status(job_id: str, status: str, message: str = None):
    db = SessionLocal()
    job = db.query(Job).get(job_id)
    if not job:
        db.close()
        return None
    job.status = status
    if message is not None:
        job.message = message
    if status in ("finished", "error", "canceled"):
        job.end_time = datetime.utcnow()
    db.commit()
    db.refresh(job)
    db.close()
    return job

def add_job_file(job_id: str, file_type: str, path: str):
    db = SessionLocal()
    job = db.query(Job).get(job_id)
    if not job:
        db.close()
        return None
    jf = JobFile(job_id=job_id, file_type=file_type, path=path)
    db.add(jf)
    db.commit()
    db.refresh(jf)
    db.close()
    return jf

def get_job(job_id: str):
    db = SessionLocal()
    job = db.query(Job).get(job_id)
    db.close()
    return job

def _serialize_job(job: Job) -> dict:
    return {
        "id": job.id,
        "status": job.status,
        "start_time": job.start_time.isoformat() if job.start_time else None,
        "end_time": job.end_time.isoformat() if job.end_time else None,
        "message": job.message,
        "files": [
            {
                "id": f.id,
                "file_type": f.file_type,
                "path": f.path,
                "created_at": f.created_at.isoformat() if f.created_at else None
            }
            for f in job.files
        ]
    }

def get_all_jobs():
    """
    Retourne la liste de tous les jobs (sérialisée) ordonnés par start_time descendant.
    """
    db = SessionLocal()
    try:
        jobs = db.query(Job).options(joinedload(Job.files)).order_by(Job.start_time.desc()).all()
        return [_serialize_job(j) for j in jobs]
    finally:
        db.close()

def get_job_serialized(job_id: str):
    """
    Retourne un job sérialisé (ou None).
    """
    db = SessionLocal()
    try:
        job = db.query(Job).options(joinedload(Job.files)).get(job_id)
        if not job:
            return None
        return _serialize_job(job)
    finally:
        db.close()