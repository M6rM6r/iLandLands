<?php

namespace App\Models;

use App\Services\Database;
use PDO;

class Listing
{
    private $db;

    public function __construct()
    {
        $this->db = Database::getInstance()->getConnection();
    }

    public function getAll()
    {
        $stmt = $this->db->query("SELECT * FROM listings ORDER BY created_at DESC");
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function getById($id)
    {
        $stmt = $this->db->prepare("SELECT * FROM listings WHERE id = ?");
        $stmt->execute([$id]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    public function create($data)
    {
        $data['id'] = uniqid();
        $data['created_at'] = date('Y-m-d H:i:s');
        $data['updated_at'] = date('Y-m-d H:i:s');

        $stmt = $this->db->prepare("INSERT INTO listings (id, title, description, price, area, country, location, image_urls, is_featured, is_published, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->execute([
            $data['id'],
            $data['title'],
            $data['description'],
            $data['price'],
            $data['area'],
            $data['country'],
            $data['location'],
            json_encode($data['imageUrls']),
            $data['isFeatured'] ?? false,
            $data['isPublished'] ?? false,
            $data['created_at'],
            $data['updated_at']
        ]);

        return $data['id'];
    }

    public function update($id, $data)
    {
        $data['updated_at'] = date('Y-m-d H:i:s');

        $stmt = $this->db->prepare("UPDATE listings SET title = ?, description = ?, price = ?, area = ?, country = ?, location = ?, image_urls = ?, is_featured = ?, is_published = ?, updated_at = ? WHERE id = ?");
        $stmt->execute([
            $data['title'],
            $data['description'],
            $data['price'],
            $data['area'],
            $data['country'],
            $data['location'],
            json_encode($data['imageUrls']),
            $data['isFeatured'] ?? false,
            $data['isPublished'] ?? false,
            $data['updated_at'],
            $id
        ]);

        return $stmt->rowCount() > 0;
    }

    public function delete($id)
    {
        $stmt = $this->db->prepare("DELETE FROM listings WHERE id = ?");
        $stmt->execute([$id]);
        return $stmt->rowCount() > 0;
    }

    public function publish($id, $published)
    {
        $stmt = $this->db->prepare("UPDATE listings SET is_published = ?, updated_at = ? WHERE id = ?");
        $stmt->execute([$published, date('Y-m-d H:i:s'), $id]);
        return $stmt->rowCount() > 0;
    }
}