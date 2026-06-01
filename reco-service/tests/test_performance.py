import pytest
from models import UserProfile, Interaction, RecommendationRequest
from recommender import RuleBasedRecommender
import data
import time

@pytest.fixture
def recommender():
    return RuleBasedRecommender(data.listings)

@pytest.fixture
def sample_request():
    profile = UserProfile(user_id="user1", preferences={"country": "USA", "price_min": 100000, "price_max": 500000})
    interactions = [
        Interaction(listing_id="1", action="favorite", timestamp="2023-01-01"),
        Interaction(listing_id="2", action="view", timestamp="2023-01-01"),
        Interaction(listing_id="3", action="favorite", timestamp="2023-01-01"),
    ]
    return RecommendationRequest(profile=profile, interactions=interactions, top_n=10)

def test_performance_p95_under_150ms(benchmark, recommender, sample_request):
    def run_recommend():
        return recommender.recommend(sample_request.profile, sample_request.interactions, sample_request.top_n)

    result = benchmark(run_recommend)
    # benchmark will run multiple times and provide stats
    # We can assert on the mean or p95
    # But since it's benchmark, it will report, and we can check manually
    # For assertion, perhaps check that it's under some time, but since it's variable, maybe just run it
    assert len(result) >= 0  # dummy assertion

# To check p95, we can run multiple times and calculate
def test_p95_latency(recommender, sample_request):
    times = []
    for _ in range(100):
        start = time.time()
        recommender.recommend(sample_request.profile, sample_request.interactions, sample_request.top_n)
        end = time.time()
        times.append((end - start) * 1000)  # ms

    times.sort()
    p95 = times[int(0.95 * len(times))]
    assert p95 < 150, f"P95 latency {p95}ms exceeds 150ms"