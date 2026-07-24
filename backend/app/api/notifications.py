from fastapi import APIRouter, Depends, HTTPException
from app.repositories.notification_repository import NotificationRepository
from app.schemas.notification import NotificationBase

router = APIRouter()

def get_notification_repo():
    return NotificationRepository()

@router.get("/")
async def get_notifications(unread_only: bool = False, repo: NotificationRepository = Depends(get_notification_repo)):
    return await repo.get_notifications(unread_only)

@router.patch("/{notification_id}/read")
async def mark_notification_read(notification_id: str, repo: NotificationRepository = Depends(get_notification_repo)):
    await repo.mark_as_read(notification_id)
    return {"status": "success"}

@router.delete("/{notification_id}")
async def delete_notification(notification_id: str, repo: NotificationRepository = Depends(get_notification_repo)):
    await repo.delete_notification(notification_id)
    return {"status": "success"}
