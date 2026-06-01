<?php

namespace App\Services;

/**
 * HubSpotService (Slim 4 / PSR context).
 *
 * @see backend/services/HubSpotService.php for the vanilla-PHP counterpart.
 *
 * Environment variables required:
 *   HUBSPOT_ACCESS_TOKEN — Private App access token from HubSpot portal
 *
 * Private App scopes needed:
 *   crm.objects.contacts.read, crm.objects.contacts.write,
 *   crm.objects.deals.read,    crm.objects.deals.write,
 *   crm.objects.associations.write
 */
class HubSpotService
{
    private const API_BASE = 'https://api.hubapi.com';

    private string $token;

    public function __construct()
    {
        $this->token = (string) (getenv('HUBSPOT_ACCESS_TOKEN') ?: '');
    }

    // =========================================================================
    // Contacts
    // =========================================================================

    /**
     * Create or update a HubSpot contact (idempotent by email).
     *
     * @param array $user {
     *   'email'   => string,
     *   'id'      => string|null,
     *   'country' => string|null,
     *   'phone'   => string|null,
     *   'name'    => string|null,
     * }
     * @return string|null HubSpot contact ID or null on failure.
     */
    public function upsertContact(array $user): ?string
    {
        if (!FeatureFlags::isEnabled('HUBSPOT_SYNC')) {
            return null;
        }

        if ($this->token === '') {
            error_log('HubSpotService: HUBSPOT_ACCESS_TOKEN not configured.');
            return null;
        }

        [$firstName, $lastName] = $this->splitName($user['name'] ?? '');

        $properties = array_filter([
            'email'             => filter_var($user['email'] ?? '', FILTER_SANITIZE_EMAIL),
            'firstname'         => $firstName,
            'lastname'          => $lastName,
            'phone'             => $user['phone'] ?? null,
            'country'           => $this->mapCountryLabel($user['country'] ?? ''),
            'gulflands_user_id' => (string) ($user['id'] ?? ''),
        ], static fn ($v) => $v !== null && $v !== '');

        $existingId = $this->findContactByEmail((string) ($user['email'] ?? ''));

        try {
            if ($existingId !== null) {
                $this->patch("/crm/v3/objects/contacts/{$existingId}", ['properties' => $properties]);
                return $existingId;
            }

            $response = $this->post('/crm/v3/objects/contacts', ['properties' => $properties]);
            return (string) ($response['id'] ?? '');
        } catch (\RuntimeException $e) {
            error_log('HubSpotService upsertContact error: ' . $e->getMessage());
            return null;
        }
    }

    // =========================================================================
    // Deals
    // =========================================================================

    /**
     * Create a HubSpot Deal for a new inquiry and associate with Contact.
     *
     * @param array $inquiry {
     *   'name'       => string,
     *   'email'      => string,
     *   'phone'      => string|null,
     *   'message'    => string,
     *   'land_title' => string,
     *   'land_id'    => string|null,
     *   'tenant_id'  => string,
     * }
     * @return string|null HubSpot deal ID or null on failure.
     */
    public function createInquiryDeal(array $inquiry): ?string
    {
        if (!FeatureFlags::isEnabled('HUBSPOT_SYNC')) {
            return null;
        }

        if ($this->token === '') {
            error_log('HubSpotService: HUBSPOT_ACCESS_TOKEN not configured.');
            return null;
        }

        $contactId = $this->upsertContact([
            'email' => $inquiry['email'],
            'name'  => $inquiry['name'],
            'phone' => $inquiry['phone'] ?? null,
        ]);

        $dealName   = 'Inquiry: ' . substr((string) $inquiry['land_title'], 0, 100);
        $properties = array_filter([
            'dealname'            => $dealName,
            'pipeline'            => 'default',
            'dealstage'           => 'appointmentscheduled',
            'description'         => substr((string) $inquiry['message'], 0, 1000),
            'gulflands_land_id'   => (string) ($inquiry['land_id']   ?? ''),
            'gulflands_tenant_id' => (string) ($inquiry['tenant_id'] ?? ''),
        ], static fn ($v) => $v !== null && $v !== '');

        try {
            $deal   = $this->post('/crm/v3/objects/deals', ['properties' => $properties]);
            $dealId = (string) ($deal['id'] ?? '');

            if ($dealId !== '' && $contactId !== null && $contactId !== '') {
                $this->put(
                    "/crm/v4/objects/deals/{$dealId}/associations/default/contacts/{$contactId}",
                    []
                );
            }

            return $dealId !== '' ? $dealId : null;
        } catch (\RuntimeException $e) {
            error_log('HubSpotService createInquiryDeal error: ' . $e->getMessage());
            return null;
        }
    }

    // =========================================================================
    // Private helpers
    // =========================================================================

    private function findContactByEmail(string $email): ?string
    {
        if ($email === '') {
            return null;
        }

        try {
            $payload  = [
                'filterGroups' => [[
                    'filters' => [[
                        'propertyName' => 'email',
                        'operator'     => 'EQ',
                        'value'        => $email,
                    ]],
                ]],
                'properties' => ['email'],
                'limit'      => 1,
            ];
            $response = $this->post('/crm/v3/objects/contacts/search', $payload);
            $results  = $response['results'] ?? [];

            return !empty($results[0]['id']) ? (string) $results[0]['id'] : null;
        } catch (\RuntimeException $e) {
            error_log('HubSpotService findContactByEmail error: ' . $e->getMessage());
            return null;
        }
    }

    private function post(string $path, array $payload): array
    {
        return $this->request('POST', $path, $payload);
    }

    private function patch(string $path, array $payload): array
    {
        return $this->request('PATCH', $path, $payload);
    }

    private function put(string $path, array $payload): array
    {
        return $this->request('PUT', $path, $payload);
    }

    private function request(string $method, string $path, array $payload): array
    {
        $url = self::API_BASE . $path;

        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_CUSTOMREQUEST  => $method,
            CURLOPT_POSTFIELDS     => json_encode($payload, JSON_THROW_ON_ERROR),
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 15,
            CURLOPT_SSL_VERIFYPEER => true,
            CURLOPT_SSL_VERIFYHOST => 2,
            CURLOPT_HTTPHEADER     => [
                'Content-Type: application/json',
                'Authorization: Bearer ' . $this->token,
            ],
        ]);

        $body   = curl_exec($ch);
        $errno  = curl_errno($ch);
        $error  = curl_error($ch);
        $status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($errno !== 0) {
            throw new \RuntimeException("cURL error ($errno): $error");
        }

        if ($status === 204) {
            return [];
        }

        $decoded = json_decode((string) $body, true, 512, JSON_THROW_ON_ERROR);

        if ($status >= 400) {
            $msg = $decoded['message'] ?? "HTTP $status";
            throw new \RuntimeException("HubSpot API error ($status): $msg");
        }

        return is_array($decoded) ? $decoded : [];
    }

    /** @return string[] */
    private function splitName(string $fullName): array
    {
        $parts = array_filter(explode(' ', trim($fullName)));
        if (empty($parts)) {
            return ['', ''];
        }
        $first = array_shift($parts);
        $last  = implode(' ', $parts);
        return [$first, $last];
    }

    private function mapCountryLabel(string $slug): string
    {
        return match ($slug) {
            'saudiArabia' => 'Saudi Arabia',
            'uae'         => 'UAE',
            'qatar'       => 'Qatar',
            'bahrain'     => 'Bahrain',
            'oman'        => 'Oman',
            'kuwait'      => 'Kuwait',
            default       => $slug,
        };
    }
}
