<?php

require_once '../models/LandListing.php';
require_once '../models/Analytics.php';
require_once '../services/OpenAiService.php';

class LandController {
    private $db;
    private $landListing;
    private $analytics;
    private OpenAiService $openai;

    public function __construct($db) {
        $this->db = $db;
        $this->landListing = new LandListing($db);
        $this->analytics = new Analytics($db);
        $this->openai = new OpenAiService($db);
    }

    public function getListings($params = []) {
        try {
            $country = $params['country'] ?? null;
            $sort = $params['sort'] ?? null;
            $search = $params['search'] ?? null;
            $page = max(1, intval($params['page'] ?? 1));
            $limit = min(50, max(1, intval($params['limit'] ?? 20)));
            $offset = ($page - 1) * $limit;

            $listings = $this->landListing->getListings($country, $sort, $search, $limit, $offset);
            $total = $this->landListing->getTotalCount($country, $search);

            $this->analytics->trackEvent('listings_viewed', [
                'country' => $country,
                'sort' => $sort,
                'search' => $search,
                'page' => $page,
                'results_count' => count($listings)
            ]);

            return [
                'success' => true,
                'data' => $listings,
                'pagination' => [
                    'page' => $page,
                    'limit' => $limit,
                    'total' => $total,
                    'pages' => ceil($total / $limit)
                ],
                'filters' => [
                    'country' => $country,
                    'sort' => $sort,
                    'search' => $search
                ]
            ];
        } catch (Exception $e) {
            error_log("Get listings error: " . $e->getMessage());
            return [
                'success' => false,
                'error' => 'Failed to fetch listings',
                'message' => defined('ENVIRONMENT') && ENVIRONMENT === 'development' ? $e->getMessage() : null
            ];
        }
    }

    public function getListing($id) {
        try {
            $listing = $this->landListing->getListingById($id);
            
            if (!$listing) {
                return [
                    'success' => false,
                    'error' => 'Listing not found'
                ];
            }

            $this->analytics->trackEvent('listing_viewed', [
                'listing_id' => $id,
                'country' => $listing['country']
            ]);

            return [
                'success' => true,
                'data' => $listing
            ];
        } catch (Exception $e) {
            error_log("Get listing error: " . $e->getMessage());
            return [
                'success' => false,
                'error' => 'Failed to fetch listing',
                'message' => defined('ENVIRONMENT') && ENVIRONMENT === 'development' ? $e->getMessage() : null
            ];
        }
    }

    public function getFeaturedListings() {
        try {
            $listings = $this->landListing->getFeaturedListings();

            $this->analytics->trackEvent('featured_listings_viewed', [
                'results_count' => count($listings)
            ]);

            return [
                'success' => true,
                'data' => $listings
            ];
        } catch (Exception $e) {
            error_log("Get featured listings error: " . $e->getMessage());
            return [
                'success' => false,
                'error' => 'Failed to fetch featured listings',
                'message' => defined('ENVIRONMENT') && ENVIRONMENT === 'development' ? $e->getMessage() : null
            ];
        }
    }

    public function searchListings($params) {
        try {
            $query = $params['q'] ?? '';
            $country = $params['country'] ?? null;
            $page = max(1, intval($params['page'] ?? 1));
            $limit = min(50, max(1, intval($params['limit'] ?? 20)));
            $offset = ($page - 1) * $limit;

            if (empty($query)) {
                return [
                    'success' => false,
                    'error' => 'Search query is required'
                ];
            }

            $listings = $this->landListing->searchListings($query, $country, $limit, $offset);
            $total = $this->landListing->getSearchCount($query, $country);

            $this->analytics->trackEvent('search_performed', [
                'query' => $query,
                'country' => $country,
                'page' => $page,
                'results_count' => count($listings)
            ]);

            return [
                'success' => true,
                'data' => $listings,
                'pagination' => [
                    'page' => $page,
                    'limit' => $limit,
                    'total' => $total,
                    'pages' => ceil($total / $limit)
                ],
                'search' => [
                    'query' => $query,
                    'country' => $country
                ]
            ];
        } catch (Exception $e) {
            error_log("Search listings error: " . $e->getMessage());
            return [
                'success' => false,
                'error' => 'Search failed',
                'message' => defined('ENVIRONMENT') && ENVIRONMENT === 'development' ? $e->getMessage() : null
            ];
        }
    }

    public function addToFavorites() {
        try {
            $input = json_decode(file_get_contents('php://input'), true);
            
            if (!isset($input['landId'])) {
                return [
                    'success' => false,
                    'error' => 'Land ID is required'
                ];
            }

            $landId = $input['landId'];
            $userId = $this->getUserId(); // Implement user authentication
            
            // Verify listing exists
            $listing = $this->landListing->getListingById($landId);
            if (!$listing) {
                return [
                    'success' => false,
                    'error' => 'Listing not found'
                ];
            }

            $result = $this->landListing->addToFavorites($landId, $userId);

            if ($result) {
                $this->analytics->trackEvent('added_to_favorites', [
                    'listing_id' => $landId,
                    'user_id' => $userId
                ]);

                return [
                    'success' => true,
                    'message' => 'Added to favorites'
                ];
            } else {
                return [
                    'success' => false,
                    'error' => 'Failed to add to favorites'
                ];
            }
        } catch (Exception $e) {
            error_log("Add to favorites error: " . $e->getMessage());
            return [
                'success' => false,
                'error' => 'Failed to add to favorites',
                'message' => defined('ENVIRONMENT') && ENVIRONMENT === 'development' ? $e->getMessage() : null
            ];
        }
    }

