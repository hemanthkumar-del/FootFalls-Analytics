from fastapi import FastAPI
import logging
import asyncio
from contextlib import asynccontextmanager
from app.database import connect_to_mongo, close_mongo_connection
from app.api import health, cameras, analytics, websocket, store, notifications
from app.core.config import settings
from app.services.detection_service import DetectionService
from app.services.camera_service import worker_registry

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Initializing FootFalls Backend Phase 4...")
    await connect_to_mongo()
    
    DetectionService()
    
    from app.repositories.camera_repository import CameraRepository
    from app.schemas.camera import CameraCreate
    camera_repo = CameraRepository()
    cameras_list = await camera_repo.get_all_cameras()
    
    if not cameras_list:
        logger.info("No cameras found in database. Registering default 'Demo Camera'...")
        new_cam = CameraCreate(name="Demo Camera", url="0", location="Entrance", status="online", isEnabled=True)
        camera_doc = await camera_repo.create_camera(new_cam)
        cameras_list = [camera_doc]
    
    main_loop = asyncio.get_running_loop()
    for c in cameras_list:
        if c.get("isEnabled", True):
            logger.info(f"Starting camera worker for {c.get('name')} (URL: {c.get('url')})...")
            worker_registry.add_worker(camera_id=str(c['_id']), url=str(c['url']), main_loop=main_loop)
    
    yield
    
    logger.info("Shutting down workers...")
    worker_registry.stop_all()
    await close_mongo_connection()

app = FastAPI(
    title="FootFalls AI Backend",
    description="Smart Footfall Analytics System API",
    version="1.0.0",
    lifespan=lifespan
)

from fastapi.middleware.cors import CORSMiddleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router, prefix="/health", tags=["Health"])
app.include_router(cameras.router, prefix="/cameras", tags=["Cameras"])
app.include_router(analytics.router, prefix="/analytics", tags=["Analytics"])
app.include_router(store.router, prefix="/store", tags=["Store Profile"])
app.include_router(notifications.router, prefix="/notifications", tags=["Notifications"])
app.include_router(websocket.router, tags=["WebSocket"])

from prometheus_fastapi_instrumentator import Instrumentator
Instrumentator().instrument(app).expose(app)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=settings.PORT, reload=False)
