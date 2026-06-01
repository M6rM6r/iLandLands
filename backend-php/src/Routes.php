<?php

namespace App;

use Slim\App;
use App\Controllers\ListingController;
use App\Controllers\AuthController;
use App\Controllers\PaymentController;
use App\Controllers\InquiryController;
use App\Controllers\TenantController;
use App\Controllers\WebhookController;
use App\Middleware\AuthMiddleware;
use App\Middleware\TenantMiddleware;
use App\Services\Database;

class Routes
{
    public static function register(App $app): void
    {
        // Shared PDO instance (singleton) for tenant look-ups
        $pdo = Database::getInstance()->getConnection();

        $paymentController = new PaymentController($pdo);

        // --- Public: Inquiry submission (rate-limited by middleware) ---
        $inquiryController = new InquiryController($pdo);
        $app->post('/api/inquiries', [$inquiryController, 'create']);

        // --- Public: Auth (no token required) ---
        $app->post('/login', [new AuthController(), 'login']);

        // --- Public: Telr webhooks and browser redirects ---
        $app->post('/api/payments/callback', [$paymentController, 'callback']);
        $app->get('/api/payments/return',    [$paymentController, 'returnRedirect']);
        $app->get('/api/payments/cancel',    [$paymentController, 'cancelRedirect']);

        // --- Public: Meta WhatsApp + PayTabs inbound webhooks ---
        $webhookController = new WebhookController();
        $app->get('/api/webhooks/whatsapp',  [$webhookController, 'whatsappVerify']);
        $app->post('/api/webhooks/whatsapp', [$webhookController, 'whatsappInbound']);
        $app->post('/api/webhooks/paytabs',  [$webhookController, 'paytabsCallback']);

        // --- Protected: Admin API ---
        // All routes carry both AuthMiddleware (RBAC) and TenantMiddleware (isolation).
        // Middleware is LIFO in Slim 4: the last ->add() call wraps the outermost shell.
        // Execution order: AuthMiddleware → TenantMiddleware → Handler
        $app->group('/api', function ($group) use ($pdo): void {

            // Read-only — any authenticated role
            $group->get('/listings', [new ListingController(), 'index'])
                  ->add(new TenantMiddleware($pdo))
                  ->add(new AuthMiddleware(['admin', 'manager', 'viewer']));

            $group->get('/listings/{id}', [new ListingController(), 'show'])
                  ->add(new TenantMiddleware($pdo))
                  ->add(new AuthMiddleware(['admin', 'manager', 'viewer']));

            // Write — manager or admin only
            $group->post('/listings', [new ListingController(), 'create'])
                  ->add(new TenantMiddleware($pdo))
                  ->add(new AuthMiddleware(['admin', 'manager']));

            $group->put('/listings/{id}', [new ListingController(), 'update'])
                  ->add(new TenantMiddleware($pdo))
                  ->add(new AuthMiddleware(['admin', 'manager']));

            $group->patch('/listings/{id}/publish', [new ListingController(), 'publish'])
                  ->add(new TenantMiddleware($pdo))
                  ->add(new AuthMiddleware(['admin', 'manager']));

            // Destructive — admin only
            $group->delete('/listings/{id}', [new ListingController(), 'delete'])
                  ->add(new TenantMiddleware($pdo))
                  ->add(new AuthMiddleware(['admin']));

            // --- AI Descriptions (OpenAI) ---
            $group->get('/listings/{id}/description', [new ListingController(), 'generateDescription'])
                  ->add(new TenantMiddleware($pdo))
                  ->add(new AuthMiddleware(['admin', 'manager', 'viewer']));

            $group->post('/listings/{id}/description/invalidate', [new ListingController(), 'invalidateDescription'])
                  ->add(new TenantMiddleware($pdo))
                  ->add(new AuthMiddleware(['admin', 'manager']));

            // --- Payments (auth + tenant) ---
            $group->post('/payments/initiate', [$paymentController, 'initiate'])
                  ->add(new TenantMiddleware($pdo))
                  ->add(new AuthMiddleware(['admin', 'manager']));

            $group->get('/payments/{orderId}', [$paymentController, 'status'])
                  ->add(new TenantMiddleware($pdo))
                  ->add(new AuthMiddleware(['admin', 'manager']));

            // --- Inquiries (auth + tenant) ---
            $group->get('/inquiries', [$inquiryController, 'list'])
                  ->add(new TenantMiddleware($pdo))
                  ->add(new AuthMiddleware(['admin', 'manager', 'viewer']));

            $group->get('/inquiries/{id}', [$inquiryController, 'get'])
                  ->add(new TenantMiddleware($pdo))
                  ->add(new AuthMiddleware(['admin', 'manager', 'viewer']));

            $group->patch('/inquiries/{id}', [$inquiryController, 'update'])
                  ->add(new TenantMiddleware($pdo))
                  ->add(new AuthMiddleware(['admin', 'manager']));

            // --- Tenant profile + subscription state ---
            $group->get('/tenant/me', [new TenantController(), 'me'])
                  ->add(new TenantMiddleware($pdo))
                  ->add(new AuthMiddleware(['admin', 'manager', 'viewer']));
        });
    }
}
