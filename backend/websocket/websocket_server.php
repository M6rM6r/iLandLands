<?php

namespace Gulflands\WebSocket;

use Ratchet\MessageComponentInterface;
use Ratchet\ConnectionInterface;
use Ratchet\Server\IoServer;
use Ratchet\Http\HttpServer;
use Ratchet\WebSocket\WsServer;
use Gulflands\Services\SmartRecommendationEngine;
use Gulflands\Models\Analytics;
use PDO;

/**
 * Real-time WebSocket Server for Gulf Lands
 * Handles live updates, notifications, and real-time interactions
 */
class WebSocketServer implements MessageComponentInterface {
    protected $clients;
    protected $analytics;
    protected $recommendationEngine;
    protected $pdo;
    
    public function __construct(PDO $pdo, Analytics $analytics, SmartRecommendationEngine $recommendationEngine) {
        $this->clients = new \SplObjectStorage;
        $this->pdo = $pdo;
        $this->analytics = $analytics;
        $this->recommendationEngine = $recommendationEngine;
    }
    
    public function onOpen(ConnectionInterface $conn) {
        $this->clients->attach($conn);
        $conn->send(json_encode([
            'type' => 'connection_established',
            'message' => 'Connected to Gulf Lands Real-time Server',
            'timestamp' => time(),
            'user_id' => $conn->resourceId
        ]));
        
        echo "New connection! ({$conn->resourceId})\n";
    }
    
    public function onMessage(ConnectionInterface $from, $msg) {
        $data = json_decode($msg, true);
        
        if (!$data || !isset($data['type'])) {
            $from->send(json_encode([
                'type' => 'error',
                'message' => 'Invalid message format'
            ]));
            return;
        }
        
        switch ($data['type']) {
            case 'subscribe':
                $this->handleSubscription($from, $data);
                break;
                
            case 'listing_view':
                $this->handleListingView($from, $data);
                break;
                
            case 'favorite_toggle':
                $this->handleFavoriteToggle($from, $data);
                break;
                
            case 'search_query':
                $this->handleSearchQuery($from, $data);
                break;
                
            case 'price_alert':
                $this->handlePriceAlert($from, $data);
                break;
                
            case 'user_location':
                $this->handleUserLocation($from, $data);
                break;
                
            default:
                $from->send(json_encode([
                    'type' => 'error',
                    'message' => 'Unknown message type: ' . $data['type']
                ]));
        }
    }
    
    public function onClose(ConnectionInterface $conn) {
        $this->clients->detach($conn);
        echo "Connection {$conn->resourceId} has disconnected\n";
    }
    
    public function onError(ConnectionInterface $conn, \Exception $e) {
        echo "An error has occurred: {$e->getMessage()}\n";
        $conn->close();
    }
    
    /**
     * Handle client subscriptions to channels
     */
    protected function handleSubscription(ConnectionInterface $conn, array $data) {
        $channels = $data['channels'] ?? [];
        
        foreach ($channels as $channel) {
            $conn->subscriptions[$channel] = true;
        }
        
        $conn->send(json_encode([
            'type' => 'subscription_confirmed',
            'channels' => $channels,
            'timestamp' => time()
        ]));
    }
    
    /**
     * Handle real-time listing views
     */
    protected function handleListingView(ConnectionInterface $from, array $data) {
        $listingId = $data['listing_id'] ?? null;
        $userId = $data['user_id'] ?? null;
        
        if (!$listingId) return;
        
        // Track analytics
        $this->analytics->trackEvent('listing_viewed', [
            'listing_id' => $listingId,
            'user_id' => $userId,
            'timestamp' => time(),
            'source' => 'websocket'
        ]);
        
        // Broadcast to other subscribed clients
        $this->broadcastToListingChannel($listingId, [
            'type' => 'listing_viewed',
            'listing_id' => $listingId,
            'viewer_count' => $this->getViewerCount($listingId),
            'timestamp' => time()
        ], $from);
        
        // Send personalized recommendations
        if ($userId) {
            $recommendations = $this->recommendationEngine->getRecommendations($userId, 5);
            $from->send(json_encode([
                'type' => 'recommendations',
                'data' => $recommendations,
                'trigger' => 'listing_view',
                'listing_id' => $listingId
            ]));
        }
    }
    
