import os
from fastapi import FastAPI, HTTPException, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from pydantic import BaseModel, Field, validator
from typing import List, Optional
from datetime import datetime
from enum import Enum
import json
import re
from contracts import LandPlotContract, Country
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from valuation_engine import LandValuationEngine

app = FastAPI(title="Gulf Lands API", version="1.0.0")

# Rate limiting
limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)

# Security Middleware
_cors_origins = os.getenv(
    "CORS_ORIGINS",
    "https://gulflands.com,https://www.gulflands.com,http://localhost:*",
).split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in _cors_origins if o.strip()],
    allow_origin_regex=r"http://localhost(:\d+)?",
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=[h.strip() for h in os.getenv(
        "ALLOWED_HOSTS",
        "gulflands-api.com,*.gulflands-api.com,localhost,127.0.0.1",
    ).split(",")],
)

# Security headers middleware
@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    response.headers["Content-Security-Policy"] = "default-src 'self'"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    return response

# Mock data
sample_plots = [
    LandPlotContract(
        id="1",
        title="Prime Coastal Land in Jeddah",
        description="A stunning piece of land with direct access to the Red Sea. Perfect for a luxury villa or a private resort.",
        price=5000000,
        area=10000,
        country=Country.saudiArabia,
        location="Jeddah, Obhur",
        imageUrls=["https://via.placeholder.com/400x300.png/009688/FFFFFF?Text=Jeddah+Land+1"],
        createdAt=datetime(2023, 1, 1),
    ),
    LandPlotContract(
        id="2",
        title="Exclusive Plot in Dubai Hills Estate",
        description="Located in one of the most prestigious communities in Dubai, offering stunning views of the golf course.",
        price=12000000,
        area=15000,
        country=Country.uae,
        location="Dubai, Dubai Hills Estate",
        imageUrls=["https://via.placeholder.com/400x300.png/FFC107/000000?Text=Dubai+Land+1"],
        createdAt=datetime(2023, 1, 2),
    ),
    LandPlotContract(
        id="3",
        title="Sea View Land in The Pearl, Qatar",
        description="An exceptional opportunity to build your dream home in one of the most sought-after locations in Doha.",
        price=9500000,
        area=8000,
        country=Country.qatar,
        location="Doha, The Pearl-Qatar",
        imageUrls=["https://via.placeholder.com/400x300.png/795548/FFFFFF?Text=Qatar+Land+1"],
        createdAt=datetime(2023, 1, 3),
    ),
    LandPlotContract(
        id="4",
        title="Large Agricultural Land in Al-Ahsa",
        description="A vast expanse of fertile land, perfect for agricultural projects. Comes with water access.",
        price=2500000,
        area=50000,
        country=Country.saudiArabia,
        location="Al-Ahsa",
        imageUrls=["https://via.placeholder.com/400x300.png/4CAF50/FFFFFF?Text=Al-Ahsa+Land+1"],
        createdAt=datetime(2023, 1, 4),
    ),
]

@app.get("/health", summary="Health probe (Docker/K8s)")
async def health():
    return {"status": "healthy"}

@app.get("/health/live", summary="Liveness probe")
async def liveness():
    return {"status": "alive"}

@app.get("/health/ready", summary="Readiness probe")
async def readiness():
    return {"status": "ready"}

