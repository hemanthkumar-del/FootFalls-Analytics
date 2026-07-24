from app.database import get_database
from app.schemas.store import StoreProfileBase, StoreProfileUpdate
from datetime import datetime, timezone
from bson import ObjectId

class StoreRepository:
    def __init__(self):
        self.collection = get_database().get_collection("store_profile")
        
    async def get_profile(self):
        doc = await self.collection.find_one({})
        if not doc:
            # Create default profile
            default_profile = {
                "store_name": "FootFalls Default Store",
                "owner_name": "Admin",
                "phone_number": "+1 800 000 0000",
                "email": "admin@footfalls.app",
                "address": "123 Retail Ave",
                "opening_time": "09:00",
                "closing_time": "21:00",
                "timezone": "UTC",
                "updated_at": datetime.now(timezone.utc)
            }
            res = await self.collection.insert_one(default_profile)
            default_profile["_id"] = str(res.inserted_id)
            return default_profile
        doc["_id"] = str(doc["_id"])
        return doc

    async def update_profile(self, update_data: StoreProfileUpdate):
        update_dict = {k: v for k, v in update_data.model_dump().items() if v is not None}
        update_dict["updated_at"] = datetime.now(timezone.utc)
        
        doc = await self.collection.find_one({})
        if doc:
            await self.collection.update_one({"_id": doc["_id"]}, {"$set": update_dict})
        else:
            await self.collection.insert_one(update_dict)
            
        return await self.get_profile()
