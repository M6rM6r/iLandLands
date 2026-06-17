<?php

class LandListing {
    private $db;
    private $table_name = 'land_listings';

    public function __construct($db) {
        $this->db = $db;
    }

    public function getListings($country = null, $sort = null, $search = null, $limit = 20, $offset = 0) {
        $sql = "SELECT * FROM {$this->table_name} WHERE status = 'active'";
        $params = [];

        if ($country) {
            $sql .= " AND country = :country";
            $params[':country'] = $country;
        }

        if ($search) {
            $sql .= " AND (title LIKE :search OR description LIKE :search OR location LIKE :search)";
            $searchParam = '%' . $search . '%';
            $params[':search'] = $searchParam;
        }

        // Add sorting
        switch ($sort) {
            case 'priceAsc':
                $sql .= " ORDER BY price ASC";
                break;
            case 'priceDesc':
                $sql .= " ORDER BY price DESC";
                break;
            case 'areaAsc':
                $sql .= " ORDER BY area ASC";
                break;
            case 'areaDesc':
                $sql .= " ORDER BY area DESC";
                break;
            case 'featured':
                $sql .= " ORDER BY is_featured DESC, created_at DESC";
                break;
            default:
                $sql .= " ORDER BY created_at DESC";
                break;
        }

        $sql .= " LIMIT :limit OFFSET :offset";
        $params[':limit'] = $limit;
        $params[':offset'] = $offset;

        try {
            $stmt = $this->db->prepare($sql);
            foreach ($params as $key => $value) {
                $stmt->bindValue($key, $value);
            }
            $stmt->execute();

            $listings = [];
            while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                $listings[] = $this->formatListing($row);
            }

            return $listings;
        } catch (PDOException $e) {
            error_log("Get listings error: " . $e->getMessage());
            throw new Exception("Failed to fetch listings");
        }
    }

    public function getListingById($id, $includeInactive = false) {
        $sql = "SELECT * FROM {$this->table_name} WHERE id = :id";
        if (!$includeInactive) {
            $sql .= " AND status = 'active'";
        }

        try {
            $stmt = $this->db->prepare($sql);
            $stmt->bindValue(':id', $id);
            $stmt->execute();

            $row = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($row) {
                return $this->formatListing($row);
            }

            return null;
        } catch (PDOException $e) {
            error_log("Get listing by ID error: " . $e->getMessage());
            throw new Exception("Failed to fetch listing");
        }
    }

    public function getFeaturedListings($limit = 10) {
        $sql = "SELECT * FROM {$this->table_name} 
                WHERE status = 'active' AND is_featured = 1 
                ORDER BY created_at DESC 
                LIMIT :limit";

        try {
            $stmt = $this->db->prepare($sql);
            $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
            $stmt->execute();

            $listings = [];
            while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                $listings[] = $this->formatListing($row);
            }

            return $listings;
        } catch (PDOException $e) {
            error_log("Get featured listings error: " . $e->getMessage());
            throw new Exception("Failed to fetch featured listings");
        }
    }

    public function searchListings($query, $country = null, $limit = 20, $offset = 0) {
        $sql = "SELECT * FROM {$this->table_name} WHERE status = 'active'";
        $params = [];

        $sql .= " AND (title LIKE :search OR description LIKE :search OR location LIKE :search)";
        $searchParam = '%' . $query . '%';
        $params[':search'] = $searchParam;

        if ($country) {
            $sql .= " AND country = :country";
            $params[':country'] = $country;
        }

        $sql .= " ORDER BY created_at DESC LIMIT :limit OFFSET :offset";
        $params[':limit'] = $limit;
        $params[':offset'] = $offset;

        try {
            $stmt = $this->db->prepare($sql);
            foreach ($params as $key => $value) {
                $stmt->bindValue($key, $value);
            }
            $stmt->execute();

            $listings = [];
            while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                $listings[] = $this->formatListing($row);
            }

            return $listings;
        } catch (PDOException $e) {
            error_log("Search listings error: " . $e->getMessage());
            throw new Exception("Failed to search listings");
        }
    }

    public function getTotalCount($country = null, $search = null) {
        $sql = "SELECT COUNT(*) as total FROM {$this->table_name} WHERE status = 'active'";
        $params = [];

        if ($country) {
            $sql .= " AND country = :country";
            $params[':country'] = $country;
        }

        if ($search) {
            $sql .= " AND (title LIKE :search OR description LIKE :search OR location LIKE :search)";
            $searchParam = '%' . $search . '%';
            $params[':search'] = $searchParam;
        }

        try {
            $stmt = $this->db->prepare($sql);
            foreach ($params as $key => $value) {
                $stmt->bindValue($key, $value);
            }
            $stmt->execute();

            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            return (int) $result['total'];
        } catch (PDOException $e) {
            error_log("Get total count error: " . $e->getMessage());
            return 0;
        }
    }

    public function getSearchCount($query, $country = null) {
        $sql = "SELECT COUNT(*) as total FROM {$this->table_name} WHERE status = 'active'";
        $params = [];

        $sql .= " AND (title LIKE :search OR description LIKE :search OR location LIKE :search)";
        $searchParam = '%' . $query . '%';
        $params[':search'] = $searchParam;

        if ($country) {
            $sql .= " AND country = :country";
            $params[':country'] = $country;
        }

        try {
            $stmt = $this->db->prepare($sql);
            foreach ($params as $key => $value) {
                $stmt->bindValue($key, $value);
            }
            $stmt->execute();

            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            return (int) $result['total'];
        } catch (PDOException $e) {
            error_log("Get search count error: " . $e->getMessage());
            return 0;
        }
    }

    public function addToFavorites($landId, $userId) {
        $sql = "INSERT INTO user_favorites (user_id, land_id, created_at) 
                VALUES (:user_id, :land_id, NOW()) 
                ON DUPLICATE KEY UPDATE created_at = NOW()";

        try {
            $stmt = $this->db->prepare($sql);
            $stmt->bindValue(':user_id', $userId);
            $stmt->bindValue(':land_id', $landId);
            return $stmt->execute();
        } catch (PDOException $e) {
            error_log("Add to favorites error: " . $e->getMessage());
            return false;
        }
    }

    public function removeFromFavorites($landId, $userId) {
        $sql = "DELETE FROM user_favorites WHERE user_id = :user_id AND land_id = :land_id";

        try {
            $stmt = $this->db->prepare($sql);
            $stmt->bindValue(':user_id', $userId);
            $stmt->bindValue(':land_id', $landId);
            return $stmt->execute();
        } catch (PDOException $e) {
            error_log("Remove from favorites error: " . $e->getMessage());
            return false;
        }
    }

    public function getUserFavorites($userId) {
        $sql = "SELECT ll.* FROM {$this->table_name} ll
                INNER JOIN user_favorites uf ON ll.id = uf.land_id
                WHERE uf.user_id = :user_id AND ll.status = 'active'
                ORDER BY uf.created_at DESC";

        try {
            $stmt = $this->db->prepare($sql);
            $stmt->bindValue(':user_id', $userId);
            $stmt->execute();

            $favorites = [];
            while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                $favorites[] = $this->formatListing($row);
            }

            return $favorites;
        } catch (PDOException $e) {
            error_log("Get user favorites error: " . $e->getMessage());
            return [];
        }
    }

    public function createListing(array $data): ?string {
        $sql = "INSERT INTO {$this->table_name}
                (id, tenant_id, title, description, price, area, country, location, image_urls, is_featured, status, created_at, updated_at)
                VALUES (:id, :tenant_id, :title, :description, :price, :area, :country, :location, :image_urls, :is_featured, :status, NOW(), NOW())";

        try {
            $id = $data['id'] ?? $this->generateUuid();
            $stmt = $this->db->prepare($sql);
            $stmt->bindValue(':id', $id);
            $stmt->bindValue(':tenant_id', $data['tenant_id']);
            $stmt->bindValue(':title', $data['title']);
            $stmt->bindValue(':description', $data['description']);
            $stmt->bindValue(':price', $data['price']);
            $stmt->bindValue(':area', $data['area']);
            $stmt->bindValue(':country', $data['country']);
            $stmt->bindValue(':location', $data['location']);
            $stmt->bindValue(':image_urls', json_encode($data['image_urls'] ?? []));
            $stmt->bindValue(':is_featured', $data['is_featured'] ?? false, PDO::PARAM_BOOL);
            $stmt->bindValue(':status', $data['status'] ?? 'active');
            $stmt->execute();
            return $id;
        } catch (PDOException $e) {
            error_log("Create listing error: " . $e->getMessage());
            return null;
        }
    }

    public function updateListing(string $id, string $tenantId, array $data): bool {
        $allowedFields = ['title', 'description', 'price', 'area', 'country', 'location', 'image_urls', 'is_featured', 'status'];
        $updates = [];
        $params = [];

        foreach ($allowedFields as $field) {
            if (array_key_exists($field, $data)) {
                $updates[] = "{$field} = :{$field}";
                if ($field === 'image_urls') {
                    $params[":{$field}"] = json_encode($data[$field]);
                } elseif ($field === 'is_featured') {
                    $params[":{$field}"] = $data[$field] ? 1 : 0;
                } else {
                    $params[":{$field}"] = $data[$field];
                }
            }
        }

        if (empty($updates)) {
            return false;
        }

        $sql = "UPDATE {$this->table_name} SET " . implode(', ', $updates) . ", updated_at = NOW() WHERE id = :id AND tenant_id = :tenant_id";
        $params[':id'] = $id;
        $params[':tenant_id'] = $tenantId;

        try {
            $stmt = $this->db->prepare($sql);
            foreach ($params as $key => $value) {
                $stmt->bindValue($key, $value);
            }
            $stmt->execute();
            return $stmt->rowCount() > 0;
        } catch (PDOException $e) {
            error_log("Update listing error: " . $e->getMessage());
            return false;
        }
    }

    public function deleteListing(string $id, string $tenantId): bool {
        // Soft delete: mark as inactive
        $sql = "UPDATE {$this->table_name} SET status = 'inactive', updated_at = NOW() WHERE id = :id AND tenant_id = :tenant_id";
        try {
            $stmt = $this->db->prepare($sql);
            $stmt->bindValue(':id', $id);
            $stmt->bindValue(':tenant_id', $tenantId);
            $stmt->execute();
            return $stmt->rowCount() > 0;
        } catch (PDOException $e) {
            error_log("Delete listing error: " . $e->getMessage());
            return false;
        }
    }

    private function generateUuid(): string {
        $data = random_bytes(16);
        $data[6] = chr(ord($data[6]) & 0x0f | 0x40);
        $data[8] = chr(ord($data[8]) & 0x3f | 0x80);
        return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
    }

    private function formatListing($row) {
        return [
            'id' => $row['id'],
            'title' => $row['title'],
            'description' => $row['description'],
            'price' => (float) $row['price'],
            'area' => (float) $row['area'],
            'country' => $row['country'],
            'location' => $row['location'],
            'imageUrls' => json_decode($row['image_urls'], true) ?? [],
            'isFeatured' => (bool) $row['is_featured'],
            'createdAt' => $row['created_at'],
            'updatedAt' => $row['updated_at']
        ];
    }
}
?>
