# Recommender Microservice

A FastAPI-based microservice for generating personalized land plot recommendations.

## Features

- Rule-based recommendation engine
- Supports user profiles and interaction history
- Deterministic outputs for same inputs
- Extension point for ML models
- REST API endpoint: POST /v1/recommendations

## Requirements

- Python 3.8+
- FastAPI
- Uvicorn
- Pydantic

## Installation

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Run the service:
   ```bash
   uvicorn app:app --reload
   ```

## API Usage

### POST /v1/recommendations

Request body:
```json
{
  "profile": {
    "user_id": "user123",
    "preferences": {
      "country": "USA",
      "price_min": 100000,
      "price_max": 500000
    }
  },
  "interactions": [
    {
      "listing_id": "1",
      "action": "favorite",
      "timestamp": "2023-01-01T00:00:00Z"
    }
  ],
  "top_n": 10
}
```

Response:
```json
[
  {
    "listing_id": "1",
    "reason": "favorite"
  },
  {
    "listing_id": "3",
    "reason": "same_country"
  }
]
```

## Testing

Run unit tests:
```bash
pytest tests/test_recommender.py
```

Run performance tests:
```bash
pytest tests/test_performance.py
```

## Recommendation Logic

The rule-based engine considers:
- Favorites: listings marked as favorite
- Recently viewed: listings viewed by the user
- Profile preferences: country and price range matches

Reason codes:
- `favorite`: User favorited this listing
- `recently_viewed`: User viewed this listing
- `same_country`: Matches user's preferred country
- `similar_price`: Within user's price range

## Extension for ML

The `MLRecommender` class provides an extension point for machine learning models. Currently falls back to rule-based logic.