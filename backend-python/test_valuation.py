import unittest
from valuation_engine import LandValuationEngine

class TestLandValuationEngine(unittest.TestCase):
    def test_basic_valuation(self):
        # saudiArabia base rate = 1200, area = 1000, coastal = 0, zoning = residential (1.00), city = default (1.00)
        # expected = 1200 * (1000 ^ 0.88) * e^0 * 1.0 * 1.0
        # 1000 ^ 0.88 is roughly 436.5158
        # expected is roughly 1200 * 436.5158 = 523819
        val = LandValuationEngine.calculate_valuation(
            country="saudiArabia",
            area_sqm=1000.0,
            coastal_distance_km=0.0,
            zoning="residential"
        )
        self.assertAlmostEqual(val, 523818.99, places=1)

    def test_coastal_decay(self):
        # Proximity decay should reduce valuation
        val_shore = LandValuationEngine.calculate_valuation(
            country="uae", area_sqm=500.0, coastal_distance_km=0.0, zoning="commercial"
        )
        val_inland = LandValuationEngine.calculate_valuation(
            country="uae", area_sqm=500.0, coastal_distance_km=10.0, zoning="commercial"
        )
        self.assertTrue(val_inland < val_shore)

    def test_zoning_multipliers(self):
        # Agricultural should be less than commercial
        val_comm = LandValuationEngine.calculate_valuation(
            country="qatar", area_sqm=800.0, coastal_distance_km=2.0, zoning="commercial"
        )
        val_agri = LandValuationEngine.calculate_valuation(
            country="qatar", area_sqm=800.0, coastal_distance_km=2.0, zoning="agricultural"
        )
        self.assertTrue(val_agri < val_comm)

if __name__ == "__main__":
    unittest.main()
