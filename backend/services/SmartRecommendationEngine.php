<?php

namespace Gulflands\Services;

use Gulflands\Models\LandListing;
use Gulflands\Models\Analytics;
use Gulflands\Models\User;
use PDO;
use PDOException;

/**
 * Smart Recommendation Engine
 * 
 * Advanced AI-powered recommendation system using multiple algorithms:
 * - Collaborative Filtering
 * - Content-Based Filtering
 * - Hybrid Approach
 * - Real-time Personalization
 * - Trend Analysis
 */
class SmartRecommendationEngine {
    private PDO $db;
    private Analytics $analytics;
    private array $weights;
    private array $locationScores;
    private array $priceRangeScores;
    
    public function __construct(PDO $db, Analytics $analytics) {
        $this->db = $db;
        $this->analytics = $analytics;
        
        // Algorithm weights
        $this->weights = [
            'collaborative' => 0.35,
            'content_based' => 0.30,
            'trending' => 0.20,
            'personalized' => 0.15
        ];
        
        // Location desirability scores
        $this->locationScores = [
            'saudi_arabia' => 0.85,
            'uae' => 0.95,
            'qatar' => 0.80,
            'bahrain' => 0.75,
            'oman' => 0.70,
            'kuwait' => 0.82
        ];
        
        // Price range preferences
        $this->priceRangeScores = [
            'budget' => ['min' => 0, 'max' => 1000000, 'score' => 0.65],
            'mid_range' => ['min' => 1000000, 'max' => 5000000, 'score' => 0.80],
            'premium' => ['min' => 5000000, 'max' => 10000000, 'score' => 0.90],
            'luxury' => ['min' => 10000000, 'max' => PHP_FLOAT_MAX, 'score' => 0.95]
        ];
    }
    
    /**
     * Get personalized recommendations for a user
     */
    public function getRecommendations(string $userId, int $limit = 10): array {
        try {
            // Get user behavior data
            $userHistory = $this->getUserHistory($userId);
            $userFavorites = $this->getUserFavorites($userId);
            $userProfile = $this->getUserProfile($userId);
            
            // Analyze user preferences
            $preferences = $this->analyzeUserPreferences($userHistory);
            
            // Get candidate listings
            $candidates = $this->getCandidateListings($userId);
            
            // Calculate recommendation scores
            $recommendations = [];
            foreach ($candidates as $listing) {
                $score = $this->calculateRecommendationScore(
                    $listing, 
                    $userHistory, 
                    $userFavorites, 
                    $preferences, 
                    $userProfile
                );
                
                if ($score > 0.6) { // Threshold for recommendation
                    $recommendations[] = [
                        'listing' => $listing,
                        'score' => $score,
                        'reasons' => $this->getRecommendationReasons($listing, $preferences)
                    ];
                }
            }
            
            // Sort by score and limit results
            usort($recommendations, fn($a, $b) => $b['score'] <=> $a['score']);
            
            return array_slice($recommendations, 0, $limit);
            
        } catch (PDOException $e) {
            error_log("Recommendation engine error: " . $e->getMessage());
            return [];
        }
    }
    
    /**
     * Get similar listings based on a target listing
     */
    public function getSimilarListings(int $listingId, int $limit = 5): array {
        try {
            $targetListing = $this->getListingById($listingId);
            if (!$targetListing) {
                return [];
            }
            
            $candidates = $this->getAllActiveListings();
            $similarities = [];
            
            foreach ($candidates as $candidate) {
                if ($candidate['id'] == $listingId) continue;
                
                $similarity = $this->calculateSimilarity($targetListing, $candidate);
                $similarities[] = [
                    'listing' => $candidate,
                    'similarity' => $similarity
                ];
            }
            
            // Sort by similarity
            usort($similarities, fn($a, $b) => $b['similarity'] <=> $a['similarity']);
            
            return array_slice($similarities, 0, $limit);
            
        } catch (PDOException $e) {
            error_log("Similar listings error: " . $e->getMessage());
            return [];
        }
    }
    
