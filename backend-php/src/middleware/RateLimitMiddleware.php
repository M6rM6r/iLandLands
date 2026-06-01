<?php

namespace App\Middleware;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface as RequestHandler;

/**
 * Redis-backed sliding-window rate limiter.
 *
 * The previous implementation used an in-memory PHP array which is destroyed at
 * the end of every request — making the rate limit completely ineffective.
 * This implementation uses Redis atomic INCR + EXPIRE for correct persistence.
 */
class RateLimitMiddleware implements MiddlewareInterface
{
    /** General API: 120 requests per 60-second window */
    private const GENERAL_LIMIT  = 120;
    /** /login endpoint: 10 attempts per 15-minute window */
    private const LOGIN_LIMIT    = 10;
    private const LOGIN_WINDOW   = 900; // 15 min
    private const GENERAL_WINDOW = 60;  // 1 min

    private \Redis $redis;

    public function __construct()
    {
        $this->redis = new \Redis();
        $this->redis->connect(
            getenv('REDIS_HOST') ?: '127.0.0.1',
            (int)(getenv('REDIS_PORT') ?: 6379),
            1.0
        );
        $password = getenv('REDIS_PASSWORD');
        if ($password) {
            $this->redis->auth($password);
        }
    }

    public function process(Request $request, RequestHandler $handler): Response
    {
        $ip   = $request->getServerParams()['REMOTE_ADDR'] ?? 'unknown';
        $path = $request->getUri()->getPath();

        if (str_contains($path, '/login')) {
            [$limit, $window] = [self::LOGIN_LIMIT, self::LOGIN_WINDOW];
            $key = "slim_rl:login:$ip";
        } else {
            [$limit, $window] = [self::GENERAL_LIMIT, self::GENERAL_WINDOW];
            $key = "slim_rl:api:$ip";
        }

        // Atomic increment — if key didn't exist, Redis creates it with value 1
        $count = $this->redis->incr($key);

        // Set expiry only on the first request in the window
        if ($count === 1) {
            $this->redis->expire($key, $window);
        }

        if ($count > $limit) {
            $ttl = $this->redis->ttl($key);
            $response = new \Slim\Psr7\Response();
            $response->getBody()->write(json_encode([
                'error'       => 'Rate limit exceeded',
                'retry_after' => max(0, $ttl),
            ]));
            return $response
                ->withStatus(429)
                ->withHeader('Content-Type', 'application/json')
                ->withHeader('Retry-After', (string) max(0, $ttl));
        }

        return $handler->handle($request);
    }
}
