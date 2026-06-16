from fastapi import FastAPI
from typing import List
from datetime import datetime
from models import RecommendationRequest, Recommendation
from recommender import MLRecommender
import data

app = FastAPI(title="Recommender Microservice", version="1.0.0")

recommender = MLRecommender(data.listings)

@app.get("/health")
def health():
    return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}

@app.post("/v1/recommendations", response_model=List[Recommendation])
def get_recommendations(request: RecommendationRequest):
    return recommender.recommend(request.profile, request.interactions, request.top_n)