    public function removeFromFavorites($landId) {
        try {
            $userId = $this->getUserId(); // Implement user authentication
            
            $result = $this->landListing->removeFromFavorites($landId, $userId);

            if ($result) {
                $this->analytics->trackEvent('removed_from_favorites', [
                    'listing_id' => $landId,
                    'user_id' => $userId
                ]);

                return [
                    'success' => true,
                    'message' => 'Removed from favorites'
                ];
            } else {
                return [
                    'success' => false,
                    'error' => 'Failed to remove from favorites'
                ];
            }
        } catch (Exception $e) {
            error_log("Remove from favorites error: " . $e->getMessage());
            return [
                'success' => false,
                'error' => 'Failed to remove from favorites',
                'message' => defined('ENVIRONMENT') && ENVIRONMENT === 'development' ? $e->getMessage() : null
            ];
        }
    }

    public function getFavorites() {
        try {
            $userId = $this->getUserId(); // Implement user authentication
            $favorites = $this->landListing->getUserFavorites($userId);

            return [
                'success' => true,
                'data' => $favorites
            ];
        } catch (Exception $e) {
            error_log("Get favorites error: " . $e->getMessage());
            return [
                'success' => false,
                'error' => 'Failed to fetch favorites',
                'message' => defined('ENVIRONMENT') && ENVIRONMENT === 'development' ? $e->getMessage() : null
            ];
        }
    }

    public function trackAnalytics($data) {
        try {
            $event = $data['event'] ?? null;
            $properties = $data['properties'] ?? [];

            // Input validation
            if (!$event) {
                return [
                    'success' => false,
                    'error' => 'Event name is required'
                ];
            }

            // Validate event name (alphanumeric, underscore, dash only)
            if (!preg_match('/^[a-zA-Z0-9_-]+$/', $event)) {
                return [
                    'success' => false,
                    'error' => 'Invalid event name format'
                ];
            }

            // Validate properties size (limit to 10KB)
            if (strlen(json_encode($properties)) > 10000) {
                return [
                    'success' => false,
                    'error' => 'Event properties too large'
                ];
            }

            // Sanitize properties (basic XSS prevention)
            $properties = $this->sanitizeProperties($properties);

            $userId = $this->getUserId();
            $sessionId = $this->getSessionId();
            $userAgent = $_SERVER['HTTP_USER_AGENT'] ?? '';
            $ipAddress = $_SERVER['REMOTE_ADDR'] ?? '';

            $result = $this->analytics->trackEvent($event, $properties, $userId, $sessionId, $userAgent, $ipAddress);

            return [
                'success' => true,
                'message' => $result ? 'Event tracked successfully' : 'Failed to track event'
            ];
        } catch (Exception $e) {
            error_log("Track analytics error: " . $e->getMessage());
            return [
                'success' => false,
                'error' => 'Failed to track analytics',
                'message' => defined('ENVIRONMENT') && ENVIRONMENT === 'development' ? $e->getMessage() : null
            ];
        }
    }

    /**
     * GET /api/v1/listings/{id}/description
     * Generate (or return cached) AI property description.
     * Auth-gated — caller must be authenticated.
     */
    public function generateDescription(string $id): array
    {
        $listing = $this->landListing->getListingById($id);
        if (!$listing) {
            return ['success' => false, 'error' => 'Listing not found'];
        }

        $description = $this->openai->generatePropertyDescription($listing);

        if ($description === '') {
            return ['success' => false, 'error' => 'Failed to generate description'];
        }

        return ['success' => true, 'data' => ['description' => $description]];
    }

    /**
     * POST /api/v1/listings/{id}/description/invalidate
     * Clear the cached AI description so the next request regenerates it.
     * Admin/manager only.
     */
    public function invalidateDescription(string $id): array
    {
        $listing = $this->landListing->getListingById($id);
        if (!$listing) {
            return ['success' => false, 'error' => 'Listing not found'];
        }

        $tenantId = $listing['tenant_id'] ?? '';
        $this->openai->invalidateCache($tenantId, $id);

        return ['success' => true, 'message' => 'Description cache cleared'];
    }

    private function sanitizeProperties($properties) {
        if (is_array($properties)) {
            $sanitized = [];
            foreach ($properties as $key => $value) {
                $sanitizedKey = filter_var($key, FILTER_SANITIZE_STRING, FILTER_FLAG_NO_ENCODE_QUOTES);
                if (is_string($value)) {
                    $sanitized[$sanitizedKey] = filter_var($value, FILTER_SANITIZE_STRING, FILTER_FLAG_NO_ENCODE_QUOTES);
                } elseif (is_array($value)) {
                    $sanitized[$sanitizedKey] = $this->sanitizeProperties($value);
                } else {
                    $sanitized[$sanitizedKey] = $value;
                }
            }
            return $sanitized;
        }
        return $properties;
    }

    private function getUserId() {
        // Implement user authentication logic
        // For now, return a placeholder
        return 'anonymous_user_' . uniqid();
    }

    private function getSessionId() {
        if (!isset($_SESSION['session_id'])) {
            $_SESSION['session_id'] = uniqid('session_', true);
        }
        return $_SESSION['session_id'];
    }
}
?>
