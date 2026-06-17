<?php

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../services/HubSpotService.php';

/**
 * AuthController — Register / Login for the primary PHP REST API.
 *
 * POST /api/v1/auth/register  — create new user account
 * POST /api/v1/auth/login     — exchange credentials for JWT + refresh token
 * POST /api/v1/auth/refresh   — issue a new access token using a valid refresh token
 */
class AuthController {

    private PDO $db;
    private HubSpotService $hubspot;

    public function __construct(PDO $db) {
        $this->db      = $db;
        $this->hubspot = new HubSpotService();
    }

    // -------------------------------------------------------------------------
    // POST /api/v1/auth/register
    // -------------------------------------------------------------------------
    public function register(): void {
        $body = $this->parseJsonBody();

        $email     = trim($body['email'] ?? '');
        $password  = $body['password'] ?? '';
        $country   = $body['country'] ?? '';
        $tenantId  = trim($body['tenant_id'] ?? 'a0000000-0000-0000-0000-000000000001');
        $firstName = trim($body['first_name'] ?? '');
        $lastName  = trim($body['last_name'] ?? '');
        $phone     = trim($body['phone'] ?? '');

        // --- Input validation ---
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $this->respond(422, ['error' => 'Invalid email address']);
        }
        if (strlen($password) < 10) {
            $this->respond(422, ['error' => 'Password must be at least 10 characters']);
        }
        $allowedCountries = ['saudiArabia', 'uae', 'qatar', 'bahrain', 'oman', 'kuwait'];
        if (!in_array($country, $allowedCountries, true)) {
            $this->respond(422, ['error' => 'country must be one of: ' . implode(', ', $allowedCountries)]);
        }

        // --- Check duplicate email within tenant ---
        $stmt = $this->db->prepare('SELECT id FROM users WHERE tenant_id = ? AND email = ? LIMIT 1');
        $stmt->execute([$tenantId, $email]);
        if ($stmt->fetch()) {
            $this->respond(409, ['error' => 'Email already registered for this tenant']);
        }

