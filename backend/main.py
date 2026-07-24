from fastapi import FastAPI
import logging
import asyncio
from contextlib import asynccontextmanager
from app.database import connect_to_mongo, close_mongo_connection
from app.api import health, cameras, analytics, websocket
from app.core.config import settings
from app.services.detection_service import DetectionService
from app.services.camera_service import CameraService

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

# Keep a global reference to camera workers
active_cameras = {}

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Initializing FootFalls Backend...")
    await connect_to_mongo()
    
    # Pre-load YOLO globally so camera threads don't block
    DetectionService()
    
    # Boot a test camera worker for the default webcam
    logger.info("Starting default camera worker (URL: 0)...")
    main_loop = asyncio.get_running_loop()
    cam = CameraService(camera_id="cam_01", url="0", main_loop=main_loop)
    cam.start()
    active_cameras["cam_01"] = cam
    
    yield
    
    # Shutdown
    logger.info("Shutting down workers...")
    for cam in active_cameras.values():
        cam.stop()
    await close_mongo_connection()

app = FastAPI(
    title="FootFalls AI Backend",
    description="Smart Footfall Analytics System API",
    version="1.0.0",
    lifespan=lifespan
)

app.include_router(health.router, prefix="/health", tags=["Health"])
app.include_router(cameras.router, prefix="/cameras", tags=["Cameras"])
app.include_router(analytics.router, prefix="/analytics", tags=["Analytics"])
app.include_router(websocket.router, tags=["WebSocket"])

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=settings.PORT, reload=False)
