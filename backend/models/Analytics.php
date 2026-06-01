<?php

class Analytics {
    private $db;
    private $table_name = 'analytics_events';

    public function __construct($db) {
        $this->db = $db;
    }

    public function trackEvent($eventName, $properties = [], $userId = null, $sessionId = null, $userAgent = '', $ipAddress = '') {
        $sql = "INSERT INTO {$this->table_name} 
                (event_name, user_id, session_id, properties, user_agent, ip_address, created_at) 
                VALUES (:event_name, :user_id, :session_id, :properties, :user_agent, :ip_address, NOW())";

        try {
            $stmt = $this->db->prepare($sql);
            $stmt->bindValue(':event_name', $eventName);
            $stmt->bindValue(':user_id', $userId);
            $stmt->bindValue(':session_id', $sessionId);
            $stmt->bindValue(':properties', json_encode($properties));
            $stmt->bindValue(':user_agent', $userAgent);
            $stmt->bindValue(':ip_address', $ipAddress);
            
            return $stmt->execute();
        } catch (PDOException $e) {
            error_log("Track event error: " . $e->getMessage());
            return false;
        }
    }

    public function getEventStats($eventName = null, $startDate = null, $endDate = null) {
        $sql = "SELECT event_name, COUNT(*) as count, DATE(created_at) as date 
                FROM {$this->table_name} WHERE 1=1";
        $params = [];

        if ($eventName) {
            $sql .= " AND event_name = :event_name";
            $params[':event_name'] = $eventName;
        }

        if ($startDate) {
            $sql .= " AND created_at >= :start_date";
            $params[':start_date'] = $startDate;
        }

        if ($endDate) {
            $sql .= " AND created_at <= :end_date";
            $params[':end_date'] = $endDate;
        }

        $sql .= " GROUP BY event_name, DATE(created_at) ORDER BY date DESC";

        try {
            $stmt = $this->db->prepare($sql);
            foreach ($params as $key => $value) {
                $stmt->bindValue($key, $value);
            }
            $stmt->execute();

            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            error_log("Get event stats error: " . $e->getMessage());
            return [];
        }
    }

    public function getPopularListings($limit = 10) {
        $sql = "SELECT 
                    JSON_UNQUOTE(JSON_EXTRACT(properties, '$.listing_id')) as listing_id,
                    COUNT(*) as view_count
                FROM {$this->table_name} 
                WHERE event_name = 'listing_viewed' 
                    AND JSON_EXTRACT(properties, '$.listing_id') IS NOT NULL
                GROUP BY listing_id 
                ORDER BY view_count DESC 
                LIMIT :limit";

        try {
            $stmt = $this->db->prepare($sql);
            $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
            $stmt->execute();

            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            error_log("Get popular listings error: " . $e->getMessage());
            return [];
        }
    }

    public function getSearchAnalytics($limit = 100) {
        $sql = "SELECT 
                    JSON_UNQUOTE(JSON_EXTRACT(properties, '$.query')) as query,
                    JSON_UNQUOTE(JSON_EXTRACT(properties, '$.country')) as country,
                    COUNT(*) as search_count,
                    AVG(JSON_EXTRACT(properties, '$.results_count')) as avg_results
                FROM {$this->table_name} 
                WHERE event_name = 'search_performed' 
                    AND JSON_EXTRACT(properties, '$.query') IS NOT NULL
                GROUP BY query, country 
                ORDER BY search_count DESC 
                LIMIT :limit";

        try {
            $stmt = $this->db->prepare($sql);
            $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
            $stmt->execute();

            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            error_log("Get search analytics error: " . $e->getMessage());
            return [];
        }
    }

    public function getCountryAnalytics() {
        $sql = "SELECT 
                    JSON_UNQUOTE(JSON_EXTRACT(properties, '$.country')) as country,
                    COUNT(*) as count
                FROM {$this->table_name} 
                WHERE event_name IN ('listings_viewed', 'listing_viewed') 
                    AND JSON_EXTRACT(properties, '$.country') IS NOT NULL
                GROUP BY country 
                ORDER BY count DESC";

        try {
            $stmt = $this->db->prepare($sql);
            $stmt->execute();

            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            error_log("Get country analytics error: " . $e->getMessage());
            return [];
        }
    }

    public function getUserActivitySummary($userId, $days = 30) {
        $sql = "SELECT 
                    event_name,
                    COUNT(*) as count,
                    DATE(created_at) as date
                FROM {$this->table_name} 
                WHERE user_id = :user_id 
                    AND created_at >= DATE_SUB(NOW(), INTERVAL :days DAY)
                GROUP BY event_name, DATE(created_at) 
                ORDER BY date DESC";

        try {
            $stmt = $this->db->prepare($sql);
            $stmt->bindValue(':user_id', $userId);
            $stmt->bindValue(':days', $days, PDO::PARAM_INT);
            $stmt->execute();

            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            error_log("Get user activity summary error: " . $e->getMessage());
            return [];
        }
    }

    public function getConversionMetrics($startDate = null, $endDate = null) {
        $sql = "SELECT 
                    DATE(created_at) as date,
                    SUM(CASE WHEN event_name = 'listing_viewed' THEN 1 ELSE 0 END) as views,
                    SUM(CASE WHEN event_name = 'added_to_favorites' THEN 1 ELSE 0 END) as favorites,
                    ROUND(
                        SUM(CASE WHEN event_name = 'added_to_favorites' THEN 1 ELSE 0 END) * 100.0 / 
                        NULLIF(SUM(CASE WHEN event_name = 'listing_viewed' THEN 1 ELSE 0 END), 0), 
                        2
                    ) as conversion_rate
                FROM {$this->table_name} 
                WHERE event_name IN ('listing_viewed', 'added_to_favorites')";

        $params = [];

        if ($startDate) {
            $sql .= " AND created_at >= :start_date";
            $params[':start_date'] = $startDate;
        }

        if ($endDate) {
            $sql .= " AND created_at <= :end_date";
            $params[':end_date'] = $endDate;
        }

        $sql .= " GROUP BY DATE(created_at) ORDER BY date DESC";

        try {
            $stmt = $this->db->prepare($sql);
            foreach ($params as $key => $value) {
                $stmt->bindValue($key, $value);
            }
            $stmt->execute();

            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            error_log("Get conversion metrics error: " . $e->getMessage());
            return [];
        }
    }

    public function cleanupOldEvents($days = 90) {
        $sql = "DELETE FROM {$this->table_name} WHERE created_at < DATE_SUB(NOW(), INTERVAL :days DAY)";

        try {
            $stmt = $this->db->prepare($sql);
            $stmt->bindValue(':days', $days, PDO::PARAM_INT);
            $deleted = $stmt->execute();
            
            return $deleted;
        } catch (PDOException $e) {
            error_log("Cleanup old events error: " . $e->getMessage());
            return false;
        }
    }
}
?>
