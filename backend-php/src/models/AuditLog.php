<?php

namespace App\Models;

use App\Services\Database;
use PDO;

class AuditLog
{
    private $db;

    public function __construct()
    {
        $this->db = Database::getInstance()->getConnection();
    }

    public function log($action, $listingId, $actor, $oldData = null, $newData = null)
    {
        $changedFields = null;
        if ($action === 'delete' && $oldData) {
            $changedFields = json_encode($oldData);
        } elseif ($oldData && $newData) {
            $changedFields = json_encode(array_keys(array_diff_assoc($newData, $oldData)));
        }

        $stmt = $this->db->prepare("INSERT INTO audit_logs (action, listing_id, actor, changed_fields, timestamp) VALUES (?, ?, ?, ?, ?)");
        $stmt->execute([
            $action,
            $listingId,
            $actor,
            $changedFields,
            date('Y-m-d H:i:s')
        ]);
    }

    public function getAll()
    {
        $stmt = $this->db->query("SELECT * FROM audit_logs ORDER BY timestamp DESC");
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}