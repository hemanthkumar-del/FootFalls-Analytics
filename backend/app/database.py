import os
from motor.motor_asyncio import AsyncIOMotorClient
from app.core.config import settings

class Database:
    client: AsyncIOMotorClient = None

db = Database()

async def connect_to_mongo():
    uri = os.environ.get("MONGODB_URI") or os.environ.get("MONGO_URI")
    
    if not uri and settings.MONGO_URI and settings.MONGO_URI != "mongodb://localhost:27017":
        uri = settings.MONGO_URI
        
    if not uri:
        if settings.ENVIRONMENT == "development":
            uri = "mongodb://localhost:27017"
        else:
            raise RuntimeError("MongoDB URI is missing! Set MONGODB_URI or MONGO_URI in production. Silently falling back to localhost is disabled.")

    db.client = AsyncIOMotorClient(uri)

async def close_mongo_connection():
    if db.client is not None:
        db.client.close()

def get_database():
    return db.client[settings.DB_NAME]
