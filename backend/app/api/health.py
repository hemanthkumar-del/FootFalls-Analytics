from fastapi import APIRouter
import psutil
from app.services.camera_service import worker_registry
from app.firebase import get_firestore

router = APIRouter()

@router.get("/")
async def get_health():
    # Check Firestore status
    db_status = "offline"
    try:
        db = get_firestore()
        if db is not None:
            # Simple read check
            await db.collection("health_check").limit(1).get()
            db_status = "online"
    except Exception:
        pass

    # Gather system metrics
    memory = psutil.virtual_memory()
    cpu_percent = psutil.cpu_percent(interval=0.1)

    return {
        "status": "online",
        "version": "1.0.0",
        "database_status": db_status,
        "active_workers": len(worker_registry.workers),
        "system_health": {
            "cpu_usage_percent": cpu_percent,
            "memory_usage_percent": memory.percent,
            "memory_used_mb": memory.used / (1024 * 1024),
            "memory_total_mb": memory.total / (1024 * 1024),
        }
    }
