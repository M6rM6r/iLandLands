import math
from typing import Dict, Any

class LandValuationEngine:
    # Base rates per square meter (normalized approximately to local currency standards)
    BASE_RATES: Dict[str, float] = {
        "saudiArabia": 1200.0,
        "uae": 2500.0,
        "qatar": 2200.0,
        "kuwait": 180.0,
        "bahrain": 280.0,
        "oman": 90.0
    }

    # Area scaling power exponent (diminishing return on per-sqm price for larger plots)
    AREA_EXPONENT: float = 0.88

    # Coastal proximity decay constant (lambda)
    COASTAL_DECAY: float = 0.05

    # Zoning premium multipliers
    ZONING_MULTIPLIERS: Dict[str, float] = {
        "commercial": 1.45,
        "mixed-use": 1.30,
        "residential": 1.00,
        "tourism": 1.25,
        "industrial": 0.85,
        "agricultural": 0.50
    }

    # Regional demand multipliers
    REGIONAL_MULTIPLIERS: Dict[str, float] = {
        "Riyadh": 1.25,
        "Jeddah": 1.10,
        "NEOM Zone": 1.50,
        "Dubai": 1.40,
        "Abu Dhabi": 1.30,
        "Doha": 1.20,
        "Manama": 1.05,
        "Muscat": 1.00
    }

    @classmethod
    def calculate_valuation(
        cls,
        country: str,
        area_sqm: float,
        coastal_distance_km: float,
        zoning: str,
        city: str = "default"
    ) -> float:
        """
        Calculates mathematical land valuation using:
        V = P_base * (Area^alpha) * e^(-lambda * d) * Z_z * C_r
        """
        # Get base rate
        base_rate = cls.BASE_RATES.get(country, 1000.0)
        
        # Area factor
        area_factor = math.pow(area_sqm, cls.AREA_EXPONENT)
        
        # Coastal decay factor
        coastal_factor = math.exp(-cls.COASTAL_DECAY * max(0.0, coastal_distance_km))
        
        # Zoning factor
        zoning_factor = cls.ZONING_MULTIPLIERS.get(zoning.lower(), 1.00)
        
        # Regional factor
        regional_factor = cls.REGIONAL_MULTIPLIERS.get(city, 1.00)

        # Computation
        raw_val = base_rate * area_factor * coastal_factor * zoning_factor * regional_factor
        return round(raw_val, 2)
