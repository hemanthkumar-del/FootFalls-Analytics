from app.database import get_database
from app.schemas.camera import CameraCreate, CameraUpdate
from bson import ObjectId
from datetime import datetime, timezone

class CameraRepository:
    def __init__(self):
        self.collection = get_database().get_collection("cameras")

    async def get_all_cameras(self):
        cursor = self.collection.find({})
        cameras = []
        async for document in cursor:
            document["_id"] = str(document["_id"])
            cameras.append(document)
        return cameras

    async def get_camera_by_id(self, camera_id: str):
        try:
            document = await self.collection.find_one({"_id": ObjectId(camera_id)})
            if document:
                document["_id"] = str(document["_id"])
            return document
        except Exception:
            return None

    async def create_camera(self, camera: CameraCreate):
        doc = camera.model_dump()
        doc["created_at"] = datetime.now(timezone.utc)
        doc["updated_at"] = datetime.now(timezone.utc)
        doc["fps"] = 0.0
        doc["uptime"] = 0
        doc["isEnabled"] = True
        doc["isStreaming"] = False
        res = await self.collection.insert_one(doc)
        doc["_id"] = str(res.inserted_id)
        return doc

    async def update_camera(self, camera_id: str, update_data: CameraUpdate):
        update_dict = {k: v for k, v in update_data.model_dump().items() if v is not None}
        if not update_dict:
            return await self.get_camera_by_id(camera_id)
            
        update_dict["updated_at"] = datetime.now(timezone.utc)
        try:
            await self.collection.update_one(
                {"_id": ObjectId(camera_id)},
                {"$set": update_dict}
            )
            return await self.get_camera_by_id(camera_id)
        except Exception:
            return None

    async def delete_camera(self, camera_id: str):
        try:
            result = await self.collection.delete_one({"_id": ObjectId(camera_id)})
            return result.deleted_count > 0
        except Exception:
            return False

    async def update_health(self, camera_id: str, fps: float, is_streaming: bool, error: str = None):
        try:
            update = {
                "fps": fps,
                "isStreaming": is_streaming,
                "lastHeartbeat": datetime.now(timezone.utc)
            }
            if error is not None:
                update["errorMessage"] = error
                
            await self.collection.update_one(
                {"_id": ObjectId(camera_id)},
                {"$set": update}
            )
        except Exception:
            pass
