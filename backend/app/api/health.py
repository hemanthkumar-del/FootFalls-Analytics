from fastapi import APIRouter
import psutil
from app.services.camera_service import worker_registry
from app.database import get_database

router = APIRouter()

@router.get("/")
async def get_health():
    # Check MongoDB status
    mongo_status = "offline"
    try:
        db = get_database()
        if db is not None:
            await db.command("ping")
            mongo_status = "online"
    except Exception:
        pass

    # Gather system metrics
    memory = psutil.virtual_memory()
    cpu_percent = psutil.cpu_percent(interval=0.1)

    return {
        "status": "online",
        "version": "1.0.0",
        "mongodb_status": mongo_status,
        "firebase_status": "online", # Handled via mobile SDK mostly
        "active_workers": len(worker_registry.workers),
        "system_health": {
            "cpu_usage_percent": cpu_percent,
            "memory_usage_percent": memory.percent,
            "memory_used_mb": memory.used / (1024 * 1024),
            "memory_total_mb": memory.total / (1024 * 1024),
        }
    }
