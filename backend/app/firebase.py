import os
import firebase_admin
from firebase_admin import credentials, firestore_async
import logging

logger = logging.getLogger(__name__)

class FirebaseService:
    def __init__(self):
        self._app = None
        self._db = None

    def initialize(self):
        if not firebase_admin._apps:
            cred_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
            if cred_path and os.path.exists(cred_path):
                cred = credentials.Certificate(cred_path)
                self._app = firebase_admin.initialize_app(cred)
                logger.info(f"Firebase initialized using certificate: {cred_path}")
            else:
                # Fallback to Application Default Credentials
                self._app = firebase_admin.initialize_app()
                logger.info("Firebase initialized using Application Default Credentials.")
        else:
            self._app = firebase_admin.get_app()

        self._db = firestore_async.client()

    @property
    def db(self):
        return self._db

firebase_service = FirebaseService()

def get_firestore():
    return firebase_service.db

