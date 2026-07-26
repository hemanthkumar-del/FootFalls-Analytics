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
            default_cred_path = r"C:\Users\DELL\Downloads\footfalls-6dab0-firebase-adminsdk-fbsvc-f02072051e.json"
            cred_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS", default_cred_path)
            
            firebase_json_env = os.environ.get("FIREBASE_CREDENTIALS_JSON")
            if firebase_json_env:
                import json
                cred_dict = json.loads(firebase_json_env)
                cred = credentials.Certificate(cred_dict)
                self._app = firebase_admin.initialize_app(cred)
                logger.info("Firebase initialized using FIREBASE_CREDENTIALS_JSON environment variable.")
            elif cred_path and os.path.exists(cred_path):
                cred = credentials.Certificate(cred_path)
                self._app = firebase_admin.initialize_app(cred)
                logger.info(f"Firebase initialized using certificate: {cred_path}")
            else:
                raise ValueError(f"Service account JSON not found at {cred_path}. ADC is disabled.")
        else:
            self._app = firebase_admin.get_app()

        self._db = firestore_async.client()

    @property
    def db(self):
        return self._db

firebase_service = FirebaseService()

def get_firestore():
    return firebase_service.db

