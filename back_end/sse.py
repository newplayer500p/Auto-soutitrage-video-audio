# sse.py
import asyncio
import json
from fastapi import APIRouter, Request
from fastapi.responses import StreamingResponse, JSONResponse

from utils.helper.notify_job import get_job_queue, cleanup_job

router = APIRouter()


@router.get("/stream/{job_id}")
async def stream_job(job_id: str, request: Request):
    q = get_job_queue(job_id)
    if q is None:
        return JSONResponse({"error": "job not found"}, status_code=404)

    async def event_generator():
        try:
            while True:
                if await request.is_disconnected():
                    break
                try:
                    msg = await asyncio.wait_for(q.get(), timeout=15.0)
                except asyncio.TimeoutError:
                    # keep-alive
                    yield ":\n\n"
                    continue

                yield f"data: {msg}\n\n"

                try:
                    obj = json.loads(msg)
                    if obj.get("event") in ("finished", "error"):
                        break
                except Exception:
                    pass
        finally:
            cleanup_job(job_id)

    return StreamingResponse(event_generator(), media_type="text/event-stream")
