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


import math

class MLRecommender(RuleBasedRecommender):
    """
    High-rigor ML Recommender using Vector Space Model (VSM) and Cosine Similarity.
    Constructs multi-dimensional features over prices, areas, and categorical properties.
    """
    def _extract_vector(self, listing: dict) -> list:
        # Vector structure: [log_price, log_area, is_sa, is_ae, is_qa, is_residential, is_commercial]
        price = float(listing.get("price", 1000000))
        area = float(listing.get("area_sqm", 500))
        
        # Log scaling to mitigate large scale variance
        log_price = math.log10(price) if price > 0 else 0.0
        log_area = math.log10(area) if area > 0 else 0.0
        
        country = listing.get("country", "")
        is_sa = 1.0 if country == "saudiArabia" else 0.0
        is_ae = 1.0 if country == "uae" else 0.0
        is_qa = 1.0 if country == "qatar" else 0.0
        
        ltype = listing.get("type", "")
        is_res = 1.0 if ltype == "residential" else 0.0
        is_com = 1.0 if ltype == "commercial" else 0.0

        return [log_price, log_area, is_sa, is_ae, is_qa, is_res, is_com]

    def _cosine_similarity(self, vec_a: list, vec_b: list) -> float:
        dot_product = sum(a * b for a, b in zip(vec_a, vec_b))
        norm_a = math.sqrt(sum(a * a for a in vec_a))
        norm_b = math.sqrt(sum(b * b for b in vec_b))
        if norm_a == 0.0 or norm_b == 0.0:
            return 0.0
        return dot_product / (norm_a * norm_b)

    def recommend(self, profile: UserProfile, interactions: List[Interaction], top_n: int) -> List[Recommendation]:
        prefs = profile.preferences
        
        # 1. Build Target User Preference Vector
        pref_price = (float(prefs.get("price_min", 0)) + float(prefs.get("price_max", 10000000))) / 2.0
        pref_area = (float(prefs.get("area_min", 0)) + float(prefs.get("area_max", 5000))) / 2.0
        
        log_pref_price = math.log10(pref_price) if pref_price > 0 else 6.0
        log_pref_area = math.log10(pref_area) if pref_area > 0 else 2.7
        
        pref_country = prefs.get("country", "")
        is_sa = 1.0 if pref_country == "saudiArabia" else 0.0
        is_ae = 1.0 if pref_country == "uae" else 0.0
        is_qa = 1.0 if pref_country == "qatar" else 0.0
        
        pref_type = prefs.get("type", "")
        is_res = 1.0 if pref_type == "residential" else 0.0
        is_com = 1.0 if pref_type == "commercial" else 0.0

        user_vector = [log_pref_price, log_pref_area, is_sa, is_ae, is_qa, is_res, is_com]

        # 2. Adjust target user vector using interaction history centroid
        interacted_vectors = []
        listings_map = {l["id"]: l for l in self.listings}
        
        for interaction in interactions:
            lid = interaction.listing_id
            if lid in listings_map:
                weight = 1.5 if interaction.action == "favorite" else 1.0
                vec = self._extract_vector(listings_map[lid])
                weighted_vec = [v * weight for v in vec]
                interacted_vectors.append(weighted_vec)
        
        if interacted_vectors:
            # Add centroid of interactions to user vector
            num_vecs = len(interacted_vectors)
            centroid = [sum(col) / num_vecs for col in zip(*interacted_vectors)]
            user_vector = [u + c for u, c in zip(user_vector, centroid)]

        # 3. Calculate similarity score for all listings
        scored = []
        for listing in self.listings:
            listing_vector = self._extract_vector(listing)
            sim = self._cosine_similarity(user_vector, listing_vector)
            scored.append((listing["id"], sim))

        # Sort by similarity descending, then id ascending
        scored.sort(key=lambda x: (-x[1], x[0]))

        return [
            Recommendation(listing_id=lid, reason=f"Mathematical match score: {sim:.4f}")
            for lid, sim in scored[:top_n]
        ]

