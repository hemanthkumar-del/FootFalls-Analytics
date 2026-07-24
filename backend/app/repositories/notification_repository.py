from app.database import get_database
from app.schemas.notification import NotificationBase
from datetime import datetime, timezone
from bson import ObjectId

class NotificationRepository:
    def __init__(self):
        self.collection = get_database().get_collection("notifications")

    async def add_notification(self, notification: NotificationBase):
        doc = notification.model_dump()
        doc["createdAt"] = datetime.now(timezone.utc)
        doc["isRead"] = False
        res = await self.collection.insert_one(doc)
        doc["_id"] = str(res.inserted_id)
        return doc

    async def get_notifications(self, unread_only: bool = False, limit: int = 50):
        query = {"isRead": False} if unread_only else {}
        cursor = self.collection.find(query).sort("createdAt", -1).limit(limit)
        docs = []
        async for doc in cursor:
            doc["_id"] = str(doc["_id"])
            docs.append(doc)
        return docs

    async def mark_as_read(self, notification_id: str):
        try:
            await self.collection.update_one(
                {"_id": ObjectId(notification_id)},
                {"$set": {"isRead": True}}
            )
        except Exception:
            pass

    async def delete_notification(self, notification_id: str):
        try:
            await self.collection.delete_one({"_id": ObjectId(notification_id)})
        except Exception:
            pass
