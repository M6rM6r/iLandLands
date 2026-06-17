<?php
header('Content-Type: application/json');
$allowedOrigins = [
    'https://gulflands.com',
    'https://www.gulflands.com',
    'https://ilandlands.web.app',
    'https://ilandlands.firebaseapp.com',
    'https://*.lovable.app',
    'https://*.lovableproject.com',
    'https://*.bolt.new',
    'http://localhost:3000',
    'http://localhost:5173',
    'http://localhost:8080',
];
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
$matchedOrigin = 'https://gulflands.com';
foreach ($allowedOrigins as $ao) {
    if ($ao === $origin) {
        $matchedOrigin = $origin;
        break;
    }
    if (str_contains($ao, '*')) {
        $pattern = str_replace('\\*', '.*', preg_quote($ao, '/'));
        if (preg_match('/^' . $pattern . '$/', $origin)) {
            $matchedOrigin = $origin;
            break;
        }
    }
}
header('Access-Control-Allow-Origin: ' . $matchedOrigin);
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Credentials: true');

// Security headers
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');
header('X-XSS-Protection: 1; mode=block');
header('Strict-Transport-Security: max-age=31536000; includeSubDomains');
header('Content-Security-Policy: default-src \'self\'');
header('Referrer-Policy: strict-origin-when-cross-origin');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/database.php';
require_once '../models/LandListing.php';
require_once '../controllers/LandController.php';
require_once '../controllers/AuthController.php';
require_once '../controllers/PaymentController.php';
require_once '../controllers/InquiryController.php';
require_once '../middleware/CorsMiddleware.php';
require_once '../middleware/RateLimitMiddleware.php';
require_once '../middleware/JwtAuthMiddleware.php';
require_once '../middleware/TenantMiddleware.php';

require_once '../controllers/WebhookController.php';
require_once '../services/SignatureVerifier.php';
require_once '../services/QueueStore.php';
require_once '../services/PayTabsService.php';
require_once '../services/TelrPaymentService.php';

// Apply middleware (order matters: CORS → rate-limit → auth → tenant)
CorsMiddleware::handle();
RateLimitMiddleware::handle();
JwtAuthMiddleware::handle();

$database = new Database();
$db = $database->getConnection();

TenantMiddleware::handle($db);

$landController = new LandController($db);

// Get the request path
$requestUri = $_SERVER['REQUEST_URI'];
$requestPath = parse_url($requestUri, PHP_URL_PATH);
$pathParts = explode('/', trim($requestPath, '/'));

// Remove 'api' and 'v1' from path parts
if (count($pathParts) >= 2 && $pathParts[0] === 'api' && $pathParts[1] === 'v1') {
    $pathParts = array_slice($pathParts, 2);
}

