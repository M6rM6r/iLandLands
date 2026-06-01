from pydantic import BaseModel, Field, validator
from typing import List, Optional
from datetime import datetime
from enum import Enum

class Country(str, Enum):
    saudiArabia = "saudiArabia"
    uae = "uae"
    qatar = "qatar"
    bahrain = "bahrain"
    oman = "oman"
    kuwait = "kuwait"

class LandPlotContract(BaseModel):
    id: str
    title: str = Field(..., min_length=1, max_length=200)
    description: str = Field(..., min_length=1, max_length=2000)
    price: float = Field(..., ge=0)
    area: float = Field(..., ge=0)
    country: Country
    location: str = Field(..., min_length=1, max_length=200)
    imageUrls: List[str] = Field(..., min_items=1)
    isFeatured: bool = False
    createdAt: datetime
    updatedAt: Optional[datetime] = None

    @validator('imageUrls')
    def validate_image_urls(cls, v):
        for url in v:
            if not url.startswith(('http://', 'https://')):
                raise ValueError('Image URLs must be valid HTTP/HTTPS URLs')
        return v

    class Config:
        use_enum_values = True