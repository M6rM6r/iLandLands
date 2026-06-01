from typing import List
from models import UserProfile, Interaction, Recommendation

class RuleBasedRecommender:
    def __init__(self, listings):
        self.listings = listings

    def recommend(self, profile: UserProfile, interactions: List[Interaction], top_n: int) -> List[Recommendation]:
        favorites = {i.listing_id for i in interactions if i.action == "favorite"}
        viewed    = {i.listing_id for i in interactions if i.action == "view"}

        prefs = profile.preferences

        scored = []
        for listing in self.listings:
            score   = 0
            reasons = []

            if listing["id"] in favorites:
                score += 10
                reasons.append(("favorite", 10))

            if listing["id"] in viewed:
                score += 5
                reasons.append(("recently_viewed", 5))

            # Country match (Gulf slug: saudiArabia, uae, qatar, …)
            if "country" in prefs and listing["country"] == prefs["country"]:
                score += 3
                reasons.append(("same_country", 3))

            # City match
            if "city" in prefs and listing.get("city", "").lower() == prefs["city"].lower():
                score += 2
                reasons.append(("same_city", 2))

            # Property type match (residential, commercial, industrial, agricultural, mixed)
            if "type" in prefs and listing.get("type") == prefs["type"]:
                score += 2
                reasons.append(("same_type", 2))

            # Price range match (in local currency units)
            if "price_min" in prefs and "price_max" in prefs:
                if prefs["price_min"] <= listing["price"] <= prefs["price_max"]:
                    score += 2
                    reasons.append(("similar_price", 2))

            # Area range match (sqm)
            if "area_min" in prefs and "area_max" in prefs:
                area = listing.get("area_sqm", 0)
                if prefs["area_min"] <= area <= prefs["area_max"]:
                    score += 1
                    reasons.append(("similar_area", 1))

            if score > 0:
                best_reason = max(reasons, key=lambda x: x[1])[0]
                scored.append((listing["id"], score, best_reason))

        # Sort by score desc, then id asc for determinism
        scored.sort(key=lambda x: (-x[1], x[0]))

        return [Recommendation(listing_id=lid, reason=reason) for lid, _, reason in scored[:top_n]]


class MLRecommender(RuleBasedRecommender):
    """Extension point for ML-based scoring — falls back to rule-based for now."""
    def recommend(self, profile, interactions, top_n):
        return super().recommend(profile, interactions, top_n)
