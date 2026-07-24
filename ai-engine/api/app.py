from fastapi import FastAPI
from api.routes import router
from api.middleware import setup_middleware
from api.services import engine_service
from database.indexes import setup_indexes
import contextlib

@contextlib.asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Ensure MongoDB Indexes
    setup_indexes()
    
    # Startup: Start the AI engine
    engine_service.start()
    yield
    # Shutdown: Stop the AI engine
    engine_service.stop()

app = FastAPI(
    title="FootFalls API",
    description="FootFalls AI Engine Service API",
    version="1.0.0",
    lifespan=lifespan
)

setup_middleware(app)

app.include_router(router, prefix="/api/v1")
