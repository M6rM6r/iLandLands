# Gulf region land listings — seed data for recommendation engine.
# Prices are in the local currency of each country:
#   Saudi Arabia → SAR  |  UAE → AED  |  Qatar → QAR
#   Kuwait → KWD        |  Bahrain → BHD  |  Oman → OMR
listings = [
    # ── Saudi Arabia ──────────────────────────────────────────
    {
        "id": "gl-sa-001", "title": "Riyadh North Residential Plot",
        "price": 1_850_000, "currency": "SAR", "area_sqm": 600,
        "country": "saudiArabia", "city": "Riyadh", "district": "Al Yasmin",
        "type": "residential", "zoning": "residential",
        "latitude": 24.7939, "longitude": 46.6753,
    },
    {
        "id": "gl-sa-002", "title": "Jeddah Corniche Commercial Land",
        "price": 4_200_000, "currency": "SAR", "area_sqm": 1200,
        "country": "saudiArabia", "city": "Jeddah", "district": "Al Balad",
        "type": "commercial", "zoning": "commercial",
        "latitude": 21.4858, "longitude": 39.1925,
    },
    {
        "id": "gl-sa-003", "title": "NEOM Tabuk Region Agricultural Plot",
        "price": 950_000, "currency": "SAR", "area_sqm": 5000,
        "country": "saudiArabia", "city": "Tabuk", "district": "NEOM Zone",
        "type": "agricultural", "zoning": "agricultural",
        "latitude": 28.3835, "longitude": 36.5662,
    },
    {
        "id": "gl-sa-004", "title": "Dammam Industrial Plot near King Fahd Port",
        "price": 2_700_000, "currency": "SAR", "area_sqm": 2500,
        "country": "saudiArabia", "city": "Dammam", "district": "Al Hamriyah",
        "type": "industrial", "zoning": "industrial",
        "latitude": 26.4207, "longitude": 50.0888,
    },
    {
        "id": "gl-sa-005", "title": "AlUla Heritage Zone Tourist Land",
        "price": 3_100_000, "currency": "SAR", "area_sqm": 800,
        "country": "saudiArabia", "city": "AlUla", "district": "Old Town",
        "type": "mixed", "zoning": "tourism",
        "latitude": 26.6178, "longitude": 37.9219,
    },
    # ── UAE ───────────────────────────────────────────────────
    {
        "id": "gl-ae-001", "title": "Dubai Marina Waterfront Plot",
        "price": 8_500_000, "currency": "AED", "area_sqm": 900,
        "country": "uae", "city": "Dubai", "district": "Dubai Marina",
        "type": "residential", "zoning": "mixed-use",
        "latitude": 25.0802, "longitude": 55.1402,
    },
    {
        "id": "gl-ae-002", "title": "Abu Dhabi Saadiyat Island Plot",
        "price": 6_200_000, "currency": "AED", "area_sqm": 700,
        "country": "uae", "city": "Abu Dhabi", "district": "Saadiyat Island",
        "type": "residential", "zoning": "residential",
        "latitude": 24.5426, "longitude": 54.4344,
    },
    {
        "id": "gl-ae-003", "title": "Sharjah Industrial Investment Zone",
        "price": 2_800_000, "currency": "AED", "area_sqm": 3000,
        "country": "uae", "city": "Sharjah", "district": "Hamriyah Free Zone",
        "type": "industrial", "zoning": "industrial",
        "latitude": 25.4052, "longitude": 55.5136,
    },
    {
        "id": "gl-ae-004", "title": "Ras Al Khaimah Mountain View Land",
        "price": 1_100_000, "currency": "AED", "area_sqm": 1500,
        "country": "uae", "city": "Ras Al Khaimah", "district": "Al Hamra",
        "type": "residential", "zoning": "residential",
        "latitude": 25.6742, "longitude": 55.9804,
    },
    {
        "id": "gl-ae-005", "title": "Ajman Commercial Corridor Plot",
        "price": 1_750_000, "currency": "AED", "area_sqm": 400,
        "country": "uae", "city": "Ajman", "district": "Al Jurf",
        "type": "commercial", "zoning": "commercial",
        "latitude": 25.4102, "longitude": 55.4354,
    },
    # ── Qatar ─────────────────────────────────────────────────
    {
        "id": "gl-qa-001", "title": "Lusail City Residential Plot",
        "price": 3_400_000, "currency": "QAR", "area_sqm": 500,
        "country": "qatar", "city": "Lusail", "district": "Fox Hills",
        "type": "residential", "zoning": "residential",
        "latitude": 25.4289, "longitude": 51.4901,
    },
    {
        "id": "gl-qa-002", "title": "West Bay Diplomatic Zone Commercial Land",
        "price": 7_800_000, "currency": "QAR", "area_sqm": 1100,
        "country": "qatar", "city": "Doha", "district": "West Bay",
        "type": "commercial", "zoning": "commercial",
        "latitude": 25.3200, "longitude": 51.5332,
    },
    {
        "id": "gl-qa-003", "title": "Al Wakrah Sea View Plot",
        "price": 2_100_000, "currency": "QAR", "area_sqm": 650,
        "country": "qatar", "city": "Al Wakrah", "district": "Al Wukair",
        "type": "residential", "zoning": "residential",
        "latitude": 25.1664, "longitude": 51.5966,
    },
    # ── Kuwait ────────────────────────────────────────────────
    {
        "id": "gl-kw-001", "title": "Kuwait City Mixed-Use Plot",
        "price": 450_000, "currency": "KWD", "area_sqm": 750,
        "country": "kuwait", "city": "Kuwait City", "district": "Salmiya",
        "type": "mixed", "zoning": "mixed-use",
        "latitude": 29.3375, "longitude": 48.0758,
    },
    {
        "id": "gl-kw-002", "title": "Jahra Agricultural Investment Land",
        "price": 180_000, "currency": "KWD", "area_sqm": 4000,
        "country": "kuwait", "city": "Jahra", "district": "Al Jahra",
        "type": "agricultural", "zoning": "agricultural",
        "latitude": 29.3375, "longitude": 47.6581,
    },
    # ── Bahrain ───────────────────────────────────────────────
    {
        "id": "gl-bh-001", "title": "Bahrain Bay Waterfront Plot",
        "price": 320_000, "currency": "BHD", "area_sqm": 400,
        "country": "bahrain", "city": "Manama", "district": "Bahrain Bay",
        "type": "residential", "zoning": "mixed-use",
        "latitude": 26.2285, "longitude": 50.5860,
    },
    {
        "id": "gl-bh-002", "title": "Riffa Residential Land",
        "price": 95_000, "currency": "BHD", "area_sqm": 350,
        "country": "bahrain", "city": "Riffa", "district": "East Riffa",
        "type": "residential", "zoning": "residential",
        "latitude": 26.1299, "longitude": 50.5551,
    },
    # ── Oman ──────────────────────────────────────────────────
    {
        "id": "gl-om-001", "title": "Muscat Hills Residential Plot",
        "price": 120_000, "currency": "OMR", "area_sqm": 600,
        "country": "oman", "city": "Muscat", "district": "Al Khuwair",
        "type": "residential", "zoning": "residential",
        "latitude": 23.5880, "longitude": 58.3829,
    },
    {
        "id": "gl-om-002", "title": "Sohar Industrial Free Zone Land",
        "price": 75_000, "currency": "OMR", "area_sqm": 2000,
        "country": "oman", "city": "Sohar", "district": "Sohar Free Zone",
        "type": "industrial", "zoning": "industrial",
        "latitude": 24.3473, "longitude": 56.7452,
    },
    {
        "id": "gl-om-003", "title": "Salalah Tourism District Coastal Plot",
        "price": 85_000, "currency": "OMR", "area_sqm": 900,
        "country": "oman", "city": "Salalah", "district": "Al Hafah",
        "type": "mixed", "zoning": "tourism",
        "latitude": 17.0151, "longitude": 54.0924,
    },
]
