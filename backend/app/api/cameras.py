from fastapi import APIRouter, Depends, HTTPException
from typing import List
from app.schemas.camera import CameraCreate, CameraUpdate, CameraInDB
from app.repositories.camera_repository import CameraRepository
from app.services.camera_service import worker_registry
import asyncio

router = APIRouter()

def get_camera_repo():
    return CameraRepository()

@router.get("/", response_model=List[CameraInDB])
async def list_cameras(repo: CameraRepository = Depends(get_camera_repo)):
    return await repo.get_all_cameras()

@router.post("/", response_model=CameraInDB)
async def add_camera(camera: CameraCreate, repo: CameraRepository = Depends(get_camera_repo)):
    doc = await repo.create_camera(camera)
    
    # Hot-start worker if enabled
    if doc.get("isEnabled", True):
        main_loop = asyncio.get_running_loop()
        worker_registry.add_worker(doc["_id"], str(doc["url"]), main_loop)
    
    return doc

@router.put("/{camera_id}", response_model=CameraInDB)
async def update_camera(camera_id: str, camera: CameraUpdate, repo: CameraRepository = Depends(get_camera_repo)):
    old_doc = await repo.get_camera_by_id(camera_id)
    if not old_doc:
        raise HTTPException(status_code=404, detail="Camera not found")

    updated = await repo.update_camera(camera_id, camera)
    if not updated:
        raise HTTPException(status_code=404, detail="Update failed")

    # Handle Hot Reloading
    main_loop = asyncio.get_running_loop()
    
    if updated.get("isEnabled"):
        # If URL changed or wasn't running, we must restart
        if old_doc.get("url") != updated.get("url") or not old_doc.get("isEnabled"):
            worker_registry.add_worker(camera_id, str(updated["url"]), main_loop)
    else:
        worker_registry.stop_worker(camera_id)

    return updated

@router.delete("/{camera_id}")
async def delete_camera(camera_id: str, repo: CameraRepository = Depends(get_camera_repo)):
    # 1. Stop worker
    worker_registry.stop_worker(camera_id)
    # 2. Delete from DB
    deleted = await repo.delete_camera(camera_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Camera not found")
    return {"message": "Camera deleted successfully"}

@router.patch("/{camera_id}/enable")
async def enable_camera(camera_id: str, repo: CameraRepository = Depends(get_camera_repo)):
    update_data = CameraUpdate(isEnabled=True)
    updated = await repo.update_camera(camera_id, update_data)
    if updated:
        main_loop = asyncio.get_running_loop()
        worker_registry.add_worker(camera_id, str(updated["url"]), main_loop)
        return {"status": "enabled"}
    raise HTTPException(404, "Camera not found")

@router.patch("/{camera_id}/disable")
async def disable_camera(camera_id: str, repo: CameraRepository = Depends(get_camera_repo)):
    update_data = CameraUpdate(isEnabled=False)
    updated = await repo.update_camera(camera_id, update_data)
    if updated:
        worker_registry.stop_worker(camera_id)
        return {"status": "disabled"}
    raise HTTPException(404, "Camera not found")

@router.get("/status")
async def get_camera_statuses(repo: CameraRepository = Depends(get_camera_repo)):
    # Fetch all cameras from DB, merge with active registry state
    cameras = await repo.get_all_cameras()
    status_list = []
    
    for c in cameras:
        cid = str(c["_id"])
        worker = worker_registry.get_worker(cid)
        status_list.append({
            "id": cid,
            "name": c.get("name"),
            "is_running_in_memory": worker is not None and worker.running,
            "fps": c.get("fps", 0),
            "uptime": c.get("uptime", 0),
            "isEnabled": c.get("isEnabled", False),
            "isStreaming": c.get("isStreaming", False),
        })
        
    return status_list