@app.get("/v1/listings", response_model=List[LandPlotContract], summary="Get land listings")
async def get_listings(
    country: Optional[Country] = Query(None, description="Filter by country"),
    min_price: Optional[float] = Query(None, ge=0, description="Minimum price"),
    max_price: Optional[float] = Query(None, ge=0, description="Maximum price"),
    min_area: Optional[float] = Query(None, ge=0, description="Minimum area"),
    max_area: Optional[float] = Query(None, ge=0, description="Maximum area"),
    sort_by: Optional[str] = Query("createdAt", description="Sort by field"),
    sort_order: Optional[str] = Query("desc", description="Sort order: asc or desc"),
    limit: int = Query(50, le=100, description="Limit results"),
    offset: int = Query(0, ge=0, description="Offset for pagination"),
):
    filtered = sample_plots.copy()
    
    if country:
        filtered = [p for p in filtered if p.country == country]
    
    if min_price is not None:
        filtered = [p for p in filtered if p.price >= min_price]
    
    if max_price is not None:
        filtered = [p for p in filtered if p.price <= max_price]
    
    if min_area is not None:
        filtered = [p for p in filtered if p.area >= min_area]
    
    if max_area is not None:
        filtered = [p for p in filtered if p.area <= max_area]
    
    # Sorting
    reverse = sort_order == "desc"
    if sort_by == "price":
        filtered.sort(key=lambda x: x.price, reverse=reverse)
    elif sort_by == "area":
        filtered.sort(key=lambda x: x.area, reverse=reverse)
    elif sort_by == "createdAt":
        filtered.sort(key=lambda x: x.createdAt, reverse=reverse)
    
    # Pagination
    paginated = filtered[offset:offset + limit]
    
    return paginated

@app.get("/v1/listings/{listing_id}", response_model=LandPlotContract, summary="Get specific listing")
async def get_listing(listing_id: str):
    for plot in sample_plots:
        if plot.id == listing_id:
            return plot
    raise HTTPException(status_code=404, detail="Listing not found")

@app.post("/v1/analytics/events", summary="Track analytics events")
@limiter.limit("10/minute")
async def track_event(request: Request, event: dict):
    # Handle both single event and batched events
    if 'events' in event:
        # Batched events
        events = event['events']
        for e in events:
            # Validate each event
            required_fields = ["event", "properties"]
            if not all(field in e for field in required_fields):
                raise HTTPException(status_code=400, detail="Missing required fields in batched event")

            # Validate event name (alphanumeric, underscore, dash only)
            if not re.match(r'^[a-zA-Z0-9_-]+$', e.get("event", "")):
                raise HTTPException(status_code=400, detail="Invalid event name in batched event")

            # Limit properties size
            if len(json.dumps(e.get("properties", {}))) > 10000:  # 10KB limit
                raise HTTPException(status_code=400, detail="Event properties too large in batched event")

            print(f"Event tracked: {e}")
    else:
        # Single event (backward compatibility)
        required_fields = ["event", "properties"]
        if not all(field in event for field in required_fields):
            raise HTTPException(status_code=400, detail="Missing required fields")

        # Validate event name (alphanumeric, underscore, dash only)
        if not re.match(r'^[a-zA-Z0-9_-]+$', event.get("event", "")):
            raise HTTPException(status_code=400, detail="Invalid event name")

        # Limit properties size
        if len(json.dumps(event.get("properties", {}))) > 10000:  # 10KB limit
            raise HTTPException(status_code=400, detail="Event properties too large")

        print(f"Event tracked: {event}")
    return {"status": "ok"}

class ValuationRequest(BaseModel):
    country: str
    area_sqm: float = Field(..., ge=0)
    coastal_distance_km: float = Field(..., ge=0)
    zoning: str
    city: Optional[str] = "default"

@app.post("/v1/valuation/estimate", summary="Perform mathematical estimation of land plot value")
@limiter.limit("30/minute")
async def estimate_valuation(request: Request, body: ValuationRequest):
    try:
        val = LandValuationEngine.calculate_valuation(
            country=body.country,
            area_sqm=body.area_sqm,
            coastal_distance_km=body.coastal_distance_km,
            zoning=body.zoning,
            city=body.city
        )
        return {
            "estimated_value": val,
            "currency": "SAR" if body.country == "saudiArabia" else ("AED" if body.country == "uae" else "USD"),
            "formula": "V = P_base * Area^alpha * e^(-lambda * d) * Z_z * C_r"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))