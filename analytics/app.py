#!/usr/bin/env python3
"""
Gulf Lands Analytics Engine
Advanced analytics and insights platform for real estate data.
"""

import logging
import json
from datetime import datetime
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict
from contextlib import asynccontextmanager
import orjson
import asyncpg
from redis import asyncio as aioredis
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler
import joblib
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from pydantic import BaseModel, Field
import uvicorn

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[logging.FileHandler("analytics.log"), logging.StreamHandler()],
)
logger = logging.getLogger(__name__)


@dataclass
class AnalyticsEvent:
    event_name: str
    user_id: Optional[str]
    session_id: Optional[str]
    properties: Dict[str, Any]
    timestamp: datetime
    user_agent: Optional[str]
    ip_address: Optional[str]


@dataclass
class UserBehavior:
    user_id: str
    session_duration: float
    pages_viewed: int
    searches_performed: int
    favorites_added: int
    contact_requests: int
    last_activity: datetime
    device_type: str
    location: Optional[str]


@dataclass
class MarketInsight:
    metric: str
    value: float
    change_percentage: float
    trend: str
    confidence: float
    recommendations: List[str]


class DatabaseManager:
    def __init__(self, dsn: str):
        self.dsn = dsn
        self.pool = None

    async def initialize(self):
        self.pool = await asyncpg.create_pool(self.dsn, min_size=5, max_size=20)
        logger.info("Database connection pool initialized")

    async def close(self):
        if self.pool:
            await self.pool.close()
            logger.info("Database connection pool closed")

    @asynccontextmanager
    async def get_connection(self):
        async with self.pool.acquire() as connection:
            yield connection


class RedisManager:
    def __init__(self, redis_url: str):
        self.redis_url = redis_url
        self.redis = None

    async def initialize(self):
        self.redis = aioredis.from_url(self.redis_url, decode_responses=False)
        logger.info("Redis connection initialized")


