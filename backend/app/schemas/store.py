from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class StoreProfileBase(BaseModel):
    store_name: str
    owner_name: str
    phone_number: str
    email: str
    address: str
    opening_time: str
    closing_time: str
    timezone: str
    logo_url: Optional[str] = None

class StoreProfileUpdate(BaseModel):
    store_name: Optional[str] = None
    owner_name: Optional[str] = None
    phone_number: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    opening_time: Optional[str] = None
    closing_time: Optional[str] = None
    timezone: Optional[str] = None
    logo_url: Optional[str] = None

class StoreProfileInDB(StoreProfileBase):
    id: str = Field(alias="_id")
    updated_at: datetime
