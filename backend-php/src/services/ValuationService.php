<?php

namespace App\Services;

class ValuationService
{
    private static array $baseRates = [
        "saudiArabia" => 1200.0,
        "uae" => 2500.0,
        "qatar" => 2200.0,
        "kuwait" => 180.0,
        "bahrain" => 280.0,
        "oman" => 90.0
    ];

    private static float $areaExponent = 0.88;
    private static float $coastalDecay = 0.05;

    private static array $zoningMultipliers = [
        "commercial" => 1.45,
        "mixed-use" => 1.30,
        "residential" => 1.00,
        "tourism" => 1.25,
        "industrial" => 0.85,
        "agricultural" => 0.50
    ];

    private static array $regionalMultipliers = [
        "Riyadh" => 1.25,
        "Jeddah" => 1.10,
        "NEOM Zone" => 1.50,
        "Dubai" => 1.40,
        "Abu Dhabi" => 1.30,
        "Doha" => 1.20,
        "Manama" => 1.05,
        "Muscat" => 1.00
    ];

    public static function calculateValuation(
        string $country,
        float $areaSqm,
        float $coastalDistanceKm,
        string $zoning,
        string $city = "default"
    ): float {
        $baseRate = self::$baseRates[$country] ?? 1000.0;
        
        $areaFactor = pow($areaSqm, self::$areaExponent);
        
        $coastalFactor = exp(-self::$coastalDecay * max(0.0, $coastalDistanceKm));
        
        $zoningFactor = self::$zoningMultipliers[strtolower($zoning)] ?? 1.00;
        
        $regionalFactor = self::$regionalMultipliers[$city] ?? 1.00;

        $rawVal = $baseRate * $areaFactor * $coastalFactor * $zoningFactor * $regionalFactor;
        
        return round($rawVal, 2);
    }
}
