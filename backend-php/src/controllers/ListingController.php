<?php

namespace App\Controllers;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use App\Models\Listing;
use App\Services\AuditLogService;
use App\Services\OpenAiService;
use App\Services\Database;
use Respect\Validation\Validator as v;

class ListingController
{
    private $listingModel;
    private AuditLogService $audit;
    private OpenAiService $openai;

    public function __construct()
    {
        $pdo                = Database::getInstance()->getConnection();
        $this->listingModel = new Listing();
        $this->audit        = new AuditLogService($pdo);
        $this->openai       = new OpenAiService($pdo);
    }

    public function index(Request $request, Response $response, $args)
    {
        $listings = $this->listingModel->getAll();
        $response->getBody()->write(json_encode($listings));
        return $response->withHeader('Content-Type', 'application/json');
    }

    public function show(Request $request, Response $response, $args)
    {
        $listing = $this->listingModel->getById($args['id']);
        if (!$listing) {
            $response->getBody()->write(json_encode(['error' => 'Listing not found']));
            return $response->withStatus(404)->withHeader('Content-Type', 'application/json');
        }
        $response->getBody()->write(json_encode($listing));
        return $response->withHeader('Content-Type', 'application/json');
    }

    public function create(Request $request, Response $response, $args)
    {
        $data = json_decode($request->getBody()->getContents(), true);
        $admin = $request->getAttribute('admin');

        // Validation
        $validator = v::key('title', v::stringType()->length(1, 200))
            ->key('description', v::stringType()->length(1, 2000))
            ->key('price', v::numeric()->min(0))
            ->key('area', v::numeric()->min(0))
            ->key('country', v::in(['saudiArabia', 'uae', 'qatar', 'bahrain', 'oman', 'kuwait']))
            ->key('location', v::stringType()->length(1, 200))
            ->key('imageUrls', v::arrayType()->each(v::stringType()));

        try {
            $validator->assert($data);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode(['error' => $e->getMessage()]));
            return $response->withStatus(400)->withHeader('Content-Type', 'application/json');
        }

        $id       = $this->listingModel->create($data);
        $tenantId = $request->getAttribute('tenant_id', '');
        $this->audit->logMutation($tenantId, 'create', 'listing', $id, $admin->username ?? 'unknown', null, $data);

        $response->getBody()->write(json_encode(['id' => $id]));
        return $response->withStatus(201)->withHeader('Content-Type', 'application/json');
    }

    public function update(Request $request, Response $response, $args)
    {
        $id = $args['id'];
        $data = json_decode($request->getBody()->getContents(), true);
        $admin = $request->getAttribute('admin');

        $oldData = $this->listingModel->getById($id);
        if (!$oldData) {
            $response->getBody()->write(json_encode(['error' => 'Listing not found']));
            return $response->withStatus(404)->withHeader('Content-Type', 'application/json');
        }

        // Validation same as create
        $validator = v::key('title', v::stringType()->length(1, 200))
            ->key('description', v::stringType()->length(1, 2000))
            ->key('price', v::numeric()->min(0))
            ->key('area', v::numeric()->min(0))
            ->key('country', v::in(['saudiArabia', 'uae', 'qatar', 'bahrain', 'oman', 'kuwait']))
            ->key('location', v::stringType()->length(1, 200))
            ->key('imageUrls', v::arrayType()->each(v::stringType()));

        try {
            $validator->assert($data);
        } catch (\Exception $e) {
            $response->getBody()->write(json_encode(['error' => $e->getMessage()]));
            return $response->withStatus(400)->withHeader('Content-Type', 'application/json');
        }

        $this->listingModel->update($id, $data);
        $tenantId = $request->getAttribute('tenant_id', '');
        $this->audit->logMutation($tenantId, 'update', 'listing', $id, $admin->username ?? 'unknown', $oldData, $data);

        $response->getBody()->write(json_encode(['message' => 'Updated']));
        return $response->withHeader('Content-Type', 'application/json');
    }

    public function delete(Request $request, Response $response, $args)
    {
        $id = $args['id'];
        $admin = $request->getAttribute('admin');

        $oldData = $this->listingModel->getById($id);
        if (!$oldData) {
            $response->getBody()->write(json_encode(['error' => 'Listing not found']));
            return $response->withStatus(404)->withHeader('Content-Type', 'application/json');
        }

        $this->listingModel->delete($id);
        $tenantId = $request->getAttribute('tenant_id', '');
        $this->audit->logMutation($tenantId, 'delete', 'listing', $id, $admin->username ?? 'unknown', $oldData, null);

        $response->getBody()->write(json_encode(['message' => 'Deleted']));
        return $response->withHeader('Content-Type', 'application/json');
    }

    public function publish(Request $request, Response $response, $args)
    {
        $id = $args['id'];
        $data = json_decode($request->getBody()->getContents(), true);
        $admin = $request->getAttribute('admin');

        if (!isset($data['isPublished'])) {
            $response->getBody()->write(json_encode(['error' => 'isPublished required']));
            return $response->withStatus(400)->withHeader('Content-Type', 'application/json');
        }

        $this->listingModel->publish($id, $data['isPublished']);
        $tenantId = $request->getAttribute('tenant_id', '');
        $this->audit->logMutation($tenantId, 'publish', 'listing', $id, $admin->username ?? 'unknown', null, ['isPublished' => $data['isPublished']]);

        $response->getBody()->write(json_encode(['message' => 'Published status updated']));
        return $response->withHeader('Content-Type', 'application/json');
    }

    /**
     * GET /api/listings/{id}/description
     * Return (or generate) a bilingual AI property description.
     * Auth: any authenticated role.
     */
    public function generateDescription(Request $request, Response $response, array $args): Response
    {
        $listing = $this->listingModel->getById($args['id']);
        if (!$listing) {
            $response->getBody()->write(json_encode(['error' => 'Listing not found']));
            return $response->withStatus(404)->withHeader('Content-Type', 'application/json');
        }

        // Ensure tenant_id is available (set by TenantMiddleware)
        if (empty($listing['tenant_id'])) {
            $listing['tenant_id'] = $request->getAttribute('tenant_id', '');
        }

        $description = $this->openai->generatePropertyDescription($listing);
        if ($description === '') {
            $response->getBody()->write(json_encode(['error' => 'Failed to generate description']));
            return $response->withStatus(502)->withHeader('Content-Type', 'application/json');
        }

        $response->getBody()->write(json_encode(['description' => $description]));
        return $response->withStatus(200)->withHeader('Content-Type', 'application/json');
    }

    /**
     * POST /api/listings/{id}/description/invalidate
     * Clear the cached AI description so the next request regenerates it.
     * Auth: admin or manager only.
     */
    public function invalidateDescription(Request $request, Response $response, array $args): Response
    {
        $listing = $this->listingModel->getById($args['id']);
        if (!$listing) {
            $response->getBody()->write(json_encode(['error' => 'Listing not found']));
            return $response->withStatus(404)->withHeader('Content-Type', 'application/json');
        }

        $tenantId = $listing['tenant_id'] ?? $request->getAttribute('tenant_id', '');
        $this->openai->invalidateCache($tenantId, $args['id']);

        $response->getBody()->write(json_encode(['message' => 'Description cache cleared']));
        return $response->withStatus(200)->withHeader('Content-Type', 'application/json');
    }
}