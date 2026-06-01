<?php

namespace App\Controllers;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use App\Services\Database;
use App\Services\SubscriptionService;

/**
 * TenantController — exposes tenant profile and subscription state.
 */
class TenantController
{
    private SubscriptionService $subscriptions;
    private \PDO $pdo;

    public function __construct()
    {
        $this->pdo           = Database::getInstance()->getConnection();
        $this->subscriptions = new SubscriptionService($this->pdo);
    }

    /**
     * GET /api/tenant/me
     * Returns the current tenant's profile, plan, and trial/billing state.
     * Auth: any authenticated role.
     */
    public function me(Request $request, Response $response): Response
    {
        $tenantId = $request->getAttribute('tenant_id', '');
        if (!$tenantId) {
            $response->getBody()->write(json_encode(['error' => 'No tenant context']));
            return $response->withStatus(400)->withHeader('Content-Type', 'application/json');
        }

        $stmt = $this->pdo->prepare(
            'SELECT id, name, slug, plan, status, settings,
                    billing_status, trial_started_at, trial_expires_at, created_at
             FROM tenants WHERE id = ? LIMIT 1'
        );
        $stmt->execute([$tenantId]);
        $tenant = $stmt->fetch(\PDO::FETCH_ASSOC);

        if (!$tenant) {
            $response->getBody()->write(json_encode(['error' => 'Tenant not found']));
            return $response->withStatus(404)->withHeader('Content-Type', 'application/json');
        }

        // Decode settings JSON if present
        if (isset($tenant['settings']) && is_string($tenant['settings'])) {
            $tenant['settings'] = json_decode($tenant['settings'], true) ?? [];
        }

        $trialState = $this->subscriptions->getTrialState($tenant);

        $response->getBody()->write(json_encode([
            'id'             => $tenant['id'],
            'name'           => $tenant['name'],
            'slug'           => $tenant['slug'],
            'plan'           => $tenant['plan'],
            'status'         => $tenant['status'],
            'settings'       => $tenant['settings'] ?? [],
            'subscription'   => $trialState,
            'created_at'     => $tenant['created_at'],
        ], JSON_UNESCAPED_UNICODE));

        return $response->withStatus(200)->withHeader('Content-Type', 'application/json');
    }
}
