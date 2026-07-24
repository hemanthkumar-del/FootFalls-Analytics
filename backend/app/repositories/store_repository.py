from app.firebase import get_firestore
from app.schemas.store import StoreProfileBase, StoreProfileUpdate
from datetime import datetime, timezone

class StoreRepository:
    def __init__(self):
        pass
        
    @property
    def collection(self):
        return get_firestore().collection("store_profile")
        
    async def get_profile(self):
        doc_ref = self.collection.document("default")
        doc = await doc_ref.get()
        
        if not doc.exists:
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
                "updated_at": datetime.now(timezone.utc).isoformat()
            }
            await doc_ref.set(default_profile)
            default_profile["_id"] = "default"
            return default_profile
            
        data = doc.to_dict()
        data["_id"] = doc.id
        return data

    async def update_profile(self, update_data: StoreProfileUpdate):
        update_dict = {k: v for k, v in update_data.model_dump().items() if v is not None}
        update_dict["updated_at"] = datetime.now(timezone.utc).isoformat()
        
        doc_ref = self.collection.document("default")
        doc = await doc_ref.get()
        
        if doc.exists:
            await doc_ref.update(update_dict)
        else:
            await doc_ref.set(update_dict)
            
        return await self.get_profile()
