from fastapi import FastAPI
from typing import List
from models import RecommendationRequest, Recommendation
from recommender import RuleBasedRecommender
import data

app = FastAPI(title="Recommender Microservice", version="1.0.0")

recommender = RuleBasedRecommender(data.listings)

@app.post("/v1/recommendations", response_model=List[Recommendation])
def get_recommendations(request: RecommendationRequest):
    return recommender.recommend(request.profile, request.interactions, request.top_n)