try {
    $endpoint   = $pathParts[0] ?? '';
    $id         = $pathParts[1] ?? null;
    $action     = $pathParts[2] ?? null;
    $subAction  = $pathParts[3] ?? null;

    $authController    = new AuthController($db);
    $paymentController = new PaymentController($db);
    $inquiryController = new InquiryController($db);

    switch ($endpoint) {
        // --- Authentication (public) ---
        case 'auth':
            $action = $pathParts[1] ?? '';
            if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
                break;
            }
            match ($action) {
                'register' => $authController->register(),
                'login'    => $authController->login(),
                'refresh'  => $authController->refresh(),
                default    => (function () {
                    http_response_code(404);
                    echo json_encode(['error' => 'Unknown auth action']);
                })()
            };
            break;

        case 'land-listings':
            if ($_SERVER['REQUEST_METHOD'] === 'GET') {
                if ($id) {
                    if ($action === 'description') {
                        // GET /api/v1/land-listings/{id}/description — auth required
                        if (empty($_REQUEST['_auth_user'])) {
                            http_response_code(401);
                            echo json_encode(['error' => 'Authentication required']);
                            break;
                        }
                        http_response_code(200);
                        echo json_encode($landController->generateDescription($id));
                    } else {
                        // Get specific listing
                        echo json_encode($landController->getListing($id));
                    }
                } elseif ($action === 'featured') {
                    // Get featured listings
                    echo json_encode($landController->getFeaturedListings());
                } else {
                    // Get all listings with filters
                    echo json_encode($landController->getListings($_GET));
                }
            } elseif ($_SERVER['REQUEST_METHOD'] === 'POST' && $id && $action === 'description' && $subAction === 'invalidate') {
                // POST /api/v1/land-listings/{id}/description/invalidate — admin/manager
                if (empty($_REQUEST['_auth_user'])) {
                    http_response_code(401);
                    echo json_encode(['error' => 'Authentication required']);
                    break;
                }
                http_response_code(200);
                echo json_encode($landController->invalidateDescription($id));
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;

        case 'favorites':
            if ($_SERVER['REQUEST_METHOD'] === 'POST') {
                echo json_encode($landController->addToFavorites());
            } elseif ($_SERVER['REQUEST_METHOD'] === 'GET') {
                echo json_encode($landController->getFavorites());
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;

        case 'favorites':
            if ($_SERVER['REQUEST_METHOD'] === 'DELETE' && $id) {
                echo json_encode($landController->removeFromFavorites($id));
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;

        case 'search':
            if ($_SERVER['REQUEST_METHOD'] === 'GET') {
                echo json_encode($landController->searchListings($_GET));
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;

        case 'analytics':
            if ($_SERVER['REQUEST_METHOD'] === 'POST') {
                echo json_encode($landController->trackAnalytics($_POST));
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;

        // --- Payments (Telr) ---
        case 'payments':
            $sub = $pathParts[1] ?? '';
            $paymentMethod = $_SERVER['REQUEST_METHOD'];

            // Telr server-to-server callback — NOT auth-gated
            if ($sub === 'callback' && $paymentMethod === 'POST') {
                $paymentController->callback();
                break;
            }

            // Browser redirects after payment — NOT auth-gated
            if ($sub === 'return' && $paymentMethod === 'GET') {
                $paymentController->returnRedirect();
                break;
            }
            if ($sub === 'cancel' && $paymentMethod === 'GET') {
                $paymentController->cancelRedirect();
                break;
            }

            // Auth-gated routes below
            if (empty($_REQUEST['_auth_user'])) {
                http_response_code(401);
                echo json_encode(['error' => 'Authentication required']);
                break;
            }

            if ($sub === 'initiate' && $paymentMethod === 'POST') {
                $paymentController->initiate();
            } elseif ($sub !== '' && $paymentMethod === 'GET') {
                // GET /api/v1/payments/{orderId}
                $paymentController->status($sub);
            } else {
                http_response_code(404);
                echo json_encode(['error' => 'Payment endpoint not found']);
            }
            break;

        // --- Inquiries (contact leads) ---
        case 'inquiries':
            $method = $_SERVER['REQUEST_METHOD'];
            $subId  = $pathParts[1] ?? '';

            // POST — public (rate-limited by middleware)
            if ($method === 'POST' && $subId === '') {
                $inquiryController->create();
                break;
            }

            // Auth-gated routes below
            if (empty($_REQUEST['_auth_user'])) {
                http_response_code(401);
                echo json_encode(['error' => 'Authentication required']);
                break;
            }

            if ($method === 'GET' && $subId === '') {
                $inquiryController->list();
            } elseif ($method === 'GET' && $subId !== '') {
                $inquiryController->get($subId);
            } elseif ($method === 'PATCH' && $subId !== '') {
                $inquiryController->update($subId);
            } else {
                http_response_code(405);
                echo json_encode(['error' => 'Method not allowed']);
            }
            break;

        // --- Webhooks (signature-verified, no auth middleware) ---
        case 'webhooks':
            $webhookController = new WebhookController();
            $sub    = $pathParts[1] ?? '';
            $method = $_SERVER['REQUEST_METHOD'];

            if ($sub === 'whatsapp') {
                if ($method === 'GET') {
                    $webhookController->whatsappVerify();
                } elseif ($method === 'POST') {
                    $webhookController->whatsappInbound();
                } else {
                    http_response_code(405);
                    echo json_encode(['error' => 'Method not allowed']);
                }
            } elseif ($sub === 'paytabs' && $method === 'POST') {
                $webhookController->paytabsCallback();
            } else {
                http_response_code(404);
                echo json_encode(['error' => 'Unknown webhook']);
            }
            break;

        default:
            http_response_code(404);
            echo json_encode(['error' => 'Endpoint not found']);
            break;
    }
} catch (Exception $e) {
    error_log('API Error: ' . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'error' => 'Internal server error',
        'message' => 'An unexpected error occurred'
    ]);
}
?>
