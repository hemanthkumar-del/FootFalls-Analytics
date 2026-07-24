import pymongo
from pymongo.errors import ConnectionFailure, ServerSelectionTimeoutError
import logging
from config.settings import settings

logger = logging.getLogger(__name__)

class DatabaseConnection:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(DatabaseConnection, cls).__new__(cls)
            cls._instance.client = None
            cls._instance.db = None
            cls._instance.connect()
        return cls._instance

    def connect(self):
        """Attempts to connect to MongoDB. Fails gracefully if unavailable."""
        try:
            # serverSelectionTimeoutMS=2000 ensures it doesn't block the AI engine forever if DB is down
            self.client = pymongo.MongoClient(
                settings.MONGODB_URI, 
                serverSelectionTimeoutMS=2000
            )
            # Test connection
            self.client.admin.command('ping')
            self.db = self.client[settings.DATABASE_NAME]
            logger.info("Successfully connected to MongoDB.")
        except (ConnectionFailure, ServerSelectionTimeoutError) as e:
            logger.error(f"Failed to connect to MongoDB: {e}")
            self.client = None
            self.db = None

    def get_collection(self, name: str):
        """Returns the collection if connected, else None."""
        if self.db is not None:
            return self.db[name]
        return None

db_connection = DatabaseConnection()