    /**
     * Handle favorite toggles in real-time
     */
    protected function handleFavoriteToggle(ConnectionInterface $from, array $data) {
        $listingId = $data['listing_id'] ?? null;
        $userId = $data['user_id'] ?? null;
        $isFavorited = $data['is_favorited'] ?? false;
        
        if (!$listingId || !$userId) return;
        
        // Update database
        $stmt = $this->pdo->prepare("
            INSERT INTO user_favorites (user_id, listing_id, created_at) 
            VALUES (?, ?, NOW())
            ON DUPLICATE KEY UPDATE 
            deleted_at = CASE WHEN ? = 0 THEN NOW() ELSE deleted_at END
        ");
        $stmt->execute([$userId, $listingId, $isFavorited ? 1 : 0]);
        
        // Track analytics
        $this->analytics->trackEvent($isFavorited ? 'added_to_favorites' : 'removed_from_favorites', [
            'listing_id' => $listingId,
            'user_id' => $userId,
            'timestamp' => time()
        ]);
        
        // Broadcast favorite count update
        $favoriteCount = $this->getFavoriteCount($listingId);
        $this->broadcastToListingChannel($listingId, [
            'type' => 'favorite_count_updated',
            'listing_id' => $listingId,
            'favorite_count' => $favoriteCount,
            'user_action' => $isFavorited ? 'added' : 'removed',
            'timestamp' => time()
        ]);
    }
    
    /**
     * Handle search queries for real-time suggestions
     */
    protected function handleSearchQuery(ConnectionInterface $from, array $data) {
        $query = $data['query'] ?? '';
        $userId = $data['user_id'] ?? null;
        
        if (strlen($query) < 2) return;
        
        // Get search suggestions
        $suggestions = $this->getSearchSuggestions($query);
        
        $from->send(json_encode([
            'type' => 'search_suggestions',
            'query' => $query,
            'suggestions' => $suggestions,
            'timestamp' => time()
        ]));
        
        // Track search analytics
        $this->analytics->trackEvent('search_query', [
            'query' => $query,
            'user_id' => $userId,
            'suggestions_count' => count($suggestions),
            'timestamp' => time()
        ]);
    }
    
    /**
     * Handle price alerts
     */
    protected function handlePriceAlert(ConnectionInterface $from, array $data) {
        $listingId = $data['listing_id'] ?? null;
        $targetPrice = $data['target_price'] ?? null;
        $userId = $data['user_id'] ?? null;
        
        if (!$listingId || !$targetPrice || !$userId) return;
        
        // Save price alert
        $stmt = $this->pdo->prepare("
            INSERT INTO price_alerts (user_id, listing_id, target_price, created_at)
            VALUES (?, ?, ?, NOW())
            ON DUPLICATE KEY UPDATE target_price = VALUES(target_price)
        ");
        $stmt->execute([$userId, $listingId, $targetPrice]);
        
        $from->send(json_encode([
            'type' => 'price_alert_set',
            'listing_id' => $listingId,
            'target_price' => $targetPrice,
            'timestamp' => time()
        ]));
    }
    
    /**
     * Handle user location updates
     */
    protected function handleUserLocation(ConnectionInterface $from, array $data) {
        $userId = $data['user_id'] ?? null;
        $latitude = $data['latitude'] ?? null;
        $longitude = $data['longitude'] ?? null;
        
        if (!$userId || !$latitude || !$longitude) return;
        
        // Update user location
        $stmt = $this->pdo->prepare("
            INSERT INTO user_locations (user_id, latitude, longitude, updated_at)
            VALUES (?, ?, ?, NOW())
            ON DUPLICATE KEY UPDATE 
            latitude = VALUES(latitude),
            longitude = VALUES(longitude),
            updated_at = NOW()
        ");
        $stmt->execute([$userId, $latitude, $longitude]);
        
        // Get nearby listings
        $nearbyListings = $this->getNearbyListings($latitude, $longitude, 10);
        
        $from->send(json_encode([
            'type' => 'nearby_listings',
            'listings' => $nearbyListings,
            'timestamp' => time()
        ]));
    }
    
    /**
     * Broadcast message to all clients subscribed to a listing
     */
    protected function broadcastToListingChannel(string $listingId, array $message, ConnectionInterface $exclude = null) {
        foreach ($this->clients as $client) {
            if ($client !== $exclude && isset($client->subscriptions["listing_{$listingId}"])) {
                $client->send(json_encode($message));
            }
        }
    }
    
    /**
     * Broadcast to all clients
     */
    protected function broadcastToAll(array $message, ConnectionInterface $exclude = null) {
        foreach ($this->clients as $client) {
            if ($client !== $exclude) {
                $client->send(json_encode($message));
            }
        }
    }
    
    /**
     * Get current viewer count for a listing
     */
    protected function getViewerCount(string $listingId): int {
        $count = 0;
        $window = 300; // 5 minutes
        
        foreach ($this->clients as $client) {
            if (isset($client->last_activity["listing_{$listingId}"]) && 
                (time() - $client->last_activity["listing_{$listingId}"]) < $window) {
                $count++;
            }
        }
        
        return $count;
    }
    
    /**
     * Get favorite count for a listing
     */
    protected function getFavoriteCount(string $listingId): int {
        $stmt = $this->pdo->prepare("
            SELECT COUNT(*) FROM user_favorites 
            WHERE listing_id = ? AND deleted_at IS NULL
        ");
        $stmt->execute([$listingId]);
        return (int)$stmt->fetchColumn();
    }
    
    /**
     * Get search suggestions
     */
    protected function getSearchSuggestions(string $query): array {
        $stmt = $this->pdo->prepare("
            SELECT DISTINCT 
                title as suggestion,
                'title' as type
            FROM land_listings 
            WHERE title LIKE ? AND status = 'active'
            LIMIT 5
            
            UNION ALL
            
            SELECT DISTINCT 
                location as suggestion,
                'location' as type
            FROM land_listings 
            WHERE location LIKE ? AND status = 'active'
            LIMIT 5
            
            UNION ALL
            
            SELECT DISTINCT 
                country as suggestion,
                'country' as type
            FROM land_listings 
            WHERE country LIKE ? AND status = 'active'
            LIMIT 3
        ");
        
        $searchTerm = "%{$query}%";
        $stmt->execute([$searchTerm, $searchTerm, $searchTerm]);
        
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    /**
     * Get nearby listings based on coordinates
     */
    protected function getNearbyListings(float $lat, float $lng, int $radiusKm): array {
        $stmt = $this->pdo->prepare("
            SELECT *, 
                (6371 * acos(cos(radians(?)) * cos(radians(latitude)) * 
                cos(radians(longitude) - radians(?)) + sin(radians(?)) * 
                sin(radians(latitude)))) AS distance
            FROM land_listings 
            WHERE latitude IS NOT NULL AND longitude IS NOT NULL 
                AND status = 'active'
            HAVING distance < ?
            ORDER BY distance
            LIMIT 10
        ");
        
        $stmt->execute([$lat, $lng, $lat, $radiusKm]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    /**
     * Send real-time notifications
     */
    public function sendNotification(string $userId, array $notification) {
        foreach ($this->clients as $client) {
            if (isset($client->user_id) && $client->user_id === $userId) {
                $client->send(json_encode([
                    'type' => 'notification',
                    'data' => $notification,
                    'timestamp' => time()
                ]));
                break;
            }
        }
    }
    
    /**
     * Broadcast listing updates
     */
    public function broadcastListingUpdate(string $listingId, array $update) {
        $this->broadcastToListingChannel($listingId, [
            'type' => 'listing_updated',
            'listing_id' => $listingId,
            'update' => $update,
            'timestamp' => time()
        ]);
    }
    
    /**
     * Broadcast new listings
     */
    public function broadcastNewListing(array $listing) {
        $this->broadcastToAll([
            'type' => 'new_listing',
            'listing' => $listing,
            'timestamp' => time()
        ]);
    }
}

// WebSocket Server Bootstrap
function runWebSocketServer(PDO $pdo, Analytics $analytics, SmartRecommendationEngine $recommendationEngine) {
    $server = new WebSocketServer($pdo, $analytics, $recommendationEngine);
    
    $app = new WsServer(
        new HttpServer(
            new IoServer(
                $server,
                '0.0.0.0',
                8080
            )
        )
    );
    
    echo "WebSocket server started on ws://0.0.0.0:8080\n";
    $app->run();
}
