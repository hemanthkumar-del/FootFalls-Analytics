from fastapi import APIRouter, Depends, HTTPException
from typing import List
from app.schemas.camera import CameraCreate, CameraUpdate, CameraInDB
from app.repositories.camera_repository import CameraRepository

router = APIRouter()

def get_camera_repo():
    return CameraRepository()

@router.get("/", response_model=List[CameraInDB])
async def list_cameras(repo: CameraRepository = Depends(get_camera_repo)):
    return await repo.get_all()

@router.post("/", response_model=CameraInDB)
async def add_camera(camera: CameraCreate, repo: CameraRepository = Depends(get_camera_repo)):
    return await repo.create(camera)

@router.put("/{camera_id}", response_model=CameraInDB)
async def update_camera(camera_id: str, camera: CameraUpdate, repo: CameraRepository = Depends(get_camera_repo)):
    updated = await repo.update(camera_id, camera)
    if not updated:
        raise HTTPException(status_code=404, detail="Camera not found")
    return updated

@router.delete("/{camera_id}")
async def delete_camera(camera_id: str, repo: CameraRepository = Depends(get_camera_repo)):
    deleted = await repo.delete(camera_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Camera not found")
    return {"message": "Camera deleted successfully"}
