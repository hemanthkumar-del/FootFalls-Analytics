from app.firebase import get_firestore
from app.schemas.camera import CameraCreate, CameraUpdate
from datetime import datetime, timezone
import uuid

class CameraRepository:
    def __init__(self):
        pass
        
    @property
    def collection(self):
        return get_firestore().collection("cameras")

    async def get_all_cameras(self):
        cameras = []
        async for doc in self.collection.stream():
            data = doc.to_dict()
            data["_id"] = doc.id
            cameras.append(data)
        return cameras

    async def get_camera_by_id(self, camera_id: str):
        try:
            doc_ref = self.collection.document(camera_id)
            doc = await doc_ref.get()
            if doc.exists:
                data = doc.to_dict()
                data["_id"] = doc.id
                return data
            return None
        except Exception:
            return None

    async def create_camera(self, camera: CameraCreate):
        doc = camera.model_dump()
        doc["created_at"] = datetime.now(timezone.utc).isoformat()
        doc["updated_at"] = datetime.now(timezone.utc).isoformat()
        doc["fps"] = 0.0
        doc["uptime"] = 0
        doc["isEnabled"] = True
        doc["isStreaming"] = False
        
        # Firestore async client add() or document().set()
        new_ref = self.collection.document()
        await new_ref.set(doc)
        
        doc["_id"] = new_ref.id
        return doc

    async def update_camera(self, camera_id: str, update_data: CameraUpdate):
        update_dict = {k: v for k, v in update_data.model_dump().items() if v is not None}
        if not update_dict:
            return await self.get_camera_by_id(camera_id)
            
        update_dict["updated_at"] = datetime.now(timezone.utc).isoformat()
        try:
            doc_ref = self.collection.document(camera_id)
            await doc_ref.update(update_dict)
            return await self.get_camera_by_id(camera_id)
        except Exception:
            return None

    async def delete_camera(self, camera_id: str):
        try:
            doc_ref = self.collection.document(camera_id)
            await doc_ref.delete()
            return True
        except Exception:
            return False

    async def update_health(self, camera_id: str, fps: float, is_streaming: bool, error: str = None):
        try:
            update = {
                "fps": fps,
                "isStreaming": is_streaming,
                "lastHeartbeat": datetime.now(timezone.utc).isoformat()
            }
            if error is not None:
                update["errorMessage"] = error
                
            doc_ref = self.collection.document(camera_id)
            await doc_ref.update(update)
        except Exception:
            pass