class AnalyticsEngine:
    def __init__(self, db_manager: DatabaseManager, redis_manager: RedisManager):
        self.db = db_manager
        self.redis = redis_manager
        self.price_model = None
        self.demand_model = None
        self.scaler = StandardScaler()

    async def initialize_models(self):
        """Initialize ML models for predictions"""
        try:
            # Load or train price prediction model
            await self._train_price_model()
            await self._train_demand_model()
            logger.info("Analytics models initialized")
        except Exception as e:
            logger.error(f"Failed to initialize models: {e}")

    async def track_event(self, event: AnalyticsEvent):
        """Track analytics event"""
        try:
            async with self.db.get_connection() as conn:
                await conn.execute(
                    """
                    INSERT INTO analytics_events 
                    (event_name, user_id, session_id, properties, user_agent, ip_address, created_at)
                    VALUES ($1, $2, $3, $4, $5, $6, $7)
                    """,
                    event.event_name,
                    event.user_id,
                    event.session_id,
                    json.dumps(event.properties),
                    event.user_agent,
                    event.ip_address,
                    event.timestamp,
                )

            # Non-blocking real-time metric update
            await self._update_realtime_metrics(event)

        except Exception as e:
            logger.error(f"Failed to track event: {e}")
            raise

    async def get_user_behavior(self, user_id: str, days: int = 30) -> UserBehavior:
        """Analyze user behavior patterns"""
        try:
            async with self.db.get_connection() as conn:
                # Get user events
                events = await conn.fetch(
                    """
                    SELECT * FROM analytics_events 
                    WHERE user_id = $1 AND created_at >= NOW() - INTERVAL '$2 days'
                    ORDER BY created_at ASC
                    """,
                    user_id,
                    days,
                )

                if not events:
                    return UserBehavior(
                        user_id=user_id,
                        session_duration=0.0,
                        pages_viewed=0,
                        searches_performed=0,
                        favorites_added=0,
                        contact_requests=0,
                        last_activity=datetime.now(),
                        device_type="unknown",
                        location=None,
                    )

                # Analyze behavior
                session_duration = self._calculate_session_duration(events)
                pages_viewed = sum(
                    1 for e in events if e["event_name"] == "listing_viewed"
                )
                searches_performed = len(
                    [e for e in events if e["event_name"] == "search_performed"]
                )
                favorites_added = len(
                    [e for e in events if e["event_name"] == "added_to_favorites"]
                )
                contact_requests = len(
                    [e for e in events if e["event_name"] == "contact_requested"]
                )

                last_activity = events[-1]["created_at"]
                device_type = self._extract_device_type(events[-1]["user_agent"])
                location = self._extract_location(events[-1]["ip_address"])

                return UserBehavior(
                    user_id=user_id,
                    session_duration=session_duration,
                    pages_viewed=int(pages_viewed),
                    searches_performed=searches_performed,
                    favorites_added=favorites_added,
                    contact_requests=contact_requests,
                    last_activity=last_activity,
                    device_type=device_type,
                    location=location,
                )

        except Exception as e:
            logger.error(f"Failed to get user behavior: {e}")
            raise

    async def get_market_insights(
        self, country: Optional[str] = None
    ) -> List[MarketInsight]:
        """Generate market insights and recommendations"""
        try:
            insights = []

            # Price trends
            price_insight = await self._analyze_price_trends(country)
            if price_insight:
                insights.append(price_insight)

            # Demand analysis
            demand_insight = await self._analyze_demand_trends(country)
            if demand_insight:
                insights.append(demand_insight)

            # Popular locations
            location_insight = await self._analyze_popular_locations(country)
            if location_insight:
                insights.append(location_insight)

            # User engagement
            engagement_insight = await self._analyze_user_engagement(country)
            if engagement_insight:
                insights.append(engagement_insight)

            # Trending listings (from cjchika/realtor_mobile inspiration)
            trending_insight = await self._analyze_trending_listings(country)
            if trending_insight:
                insights.append(trending_insight)

            return insights

        except Exception as e:
            logger.error(f"Failed to get market insights: {e}")
            raise

    async def predict_price(self, features: Dict[str, Any]) -> Dict[str, Any]:
        """Predict property price using ML model"""
        try:
            if not self.price_model:
                raise HTTPException(status_code=500, detail="Price model not available")

            # Prepare features
            feature_vector = self._prepare_price_features(features)

            # Make prediction
            predicted_price = self.price_model.predict([feature_vector])[0]
            confidence = self._calculate_prediction_confidence(feature_vector)

            return {
                "predicted_price": float(predicted_price),
                "confidence": float(confidence),
                "currency": "SAR",
                "features_used": list(features.keys()),
            }

        except Exception as e:
            logger.error(f"Failed to predict price: {e}")
            raise

    async def get_real_time_metrics(self) -> Dict[str, Any]:
        """Get real-time analytics metrics"""
        try:
            metrics = {}

            # Get from Redis
            keys = await self.redis.keys("realtime:*")
            for key in keys:
                value = await self.redis.get(key)
                metrics[key.decode().replace("realtime:", "")] = json.loads(value)

            return metrics

        except Exception as e:
            logger.error(f"Failed to get real-time metrics: {e}")
            raise

    async def _train_price_model(self):
        """Train price prediction model"""
        try:
            async with self.db.get_connection() as conn:
                # Get historical data
                data = await conn.fetch("""
                    SELECT price, area, country, location, is_featured, created_at
                    FROM land_listings
                    WHERE status = 'active' AND price > 0
                """)

                if len(data) < 100:
                    logger.warning("Insufficient data for price model training")
                    return

                # Prepare training data
                df = pd.DataFrame([dict(row) for row in data])
                df = self._prepare_training_data(df)

                # Train model
                X = df.drop("price", axis=1)
                y = df["price"]

                X_scaled = self.scaler.fit_transform(X)

                self.price_model = RandomForestRegressor(
                    n_estimators=100, random_state=42, n_jobs=-1
                )
                self.price_model.fit(X_scaled, y)

                # Save model
                joblib.dump(self.price_model, "price_model.pkl")
                joblib.dump(self.scaler, "price_scaler.pkl")

                logger.info("Price model trained successfully")

        except Exception as e:
            logger.error(f"Failed to train price model: {e}")

    async def _train_demand_model(self):
        """Train demand prediction model"""
        try:
            async with self.db.get_connection() as conn:
                # Get search and view data
                data = await conn.fetch("""
                    SELECT 
                        COUNT(*) as demand_score,
                        country,
                        AVG(price) as avg_price,
                        AVG(area) as avg_area,
                        DATE_TRUNC('hour', created_at) as hour
                    FROM analytics_events
                    WHERE event_name IN ('listing_viewed', 'search_performed')
                    AND created_at >= NOW() - INTERVAL '30 days'
                    GROUP BY country, hour
                """)

                if len(data) < 50:
                    logger.warning("Insufficient data for demand model training")
                    return

                # Prepare training data
                df = pd.DataFrame([dict(row) for row in data])

                # Train model (simplified for demo)
                features = ["avg_price", "avg_area"]
                X = df[features].fillna(0)
                y = df["demand_score"]

                self.demand_model = RandomForestRegressor(
                    n_estimators=50, random_state=42
                )
                self.demand_model.fit(X, y)

                logger.info("Demand model trained successfully")

        except Exception as e:
            logger.error(f"Failed to train demand model: {e}")

    async def _update_realtime_metrics(self, event: AnalyticsEvent):
        """Update real-time metrics in Redis"""
        try:
            # Update event counters
            key = f"realtime:events:{event.event_name}"
            await self.redis.incr(key)
            await self.redis.expire(key, 3600)  # 1 hour expiry

            # Update user metrics
            if event.user_id:
                user_key = f"realtime:users:{event.user_id}"
                await self.redis.incr(user_key)
                await self.redis.expire(user_key, 86400)  # 24 hour expiry

            # Update country metrics
            country = event.properties.get("country")
            if country:
                country_key = f"realtime:countries:{country}"
                await self.redis.incr(country_key)
                await self.redis.expire(country_key, 3600)

        except Exception as e:
            logger.error(f"Failed to update realtime metrics: {e}")

    def _calculate_session_duration(self, events: List) -> float:
        """Calculate total session duration"""
        if len(events) < 2:
            return 0.0

        times = [
            e["created_at"] if isinstance(e, dict) else e.get("created_at")
            for e in events
        ]
        times = [t for t in times if t is not None]
        if not times:
            return 0.0

        start_time = min(times)
        end_time = max(times)
        return (end_time - start_time).total_seconds() / 60.0  # minutes

    def _extract_device_type(self, user_agent: Optional[str]) -> str:
        """Extract device type from user agent"""
        if not user_agent:
            return "unknown"

        user_agent = user_agent.lower()
        if "mobile" in user_agent:
            return "mobile"
        elif "tablet" in user_agent:
            return "tablet"
        elif "desktop" in user_agent:
            return "desktop"
        else:
            return "unknown"

    def _extract_location(self, ip_address: Optional[str]) -> Optional[str]:
        """Extract location from IP address (simplified)"""
        if not ip_address or ip_address == "127.0.0.1":
            return "Local / Test"
        # Placeholder for geo-IP logic
        return "Gulf Region (Detected)"

    def _prepare_price_features(self, features: Dict[str, Any]) -> List[float]:
        """Prepare features for price prediction"""
        # This is a simplified version - in production, use proper feature engineering
        feature_map = {
            "area": 0.0,
            "country_saudi_arabia": 0.0,
            "country_uae": 0.0,
            "country_qatar": 0.0,
            "country_bahrain": 0.0,
            "country_oman": 0.0,
            "country_kuwait": 0.0,
            "is_featured": 0.0,
        }

        # Map features
        if "area" in features:
            feature_map["area"] = float(features["area"])

        if "country" in features:
            country_key = f"country_{features['country']}"
            if country_key in feature_map:
                feature_map[country_key] = 1.0

        if "is_featured" in features:
            feature_map["is_featured"] = float(features["is_featured"])

        return list(feature_map.values())

    def _calculate_prediction_confidence(self, features: List[float]) -> float:
        """Calculate prediction confidence score"""
        # Simplified confidence calculation
        return 0.85  # In production, calculate based on model uncertainty

    def _prepare_training_data(self, df: pd.DataFrame) -> pd.DataFrame:
        """Prepare data for model training"""
        # One-hot encode countries
        countries = ["saudi_arabia", "uae", "qatar", "bahrain", "oman", "kuwait"]
        for country in countries:
            df[f"country_{country}"] = (df["country"] == country).astype(int)

        # Convert boolean columns
        df["is_featured"] = df["is_featured"].astype(int)

        # Select features
        feature_columns = (
            ["area"] + [f"country_{c}" for c in countries] + ["is_featured"]
        )
        df = df[["price"] + feature_columns]

        return df.dropna()

    async def _analyze_price_trends(
        self, country: Optional[str]
    ) -> Optional[MarketInsight]:
        """Analyze price trends"""
        try:
            async with self.db.get_connection() as conn:
                query = """
                    SELECT 
                        AVG(price) as avg_price,
                        EXTRACT(MONTH FROM created_at) as month,
                        EXTRACT(YEAR FROM created_at) as year
                    FROM land_listings
                    WHERE status = 'active'
                """
                params = []

                if country:
                    query += " AND country = $1"
                    params.append(country)

                query += " GROUP BY month, year ORDER BY year, month"

                data = await conn.fetch(query, *params)

                if len(data) < 2:
                    return None

                # Calculate trend
                prices = [row["avg_price"] for row in data]
                current_price = prices[-1]
                previous_price = prices[-2]

                change_percentage = (
                    (current_price - previous_price) / previous_price
                ) * 100
                trend = "increasing" if change_percentage > 0 else "decreasing"

                return MarketInsight(
                    metric="Average Price",
                    value=current_price,
                    change_percentage=change_percentage,
                    trend=trend,
                    confidence=0.85,
                    recommendations=self._generate_price_recommendations(
                        trend, change_percentage
                    ),
                )

        except Exception as e:
            logger.error(f"Failed to analyze price trends: {e}")
            return None

    async def _analyze_demand_trends(
        self, country: Optional[str]
    ) -> Optional[MarketInsight]:
        """Analyze demand trends"""
        try:
            async with self.db.get_connection() as conn:
                query = """
                    SELECT 
                        COUNT(*) as demand_score,
                        DATE_TRUNC('day', created_at) as day
                    FROM analytics_events
                    WHERE event_name = 'listing_viewed'
                """
                params = []

                if country:
                    query += " AND properties->>'country' = $1"
                    params.append(country)

                query += " AND created_at >= NOW() - INTERVAL '30 days' GROUP BY day ORDER BY day"

                data = await conn.fetch(query, *params)

                if len(data) < 7:
                    return None

                # Calculate trend
                demand_scores = [row["demand_score"] for row in data]
                current_demand = demand_scores[-1]
                avg_demand = np.mean(demand_scores[:-1])

                change_percentage = ((current_demand - avg_demand) / avg_demand) * 100
                trend = "increasing" if change_percentage > 0 else "decreasing"

                return MarketInsight(
                    metric="Demand Score",
                    value=current_demand,
                    change_percentage=change_percentage,
                    trend=trend,
                    confidence=0.75,
                    recommendations=self._generate_demand_recommendations(
                        trend, change_percentage
                    ),
                )

        except Exception as e:
            logger.error(f"Failed to analyze demand trends: {e}")
            return None

    async def _analyze_popular_locations(
        self, country: Optional[str]
    ) -> Optional[MarketInsight]:
        """Analyze popular locations"""
        try:
            async with self.db.get_connection() as conn:
                query = """
                    SELECT 
                        location,
                        COUNT(*) as view_count,
                        AVG(price) as avg_price
                    FROM analytics_events ae
                    JOIN land_listings ll ON ae.properties->>'listing_id' = ll.id
                    WHERE ae.event_name = 'listing_viewed'
                """
                params = []

                if country:
                    query += " AND ll.country = $1"
                    params.append(country)

                query += " GROUP BY location ORDER BY view_count DESC LIMIT 1"

                data = await conn.fetch(query, *params)

                if not data:
                    return None

                top_location = data[0]

                return MarketInsight(
                    metric="Top Location",  # Consider making this dynamic based on the actual location
                    value=top_location["view_count"],
                    change_percentage=0.0,
                    trend="stable",
                    confidence=0.90,
                    recommendations=[
                        f"Focus marketing efforts on {top_location['location']}",
                        f"Average price in this area: SAR {top_location['avg_price']:,.0f}",
                    ],
                )

        except Exception as e:
            logger.error(f"Failed to analyze popular locations: {e}")
            return None

    async def _analyze_user_engagement(
        self, country: Optional[str]
    ) -> Optional[MarketInsight]:
        """Analyze user engagement"""
        try:
            async with self.db.get_connection() as conn:
                query = """
                    SELECT 
                        COUNT(DISTINCT user_id) as active_users,
                        COUNT(*) as total_events,
                        AVG(EXTRACT(EPOCH FROM (MAX(created_at) - MIN(created_at))/60)) as avg_session_duration
                    FROM analytics_events
                    WHERE created_at >= NOW() - INTERVAL '7 days'
                """
                params = []

                if country:
                    query += " AND properties->>'country' = $1"
                    params.append(country)

                data = await conn.fetch(query, *params)

                if not data:
                    return None

                engagement_data = data[0]

                return MarketInsight(
                    metric="User Engagement",
                    value=engagement_data["active_users"],
                    change_percentage=0.0,
                    trend="stable",
                    confidence=0.80,
                    recommendations=[
                        f"Average session duration: {engagement_data['avg_session_duration']:.1f} minutes",
                        f"Total events this week: {engagement_data['total_events']}",
                    ],
                )

        except Exception as e:
            logger.error(f"Failed to analyze user engagement: {e}")
            return None

    async def _analyze_trending_listings(
        self, country: Optional[str]
    ) -> Optional[MarketInsight]:
        """Analyze trending listings based on velocity of views in the last 24h."""
        try:
            async with self.db.get_connection() as conn:
                query = """
                    SELECT 
                        ae.properties->>'listing_id' as listing_id,
                        ll.title,
                        COUNT(*) as velocity
                    FROM analytics_events
                    JOIN land_listings ll ON (ae.properties->>'listing_id')::uuid = ll.id
                    WHERE ae.event_name = 'listing_viewed'
                    AND ae.created_at >= NOW() - INTERVAL '24 hours'
                """
                params = []
                if country:
                    query += " AND properties->>'country' = $1"
                    params.append(country)

                query += " GROUP BY listing_id ORDER BY velocity DESC LIMIT 5"

                data = await conn.fetch(query, *params)

                if not data:
                    return None

                total_trending = len(data)
                top_velocity = data[0]["velocity"]

                return MarketInsight(
                    metric="Trending Velocity",
                    value=float(top_velocity),
                    change_percentage=0.0,
                    trend="high_velocity",
                    confidence=0.95,
                    recommendations=[
                        f"Found {total_trending} high-velocity listings in the last 24 hours.",
                        "Promote these items to 'Featured' status to maximize conversion.",
                    ],
                )
        except Exception as e:
            logger.error(f"Failed to analyze trending: {e}")
            return None

    def _generate_price_recommendations(
        self, trend: str, change_percentage: float
    ) -> List[str]:
        """Generate price-related recommendations"""
        recommendations = []

        if trend == "increasing":
            recommendations.append(
                "Market is heating up - consider listing at premium prices"
            )
            recommendations.append("Buyers are active - good time to sell")
        else:
            recommendations.append(
                "Prices are softening - consider competitive pricing"
            )
            recommendations.append("Focus on value proposition to attract buyers")

        return recommendations

    def _generate_demand_recommendations(
        self, trend: str, change_percentage: float
    ) -> List[str]:
        """Generate demand-related recommendations"""
        recommendations = []

        if trend == "increasing":
            recommendations.append("Demand is rising - increase marketing spend")
            recommendations.append("Consider expanding inventory in popular areas")
        else:
            recommendations.append("Demand is declining - focus on retention")
            recommendations.append("Review pricing strategy to stimulate demand")

        return recommendations


