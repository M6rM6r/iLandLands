import pytest
import requests
from typing import Dict, Any
import json
from contracts import LandPlotContract

BASE_URL = "http://localhost:8000"  # Adjust as needed

class TestAPIContracts:
    """Contract tests for API compliance"""

    @pytest.fixture
    def api_client(self):
        return requests.Session()

    def test_listings_endpoint_contract(self, api_client):
        """Test /v1/listings returns valid LandPlot contracts"""
        response = api_client.get(f"{BASE_URL}/v1/listings")
        assert response.status_code == 200

        data = response.json()
        assert isinstance(data, list)

        for item in data:
            # Validate against contract
            plot = LandPlotContract(**item)
            assert plot.id is not None
            assert plot.title is not None
            assert plot.price > 0
            assert plot.area > 0

    def test_listing_by_id_contract(self, api_client):
        """Test /v1/listings/{id} returns valid contract"""
        # First get a listing ID
        response = api_client.get(f"{BASE_URL}/v1/listings")
        assert response.status_code == 200
        listings = response.json()
        assert len(listings) > 0

        listing_id = listings[0]['id']

        response = api_client.get(f"{BASE_URL}/v1/listings/{listing_id}")
        assert response.status_code == 200

        data = response.json()
        plot = LandPlotContract(**data)

    def test_search_functionality(self, api_client):
        """Test search query parameter"""
        response = api_client.get(f"{BASE_URL}/v1/listings", params={"search": "Riyadh"})
        assert response.status_code == 200

        data = response.json()
        assert isinstance(data, list)

        # Verify search results contain the query
        for item in data:
            assert "riyadh" in item['title'].lower() or "riyadh" in item['location'].lower()

    def test_country_filter(self, api_client):
        """Test country filtering"""
        response = api_client.get(f"{BASE_URL}/v1/listings", params={"country": "saudiArabia"})
        assert response.status_code == 200

        data = response.json()
        for item in data:
            assert item['country'] == "saudiArabia"

    def test_analytics_events_endpoint(self, api_client):
        """Test analytics events posting"""
        event_data = {
            "event_type": "page_view",
            "user_id": "test_user",
            "properties": {"page": "listings"}
        }

        response = api_client.post(f"{BASE_URL}/v1/analytics/events", json=event_data)
        assert response.status_code == 200

    def test_recommendations_contract(self, api_client):
        """Test recommendations API contract"""
        reco_url = "http://localhost:8001"  # Assuming reco-service runs on different port
        reco_data = {
            "user_id": "test_user",
            "preferences": {"country": "UAE"}
        }

        response = api_client.post(f"{reco_url}/v1/recommendations", json=reco_data)
        if response.status_code == 200:
            data = response.json()
            assert isinstance(data, list)
            for rec in data:
                assert "listing_id" in rec
                assert "score" in rec

class TestAPIIntegration:
    """Integration tests for realistic user journeys"""

    def test_full_listing_workflow(self, api_client):
        """Test complete workflow: get listings, search, get details"""
        # Get all listings
        response = api_client.get(f"{BASE_URL}/v1/listings")
        assert response.status_code == 200
        listings = response.json()
        assert len(listings) > 0

        # Search for specific location
        response = api_client.get(f"{BASE_URL}/v1/listings", params={"search": "Dubai"})
        assert response.status_code == 200
        search_results = response.json()

        if search_results:
            # Get details of first result
            listing_id = search_results[0]['id']
            response = api_client.get(f"{BASE_URL}/v1/listings/{listing_id}")
            assert response.status_code == 200
            details = response.json()
            assert details['id'] == listing_id

    def test_analytics_tracking(self, api_client):
        """Test analytics event tracking"""
        events = [
            {"event_type": "app_open", "user_id": "test_user_1"},
            {"event_type": "listing_view", "user_id": "test_user_1", "listing_id": "123"},
            {"event_type": "search", "user_id": "test_user_1", "query": "beachfront"}
        ]

        for event in events:
            response = api_client.post(f"{BASE_URL}/v1/analytics/events", json=event)
            assert response.status_code in [200, 201]

if __name__ == "__main__":
    pytest.main([__file__, "-v"])