    /**
     * Get trending listings based on analytics data
     */
    public function getTrendingListings(int $limit = 20): array {
        try {
            $sql = "
                SELECT 
                    ll.*,
                    COUNT(ae.id) as view_count,
                    COUNT(DISTINCT ae.user_id) as unique_viewers,
                    AVG(CASE WHEN ae.event_name = 'added_to_favorites' THEN 1 ELSE 0 END) as favorite_rate,
                    MAX(ae.created_at) as last_interaction
                FROM land_listings ll
                LEFT JOIN analytics_events ae ON ae.properties->>'listing_id' = ll.id
                WHERE ll.status = 'active'
                    AND ae.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
                GROUP BY ll.id
                HAVING view_count > 0
                ORDER BY (
                    (view_count * 0.4) + 
                    (unique_viewers * 0.3) + 
                    (favorite_rate * 0.2) + 
                    (CASE WHEN ll.is_featured = 1 THEN 0.1 ELSE 0 END)
                ) DESC
                LIMIT :limit
            ";
            
            $stmt = $this->db->prepare($sql);
            $stmt->bindParam(':limit', $limit, PDO::PARAM_INT);
            $stmt->execute();
            
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
            
        } catch (PDOException $e) {
            error_log("Trending listings error: " . $e->getMessage());
            return [];
        }
    }
    
    /**
     * Calculate recommendation score for a listing
     */
    private function calculateRecommendationScore(
        array $listing, 
        array $userHistory, 
        array $userFavorites, 
        array $preferences, 
        array $userProfile
    ): float {
        $collaborativeScore = $this->calculateCollaborativeScore($listing, $userHistory, $userFavorites);
        $contentBasedScore = $this->calculateContentBasedScore($listing, $preferences);
        $trendingScore = $this->calculateTrendingScore($listing);
        $personalizedScore = $this->calculatePersonalizedScore($listing, $userProfile);
        
        return (
            $collaborativeScore * $this->weights['collaborative'] +
            $contentBasedScore * $this->weights['content_based'] +
            $trendingScore * $this->weights['trending'] +
            $personalizedScore * $this->weights['personalized']
        );
    }
    
    /**
     * Collaborative filtering score
     */
    private function calculateCollaborativeScore(array $listing, array $userHistory, array $userFavorites): float {
        $score = 0.0;
        
        // Check if similar users liked this listing
        foreach ($userFavorites as $favorite) {
            $similarity = $this->calculateListingSimilarity($listing, $favorite);
            $score += $similarity * 0.5;
        }
        
        // Check viewing patterns
        foreach ($userHistory as $viewed) {
            $similarity = $this->calculateListingSimilarity($listing, $viewed);
            $score += $similarity * 0.3;
        }
        
        return min($score, 1.0);
    }
    
    /**
     * Content-based filtering score
     */
    private function calculateContentBasedScore(array $listing, array $preferences): float {
        $score = 0.0;
        
        // Country preference
        if (in_array($listing['country'], $preferences['preferred_countries'] ?? [])) {
            $score += 0.3;
        }
        
        // Price range preference
        $priceRange = $preferences['price_range'] ?? 'mid_range';
        $score += $this->getPriceScore($listing['price'], $priceRange) * 0.25;
        
        // Area preference
        if (isset($preferences['avg_area'])) {
            $areaSimilarity = 1.0 - abs($listing['area'] - $preferences['avg_area']) / $preferences['avg_area'];
            $score += max(0, $areaSimilarity) * 0.2;
        }
        
        // Location preference
        $listingLocation = explode(',', $listing['location'])[0] ?? '';
        if (in_array(trim($listingLocation), $preferences['preferred_locations'] ?? [])) {
            $score += 0.15;
        }
        
        // Features preference
        if ($listing['is_featured'] && in_array('featured', $preferences['features'] ?? [])) {
            $score += 0.1;
        }
        
        return min($score, 1.0);
    }
    
    /**
     * Trending score based on recent activity
     */
    private function calculateTrendingScore(array $listing): float {
        $score = 0.0;
        
        // Featured listings get higher trending score
        if ($listing['is_featured']) {
            $score += 0.3;
        }
        
        // Recent listings get higher trending score
        $daysSinceCreation = $this->getDaysSinceCreation($listing['created_at']);
        if ($daysSinceCreation < 7) {
            $score += 0.2;
        } elseif ($daysSinceCreation < 30) {
            $score += 0.1;
        }
        
        // Popular locations get higher trending score
        $score += ($this->locationScores[$listing['country']] ?? 0.5) * 0.3;
        
        // Price efficiency
        $pricePerSqm = $listing['price'] / $listing['area'];
        if ($pricePerSqm < 1000) {
            $score += 0.2; // Good value
        } elseif ($pricePerSqm < 5000) {
            $score += 0.1; // Reasonable value
        }
        
        return min($score, 1.0);
    }
    