# Pydantic models for API
class EventRequest(BaseModel):
    event_name: str
    user_id: Optional[str] = None
    session_id: Optional[str] = None
    properties: Dict[str, Any] = Field(default_factory=dict)
    user_agent: Optional[str] = None
    ip_address: Optional[str] = None


class PricePredictionRequest(BaseModel):
    area: float
    country: str
    location: Optional[str] = None
    is_featured: bool = False


# FastAPI application
app = FastAPI(
    title="Gulf Lands Analytics API",
    description="Advanced analytics and insights for Gulf Lands Market",
    version="1.0.0",
)

# Add middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(GZipMiddleware, minimum_size=1000)

# Global variables
db_manager = None
redis_manager = None
analytics_engine = None


@app.on_event("startup")
async def startup_event():
    global db_manager, redis_manager, analytics_engine

    # Initialize database
    db_manager = DatabaseManager(
        "postgresql://gulflands_user:secure_password_123@localhost/gulflands"
    )
    await db_manager.initialize()

    redis_manager = RedisManager("redis://localhost:6379/0")
    await redis_manager.initialize()

    analytics_engine = AnalyticsEngine(db_manager, redis_manager)
    await analytics_engine.initialize_models()


@app.on_event("shutdown")
async def shutdown_event():
    global db_manager, redis_manager, analytics_engine
    global db_manager, redis_manager
    # Ensure models are saved or resources are released if necessary
    # await analytics_engine.save_models() # Example
    if db_manager:
        await db_manager.close()

    if redis_manager:
        await redis_manager.close()
        if redis_manager.redis:
            await redis_manager.redis.close()
        logger.info("Redis connection closed")

    logger.info("Analytics service stopped")