        // --- Store ---
        $id           = $this->generateUuid();
        $passwordHash = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);
        $stmt = $this->db->prepare(
            'INSERT INTO users (id, tenant_id, email, password_hash, first_name, last_name, phone, country, role, status, created_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, \'viewer\', \'active\', NOW())'
        );
        $stmt->execute([
            $id, $tenantId, $email, $passwordHash,
            $firstName !== '' ? $firstName : null,
            $lastName  !== '' ? $lastName  : null,
            $phone     !== '' ? $phone     : null,
            $country,
        ]);

        // --- Async: push to HubSpot CRM (non-blocking, errors are logged not thrown) ---
        $this->hubspot->upsertContact([
            'id'      => $id,
            'email'   => $email,
            'country' => $country,
        ]);

        $this->respond(201, ['id' => $id, 'email' => $email, 'country' => $country, 'tenant_id' => $tenantId]);
    }

    // -------------------------------------------------------------------------
    // POST /api/v1/auth/login
    // -------------------------------------------------------------------------
    public function login(): void {
        $body     = $this->parseJsonBody();
        $email    = trim($body['email'] ?? '');
        $password = $body['password'] ?? '';

        if ($email === '' || $password === '') {
            $this->respond(422, ['error' => 'email and password are required']);
        }

        // Introduce a minimum response delay to frustrate brute-force even when
        // the user does not exist (mitigates timing-based user enumeration).
        $startTime = microtime(true);

        $stmt = $this->db->prepare(
            'SELECT id, tenant_id, email, password_hash, country, status, role FROM users WHERE email = ? LIMIT 1'
        );
        $stmt->execute([$email]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        // Always call password_verify even on a dummy hash so timing is uniform
        $dummyHash    = '$2y$12$invalidhashpaddddddddddddddddddddddddddddddddddddddddddddd';
        $hashToCheck  = $user ? $user['password_hash'] : $dummyHash;
        $passwordValid = password_verify($password, $hashToCheck);

        if (!$user || !$passwordValid) {
            // Enforce minimum 200 ms to prevent timing attacks
            $elapsed = (microtime(true) - $startTime) * 1000;
            if ($elapsed < 200) {
                usleep((int)(200000 - $elapsed * 1000));
            }
            $this->respond(401, ['error' => 'Invalid credentials']);
        }

        if ($user['status'] !== 'active') {
            $this->respond(403, ['error' => 'Account is not active']);
        }

        $accessToken  = $this->issueJwt($user['id'], $user['tenant_id'], $user['email'], $user['role'], 3600);
        $refreshToken = $this->issueJwt($user['id'], $user['tenant_id'], $user['email'], $user['role'], 86400 * 30, 'refresh');

        $this->respond(200, [
            'access_token'  => $accessToken,
            'refresh_token' => $refreshToken,
            'token_type'    => 'Bearer',
            'expires_in'    => 3600,
            'user'          => [
                'id'        => $user['id'],
                'tenant_id' => $user['tenant_id'],
                'email'     => $user['email'],
                'country'   => $user['country'],
                'role'      => $user['role'],
            ],
        ]);
    }

    // -------------------------------------------------------------------------
    // POST /api/v1/auth/refresh
    // -------------------------------------------------------------------------
    public function refresh(): void {
        $body = $this->parseJsonBody();
        $refreshToken = $body['refresh_token'] ?? '';

        if ($refreshToken === '') {
            $this->respond(422, ['error' => 'refresh_token is required']);
        }

        // Validate the refresh token from the body (not the Authorization header)
        $payload = $this->validateRefreshToken($refreshToken);
        if ($payload === null) {
            $this->respond(401, ['error' => 'Invalid refresh token']);
        }

        if (($payload['type'] ?? '') !== 'refresh') {
            $this->respond(401, ['error' => 'Token is not a refresh token']);
        }

        $accessToken = $this->issueJwt($payload['sub'], $payload['tenant_id'] ?? '', $payload['email'], $payload['role'], 3600);

        $this->respond(200, [
            'access_token' => $accessToken,
            'token_type'   => 'Bearer',
            'expires_in'   => 3600,
        ]);
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------
    private function issueJwt(
        string $userId,
        string $tenantId,
        string $email,
        string $role,
        int    $ttlSeconds,
        string $type = 'access'
    ): string {
        $secret = getenv('JWT_SECRET');
        if (!$secret || strlen($secret) < 32) {
            throw new \RuntimeException('JWT_SECRET must be at least 32 characters');
        }

        $now     = time();
        $header  = $this->base64UrlEncode(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
        $payload = $this->base64UrlEncode(json_encode([
            'sub'       => $userId,
            'tenant_id' => $tenantId,
            'email'     => $email,
            'role'      => $role,
            'type'      => $type,
            'iat'       => $now,
            'exp'       => $now + $ttlSeconds,
        ]));
        $sig = $this->base64UrlEncode(hash_hmac('sha256', "$header.$payload", $secret, true));

        return "$header.$payload.$sig";
    }

    private function base64UrlEncode(string $data): string {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    /**
     * Validate a JWT token string directly (used for refresh tokens from body).
     */
    private function validateRefreshToken(string $token): ?array {
        $secret = getenv('JWT_SECRET');
        if (!$secret || strlen($secret) < 32) {
            return null;
        }

        $parts = explode('.', $token);
        if (count($parts) !== 3) {
            return null;
        }

        [$headerB64, $payloadB64, $signatureB64] = $parts;

        $expectedSig = $this->base64UrlEncode(hash_hmac('sha256', "$headerB64.$payloadB64", $secret, true));
        if (!hash_equals($expectedSig, $signatureB64)) {
            return null;
        }

        $payload = json_decode($this->base64UrlDecode($payloadB64), true);
        if (!is_array($payload)) {
            return null;
        }

        if (isset($payload['exp']) && $payload['exp'] < time()) {
            return null;
        }

        if (isset($payload['iat']) && $payload['iat'] > time() + 60) {
            return null;
        }

        return $payload;
    }

    private function base64UrlDecode(string $data): string {
        return base64_decode(strtr($data, '-_', '+/'));
    }

    private function parseJsonBody(): array {
        $raw = file_get_contents('php://input');
        if ($raw === '') {
            return [];
        }
        $decoded = json_decode($raw, true);
        if (!is_array($decoded)) {
            $this->respond(400, ['error' => 'Request body must be valid JSON']);
        }
        return $decoded;
    }

    /** RFC 4122 v4 UUID */
    private function generateUuid(): string {
        $bytes = random_bytes(16);
        $bytes[6] = chr((ord($bytes[6]) & 0x0f) | 0x40);
        $bytes[8] = chr((ord($bytes[8]) & 0x3f) | 0x80);
        return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($bytes), 4));
    }

    private function respond(int $status, array $body): never {
        http_response_code($status);
        header('Content-Type: application/json');
        echo json_encode($body);
        exit;
    }
}
