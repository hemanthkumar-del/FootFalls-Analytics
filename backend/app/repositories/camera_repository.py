from bson import ObjectId
from app.database import get_database
from app.schemas.camera import CameraCreate, CameraUpdate
from datetime import datetime, timezone

class CameraRepository:
    def __init__(self):
        self.collection = get_database().get_collection("cameras")

    async def get_all(self):
        cursor = self.collection.find({})
        return [self._map_doc(doc) async for doc in cursor]

    async def get_by_id(self, camera_id: str):
        doc = await self.collection.find_one({"_id": ObjectId(camera_id)})
        return self._map_doc(doc) if doc else None

    async def create(self, camera: CameraCreate):
        doc = camera.model_dump()
        doc["created_at"] = datetime.now(timezone.utc)
        doc["updated_at"] = datetime.now(timezone.utc)
        result = await self.collection.insert_one(doc)
        doc["_id"] = result.inserted_id
        return self._map_doc(doc)

    async def update(self, camera_id: str, camera_update: CameraUpdate):
        update_data = {k: v for k, v in camera_update.model_dump().items() if v is not None}
        if not update_data:
            return await self.get_by_id(camera_id)
            
        update_data["updated_at"] = datetime.now(timezone.utc)
        await self.collection.update_one(
            {"_id": ObjectId(camera_id)},
            {"$set": update_data}
        )
        return await self.get_by_id(camera_id)

    async def delete(self, camera_id: str):
        result = await self.collection.delete_one({"_id": ObjectId(camera_id)})
        return result.deleted_count > 0

    def _map_doc(self, doc: dict) -> dict:
        if doc and "_id" in doc:
            doc["_id"] = str(doc["_id"])
        return doc
