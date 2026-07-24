from app.firebase import get_firestore
from app.schemas.notification import NotificationBase
from datetime import datetime, timezone
from google.cloud import firestore

class NotificationRepository:
    def __init__(self):
        pass
        
    @property
    def collection(self):
        return get_firestore().collection("notifications")

    async def add_notification(self, notification: NotificationBase):
        doc = notification.model_dump()
        doc["createdAt"] = datetime.now(timezone.utc).isoformat()
        doc["isRead"] = False
        
        new_ref = self.collection.document()
        await new_ref.set(doc)
        
        doc["_id"] = new_ref.id
        return doc

    async def get_notifications(self, unread_only: bool = False, limit: int = 50):
        query = self.collection
        if unread_only:
            query = query.where(filter=firestore.FieldFilter("isRead", "==", False))
            
        query = query.order_by("createdAt", direction=firestore.Query.DESCENDING).limit(limit)
        
        docs = []
        async for doc in query.stream():
            data = doc.to_dict()
            data["_id"] = doc.id
            docs.append(data)
        return docs

    async def mark_as_read(self, notification_id: str):
        try:
            await self.collection.document(notification_id).update({"isRead": True})
        except Exception:
            pass

    async def delete_notification(self, notification_id: str):
        try:
            await self.collection.document(notification_id).delete()
        except Exception:
            pass
