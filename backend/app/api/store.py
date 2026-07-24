from fastapi import APIRouter, Depends
from app.repositories.store_repository import StoreRepository
from app.schemas.store import StoreProfileUpdate, StoreProfileInDB

router = APIRouter()

def get_store_repo():
    return StoreRepository()

@router.get("/profile")
async def get_store_profile(repo: StoreRepository = Depends(get_store_repo)):
    return await repo.get_profile()

@router.put("/profile")
async def update_store_profile(data: StoreProfileUpdate, repo: StoreRepository = Depends(get_store_repo)):
    return await repo.update_profile(data)
