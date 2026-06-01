<?php

class Database {
    private $host;
    private $db_name;
    private $username;
    private $password;
    private $charset = 'utf8mb4';
    
    public function __construct() {
        $this->host = getenv('DB_HOST') ?: 'localhost';
        $this->db_name = getenv('DB_NAME') ?: 'gulflands';
        $this->username = getenv('DB_USER') ?: 'gulflands_user';
        $this->password = getenv('DB_PASS') ?: '';
    }
    
    public $conn;

    public function getConnection() {
        $this->conn = null;

        try {
            $dsn = "mysql:host=" . $this->host . ";dbname=" . $this->db_name . ";charset=" . $this->charset;
            
            $options = [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
                PDO::ATTR_PERSISTENT => true,
                PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci"
            ];

            $this->conn = new PDO($dsn, $this->username, $this->password, $options);

            // Set timezone
            $this->conn->exec("SET time_zone = '+00:00'");
            
            return $this->conn;
        } catch(PDOException $exception) {
            error_log("Database connection error: " . $exception->getMessage());
            
            // In production, return a more generic error
            if (defined('ENVIRONMENT') && ENVIRONMENT === 'production') {
                throw new Exception("Database connection failed");
            } else {
                throw new Exception("Database connection failed: " . $exception->getMessage());
            }
        }
    }

    public function closeConnection() {
        $this->conn = null;
    }

    public function beginTransaction() {
        return $this->conn->beginTransaction();
    }

    public function commit() {
        return $this->conn->commit();
    }

    public function rollback() {
        return $this->conn->rollback();
    }

    public function getLastInsertId() {
        return $this->conn->lastInsertId();
    }

    public function prepare($sql) {
        return $this->conn->prepare($sql);
    }

    public function query($sql) {
        return $this->conn->query($sql);
    }

    public function execute($sql, $params = []) {
        try {
            $stmt = $this->conn->prepare($sql);
            return $stmt->execute($params);
        } catch(PDOException $exception) {
            error_log("Query execution error: " . $exception->getMessage());
            throw new Exception("Query execution failed");
        }
    }

    public function fetchAll($sql, $params = []) {
        try {
            $stmt = $this->conn->prepare($sql);
            $stmt->execute($params);
            return $stmt->fetchAll();
        } catch(PDOException $exception) {
            error_log("Fetch all error: " . $exception->getMessage());
            throw new Exception("Fetch operation failed");
        }
    }

    public function fetchOne($sql, $params = []) {
        try {
            $stmt = $this->conn->prepare($sql);
            $stmt->execute($params);
            return $stmt->fetch();
        } catch(PDOException $exception) {
            error_log("Fetch one error: " . $exception->getMessage());
            throw new Exception("Fetch operation failed");
        }
    }

    public function insert($table, $data) {
        try {
            $columns = array_keys($data);
            $placeholders = array_fill(0, count($columns), '?');
            
            $sql = "INSERT INTO $table (" . implode(', ', $columns) . ") 
                    VALUES (" . implode(', ', $placeholders) . ")";
            
            $stmt = $this->conn->prepare($sql);
            $stmt->execute(array_values($data));
            
            return $this->getLastInsertId();
        } catch(PDOException $exception) {
            error_log("Insert error: " . $exception->getMessage());
            throw new Exception("Insert operation failed");
        }
    }

    public function update($table, $data, $where, $whereParams = []) {
        try {
            $setClauses = [];
            $params = [];
            
            foreach ($data as $column => $value) {
                $setClauses[] = "$column = ?";
                $params[] = $value;
            }
            
            $sql = "UPDATE $table SET " . implode(', ', $setClauses) . " WHERE $where";
            
            $params = array_merge($params, $whereParams);
            
            $stmt = $this->conn->prepare($sql);
            return $stmt->execute($params);
        } catch(PDOException $exception) {
            error_log("Update error: " . $exception->getMessage());
            throw new Exception("Update operation failed");
        }
    }

    public function delete($table, $where, $params = []) {
        try {
            $sql = "DELETE FROM $table WHERE $where";
            $stmt = $this->conn->prepare($sql);
            return $stmt->execute($params);
        } catch(PDOException $exception) {
            error_log("Delete error: " . $exception->getMessage());
            throw new Exception("Delete operation failed");
        }
    }
}
?>