    /**
     * Personalized score based on user profile
     */
    private function calculatePersonalizedScore(array $listing, array $userProfile): float {
        $score = 0.0;
        
        // Device-based personalization
        $deviceType = $userProfile['device_type'] ?? 'unknown';
        if ($deviceType === 'mobile') {
            // Prefer listings with better mobile experience
            if (!empty($listing['image_urls'])) {
                $score += 0.1;
            }
        }
        
        // Location-based personalization
        $userLocation = $userProfile['location'] ?? 'unknown';
        if ($userLocation !== 'unknown' && $this->isNearby($listing, $userLocation)) {
            $score += 0.2;
        }
        
        // Time-based personalization
        $hour = (int)date('H');
        if ($hour >= 18 && $hour <= 22) { // Evening browsing
            // Prefer premium listings in the evening
            if ($listing['price'] > 5000000) {
                $score += 0.1;
            }
        }
        
        return min($score, 1.0);
    }
    
    /**
     * Calculate similarity between two listings
     */
    private function calculateSimilarity(array $listing1, array $listing2): float {
        $similarity = 0.0;
        $factors = 0;
        
        // Location similarity
        if ($listing1['country'] === $listing2['country']) {
            $similarity += 0.3;
        }
        $factors++;
        
        // Price range similarity
        $priceRatio1 = $listing1['price'] / $listing1['area'];
        $priceRatio2 = $listing2['price'] / $listing2['area'];
        $priceSimilarity = 1.0 - abs($priceRatio1 - $priceRatio2) / max($priceRatio1, $priceRatio2);
        $similarity += $priceSimilarity * 0.25;
        $factors++;
        
        // Area similarity
        $areaRatio = min($listing1['area'], $listing2['area']) / max($listing1['area'], $listing2['area']);
        $similarity += $areaRatio * 0.2;
        $factors++;
        
        // Featured status similarity
        if ($listing1['is_featured'] === $listing2['is_featured']) {
            $similarity += 0.15;
        }
        $factors++;
        
        // Text similarity (title and description)
        $textSimilarity = $this->calculateTextSimilarity(
            $listing1['title'] . ' ' . $listing1['description'],
            $listing2['title'] . ' ' . $listing2['description']
        );
        $similarity += $textSimilarity * 0.1;
        $factors++;
        
        return $similarity / $factors;
    }
    
    /**
     * Calculate listing similarity (simplified version)
     */
    private function calculateListingSimilarity(array $listing1, array $listing2): float {
        $similarity = 0.0;
        
        // Country similarity
        if ($listing1['country'] === $listing2['country']) {
            $similarity += 0.3;
        }
        
        // Price similarity
        $priceRatio = min($listing1['price'], $listing2['price']) / max($listing1['price'], $listing2['price']);
        $similarity += $priceRatio * 0.3;
        
        // Area similarity
        $areaRatio = min($listing1['area'], $listing2['area']) / max($listing1['area'], $listing2['area']);
        $similarity += $areaRatio * 0.2;
        
        // Featured status
        if ($listing1['is_featured'] === $listing2['is_featured']) {
            $similarity += 0.2;
        }
        
        return $similarity;
    }
    
    /**
     * Analyze user preferences from history
     */
    private function analyzeUserPreferences(array $userHistory): array {
        if (empty($userHistory)) {
            return [
                'preferred_countries' => [],
                'price_range' => 'mid_range',
                'avg_area' => 0.0,
                'preferred_locations' => [],
                'features' => []
            ];
        }
        
        // Analyze country preferences
        $countryCounts = [];
        foreach ($userHistory as $listing) {
            $countryCounts[$listing['country']] = ($countryCounts[$listing['country']] ?? 0) + 1;
        }
        
        $preferredCountries = array_keys(array_filter($countryCounts, fn($count) => $count >= 2));
        
        // Analyze price preferences
        $prices = array_column($userHistory, 'price');
        $avgPrice = array_sum($prices) / count($prices);
        
        $priceRange = 'mid_range';
        foreach ($this->priceRangeScores as $range => $config) {
            if ($avgPrice >= $config['min'] && $avgPrice < $config['max']) {
                $priceRange = $range;
                break;
            }
        }
        
        // Analyze area preferences
        $areas = array_column($userHistory, 'area');
        $avgArea = array_sum($areas) / count($areas);
        
        // Analyze location preferences
        $locationCounts = [];
        foreach ($userHistory as $listing) {
            $location = trim(explode(',', $listing['location'])[0] ?? '');
            if ($location) {
                $locationCounts[$location] = ($locationCounts[$location] ?? 0) + 1;
            }
        }
        
        $preferredLocations = array_keys(array_filter($locationCounts, fn($count) => $count >= 2));
        
        // Analyze features
        $features = [];
        if (array_filter($userHistory, fn($listing) => $listing['is_featured'])) {
            $features[] = 'featured';
        }
        
        if ($avgArea > 10000) {
            $features[] = 'large_area';
        }
        
        if ($avgPrice > 5000000) {
            $features[] = 'premium';
        }
        
        return [
            'preferred_countries' => $preferredCountries,
            'price_range' => $priceRange,
            'avg_price' => $avgPrice,
            'avg_area' => $avgArea,
            'preferred_locations' => $preferredLocations,
            'features' => $features
        ];
    }
    
