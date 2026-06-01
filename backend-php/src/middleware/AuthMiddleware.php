<?php

namespace App\Middleware;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface as RequestHandler;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;

class AuthMiddleware implements MiddlewareInterface
{
    /** @var string[] Roles allowed to pass this middleware instance */
    private array $allowedRoles;

    /**
     * @param string[] $allowedRoles  Roles that may access routes protected by this instance.
     *                                Default is all valid roles (any authenticated user).
     */
    public function __construct(array $allowedRoles = ['admin', 'manager', 'viewer'])
    {
        $this->allowedRoles = $allowedRoles;
    }

    public function process(Request $request, RequestHandler $handler): Response
    {
        $authHeader = $request->getHeaderLine('Authorization');
        if (!$authHeader || !preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
            return $this->unauthorized('Missing or malformed Authorization header');
        }

        $token = $matches[1];
        try {
            $decoded = JWT::decode($token, new Key(JWT_SECRET, 'HS256'));
        } catch (\Exception $e) {
            return $this->unauthorized('Invalid or expired token');
        }

        // --- RBAC check ---
        $role = $decoded->role ?? '';
        if (!in_array($role, $this->allowedRoles, true)) {
            return $this->forbidden("Role '$role' is not permitted to access this resource");
        }

        $request = $request->withAttribute('admin', $decoded);
        return $handler->handle($request);
    }

    private function unauthorized(string $message): Response
    {
        $response = new \Slim\Psr7\Response();
        $response->getBody()->write(json_encode(['error' => 'Unauthorized', 'message' => $message]));
        return $response->withStatus(401)->withHeader('Content-Type', 'application/json');
    }

    private function forbidden(string $message): Response
    {
        $response = new \Slim\Psr7\Response();
        $response->getBody()->write(json_encode(['error' => 'Forbidden', 'message' => $message]));
        return $response->withStatus(403)->withHeader('Content-Type', 'application/json');
    }
}