@app.post("/track")
async def track_event(request: EventRequest):
    """Track analytics event"""
    try:
        event = AnalyticsEvent(
            event_name=request.event_name,
            user_id=request.user_id,
            session_id=request.session_id,
            properties=request.properties,
            timestamp=datetime.utcnow(),
            user_agent=request.user_agent,
            ip_address=request.ip_address,
        )

        await analytics_engine.track_event(event)

        return {"status": "success", "message": "Event tracked successfully"}

    except Exception as e:
        logger.error(f"Failed to track event: {e}")
        raise HTTPException(status_code=500, detail="Failed to track event")


@app.get("/user/{user_id}/behavior")
async def get_user_behavior(user_id: str, days: int = 30):
    """Get user behavior analysis"""
    try:
        behavior = await analytics_engine.get_user_behavior(user_id, days)
        return asdict(behavior)

    except Exception as e:
        logger.error(f"Failed to get user behavior: {e}")
        raise HTTPException(status_code=500, detail="Failed to get user behavior")


@app.get("/insights")
async def get_market_insights(country: Optional[str] = None):
    """Get market insights"""
    try:
        insights = await analytics_engine.get_market_insights(country)
        return [asdict(insight) for insight in insights]

    except Exception as e:
        logger.error(f"Failed to get market insights: {e}")
        raise HTTPException(status_code=500, detail="Failed to get market insights")


@app.post("/predict-price")
async def predict_price(request: PricePredictionRequest):
    """Predict property price"""
    try:
        features = {
            "area": request.area,
            "country": request.country,
            "location": request.location,
            "is_featured": request.is_featured,
        }

        prediction = await analytics_engine.predict_price(features)
        return prediction

    except Exception as e:
        logger.error(f"Failed to predict price: {e}")
        raise HTTPException(status_code=500, detail="Failed to predict price")


@app.get("/realtime")
async def get_real_time_metrics():
    """Get real-time metrics"""
    try:
        metrics = await analytics_engine.get_real_time_metrics()
        return metrics

    except Exception as e:
        logger.error(f"Failed to get real-time metrics: {e}")
        raise HTTPException(status_code=500, detail="Failed to get real-time metrics")


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}


if __name__ == "__main__":
    # Ensure uvicorn is installed: pip install uvicorn[standard]
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True, log_level="info")