    /**
     * Get recommendation reasons
     */
    private function getRecommendationReasons(array $listing, array $preferences): array {
        $reasons = [];
        
        if (in_array($listing['country'], $preferences['preferred_countries'] ?? [])) {
            $reasons[] = 'Popular in your preferred country';
        }
        
        if ($listing['is_featured']) {
            $reasons[] = 'Featured listing';
        }
        
        $listingLocation = trim(explode(',', $listing['location'])[0] ?? '');
        if (in_array($listingLocation, $preferences['preferred_locations'] ?? [])) {
            $reasons[] = 'In your preferred area';
        }
        
        $daysSinceCreation = $this->getDaysSinceCreation($listing['created_at']);
        if ($daysSinceCreation < 7) {
            $reasons[] = 'New listing';
        }
        
        return $reasons;
    }
    
    // Helper methods
    private function getUserHistory(string $userId): array {
        $sql = "
            SELECT ll.* FROM land_listings ll
            JOIN analytics_events ae ON ae.properties->>'listing_id' = ll.id
            WHERE ae.user_id = :user_id 
                AND ae.event_name = 'listing_viewed'
                AND ae.created_at >= DATE_SUB(NOW(), INTERVAL 90 DAY)
            ORDER BY ae.created_at DESC
        ";
        
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':user_id', $userId);
        $stmt->execute();
        
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    private function getUserFavorites(string $userId): array {
        $sql = "
            SELECT ll.* FROM land_listings ll
            JOIN user_favorites uf ON uf.listing_id = ll.id
            WHERE uf.user_id = :user_id
        ";
        
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':user_id', $userId);
        $stmt->execute();
        
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    private function getUserProfile(string $userId): array {
        // This would typically come from a user profile table
        // For now, return basic profile data
        return [
            'device_type' => 'unknown',
            'location' => 'unknown'
        ];
    }
    
    private function getCandidateListings(string $userId): array {
        $sql = "
            SELECT * FROM land_listings 
            WHERE status = 'active' 
                AND id NOT IN (
                    SELECT ll.id FROM land_listings ll
                    JOIN analytics_events ae ON ae.properties->>'listing_id' = ll.id
                    WHERE ae.user_id = :user_id
                )
            ORDER BY created_at DESC
            LIMIT 100
        ";
        
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':user_id', $userId);
        $stmt->execute();
        
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    private function getListingById(int $listingId): ?array {
        $sql = "SELECT * FROM land_listings WHERE id = :id";
        $stmt = $this->db->prepare($sql);
        $stmt->bindParam(':id', $listingId);
        $stmt->execute();
        
        return $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
    }
    
    private function getAllActiveListings(): array {
        $sql = "SELECT * FROM land_listings WHERE status = 'active' ORDER BY created_at DESC";
        $stmt = $this->db->prepare($sql);
        $stmt->execute();
        
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    private function getPriceScore(float $price, string $priceRange): float {
        $config = $this->priceRangeScores[$priceRange] ?? $this->priceRangeScores['mid_range'];
        
        if ($price >= $config['min'] && $price < $config['max']) {
            return 1.0;
        }
        
        if ($price < $config['min']) {
            return 0.7;
        }
        
        return max(0.0, 1.0 - ($price - $config['max']) / $config['max']);
    }
    
    private function calculateTextSimilarity(string $text1, string $text2): float {
        $words1 = array_unique(str_word_count(strtolower($text1), 1));
        $words2 = array_unique(str_word_count(strtolower($text2), 1));
        
        $intersection = array_intersect($words1, $words2);
        $union = array_unique(array_merge($words1, $words2));
        
        return count($union) > 0 ? count($intersection) / count($union) : 0.0;
    }
    
    private function isNearby(array $listing, string $userLocation): bool {
        // Simplified proximity check
        return stripos($listing['location'], $userLocation) !== false;
    }
    
    private function getDaysSinceCreation(string $createdAt): int {
        return (new DateTime())->diff(new DateTime($createdAt))->days;
    }
}
