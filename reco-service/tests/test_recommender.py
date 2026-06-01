import pytest
from models import UserProfile, Interaction, RecommendationRequest
from recommender import RuleBasedRecommender
import data

@pytest.fixture
def recommender():
    return RuleBasedRecommender(data.listings)

def test_recommend_favorites(recommender):
    profile = UserProfile(user_id="user1", preferences={})
    interactions = [
        Interaction(listing_id="1", action="favorite", timestamp="2023-01-01"),
        Interaction(listing_id="2", action="view", timestamp="2023-01-01"),
    ]
    req = RecommendationRequest(profile=profile, interactions=interactions, top_n=5)
    recs = recommender.recommend(req.profile, req.interactions, req.top_n)
    assert len(recs) == 2
    assert recs[0].listing_id == "1"
    assert recs[0].reason == "favorite"
    assert recs[1].listing_id == "2"
    assert recs[1].reason == "recently_viewed"

def test_recommend_preferences(recommender):
    profile = UserProfile(user_id="user1", preferences={"country": "USA", "price_min": 150000, "price_max": 300000})
    interactions = []
    req = RecommendationRequest(profile=profile, interactions=interactions, top_n=5)
    recs = recommender.recommend(req.profile, req.interactions, req.top_n)
    # Should recommend listings in USA with price in range
    usa_listings = [listing for listing in data.listings if listing['country'] == 'USA' and 150000 <= listing['price'] <= 300000]
    assert len(recs) == len(usa_listings)
    for rec in recs:
        listing = next(listing for listing in data.listings if listing['id'] == rec.listing_id)
        assert listing['country'] == 'USA'
        assert 150000 <= listing['price'] <= 300000
        assert rec.reason in ["same_country", "similar_price"]

def test_deterministic_output(recommender):
    profile = UserProfile(user_id="user1", preferences={"country": "USA"})
    interactions = [
        Interaction(listing_id="1", action="favorite", timestamp="2023-01-01"),
        Interaction(listing_id="3", action="view", timestamp="2023-01-01"),
    ]
    req = RecommendationRequest(profile=profile, interactions=interactions, top_n=10)
    recs1 = recommender.recommend(req.profile, req.interactions, req.top_n)
    recs2 = recommender.recommend(req.profile, req.interactions, req.top_n)
    assert recs1 == recs2

def test_top_n(recommender):
    profile = UserProfile(user_id="user1", preferences={"country": "USA"})
    interactions = []
    req = RecommendationRequest(profile=profile, interactions=interactions, top_n=3)
    recs = recommender.recommend(req.profile, req.interactions, req.top_n)
    assert len(recs) == 3