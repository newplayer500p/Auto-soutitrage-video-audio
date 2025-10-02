# utils/helper/notify_job.py
import asyncio
import json
from datetime import datetime
from typing import Dict, Optional, Any, List, Tuple

# --- configuration (tu peux l'importer depuis app.py si tu préfères) ---
# Format: list of (task_id, human_label)
# Exemple minimal - adapte l'ordre/labels avec ceux de ton app
TASKS_ORDER: List[Tuple[str, str]] = [
    ("upload", "Upload vers le serveur"),
    ("extraction", "Extraction de l'audio"),
    ("isolation_voix", "Isolation du voix"),
    ("transcription", "Transcription et alignement"),
    ("creation_ass", "Génération fichier sous titre .ass"),
    ("assemblage", "Incrustation du sous-titres"),
    ("finished", "Terminé"),
]

# --- état global stocké dans le module ---
job_queues: Dict[str, asyncio.Queue] = {}
job_states: Dict[str, Dict[str, dict]] = {}  # job_id -> { task_id: {...} }


# --- helpers pour job queues / states ---
def create_job_queue(job_id: str) -> None:
    """Créer une queue asyncio pour job_id (écrase si existante)."""
    q = asyncio.Queue()
    job_queues[job_id] = q


def init_job_state(job_id: str, tasks_order: Optional[List[Tuple[str, str]]] = None) -> None:
    """Initialise la map tasks pour le job avec status 'pending'."""
    order = tasks_order if tasks_order is not None else TASKS_ORDER
    state = {}
    for task_id, label in order:
        state[task_id] = {"id": task_id, "label": label, "status": "pending", "info": None}
    job_states[job_id] = state


def get_job_queue(job_id: str) -> Optional[asyncio.Queue]:
    return job_queues.get(job_id)


def get_job_state(job_id: str) -> Optional[Dict[str, dict]]:
    return job_states.get(job_id)


# --- internal helper pour marquer le status (doit être appelé dans l'event loop) ---
def _mark_task_in_loop(job_id: str, task_id: str, status: str, info: Optional[dict] = None) -> None:
    s = job_states.get(job_id)
    if not s:
        return
    if task_id not in s:
        # si tâche inconnue on l'ajoute (tolérance)
        s[task_id] = {"id": task_id, "label": task_id, "status": status, "info": info}
        return

    s[task_id]["status"] = status
    if info is not None:
        s[task_id]["info"] = info


# --- utilitaires temps / serialisation ---
def _now_iso() -> str:
    return datetime.utcnow().isoformat() + "Z"


def _safe_json_dumps(obj: Any) -> str:
    try:
        return json.dumps(obj, default=str)
    except Exception:
        # fallback minimal
        return json.dumps({"repr": repr(obj)}, default=str)


# --- principale fonction publique: notify_job ---
def notify_job(job_id: str, event: str, payload: dict) -> None:
    """
    Pousse un message JSON dans la queue du job ET met à jour job_states pour
    certains événements standards (task_started, task_finished, task_info, error).

    Usage examples:
      notify_job(job_id, "task_started", {"task": "extraction"})
      notify_job(job_id, "task_finished", {"task": "extraction", "result": {"wav": "/uploads/..."}})
    """
    q = job_queues.get(job_id)
    if q is None:
        # pas de queue: ignore silencieusement (ou log si tu veux)
        return

    # Prépare le message (texte JSON)
    message_obj = {"event": event, "payload": payload or {}, "ts": _now_iso()}
    message_text = _safe_json_dumps(message_obj)

    # Récupère la loop (on suppose la loop principale)
    try:
        loop = asyncio.get_running_loop()
    except RuntimeError:
        loop = asyncio.get_event_loop()

    # 1) push du message dans la queue (thread-safe / loop-safe)
    loop.call_soon_threadsafe(q.put_nowait, message_text)

    # 2) mise à jour de l'état si événement standard (on l'exécute dans la loop aussi)
    def _apply_state_update():
        try:
            if event == "task_started":
                task_id = payload.get("task")
                if task_id:
                    _mark_task_in_loop(job_id, task_id, "in_progress", payload.get("info"))
            elif event == "task_finished":
                task_id = payload.get("task")
                info = payload.get("info") or payload
                if task_id:
                    _mark_task_in_loop(job_id, task_id, "done", info)
            elif event == "error":
                task_id = payload.get("task")
                if task_id:
                    _mark_task_in_loop(job_id, task_id, "error", {"error": payload.get("error") or payload})
            elif event == "finished":
                # marque tâche globale finished
                _mark_task_in_loop(job_id, "finished", "done", payload or {})
        except Exception:
            # protège la loop contre erreur d'update
            pass

    # schedule update in loop
    loop.call_soon_threadsafe(_apply_state_update)


# --- petite fonction utilitaire pour cleanup de job ---
def cleanup_job(job_id: str) -> None:
    job_queues.pop(job_id, None)
    job_states.pop(job_id, None)
