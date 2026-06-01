from pydantic import BaseModel
from typing import List, Dict, Any

class UserProfile(BaseModel):
    user_id: str
    preferences: Dict[str, Any]  # e.g., {"country": "USA", "price_min": 100000, "price_max": 500000}

class Interaction(BaseModel):
    listing_id: str
    action: str  # "view", "favorite", "purchase"
    timestamp: str

class RecommendationRequest(BaseModel):
    profile: UserProfile
    interactions: List[Interaction]
    top_n: int = 10

class Recommendation(BaseModel):
    listing_id: str
    reason: str