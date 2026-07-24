from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    GOOGLE_APPLICATION_CREDENTIALS: str | None = None
    YOLO_MODEL_PATH: str = "yolov8n.pt"
    CONFIDENCE_THRESHOLD: float = 0.5
    PORT: int = 8000
    ENVIRONMENT: str = "development"
    CORS_ORIGINS: str = "*" # Comma-separated list for production
    
    FIREBASE_PROJECT_ID: str = ""
    FIREBASE_API_KEY: str = ""
    GOOGLE_CLIENT_ID: str = ""
    JWT_SECRET: str = "placeholder_secret"

    @property
    def cors_origins_list(self) -> List[str]:
        if self.CORS_ORIGINS == "*":
            return ["*"]
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",")]

    class Config:
        env_file = ".env"

settings = Settings()
