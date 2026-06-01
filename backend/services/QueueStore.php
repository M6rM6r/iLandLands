<?php
/**
 * QueueStore — file-based webhook event queue with dead-letter support.
 *
 * Ported from Rew (realestate-saas) services/php-webhooks/src/QueueStore.php.
 *
 * Events are stored as JSON files in $queueDir.
 * After MAX_ATTEMPTS failures the event is moved to $deadLetterDir.
 *
 * Usage:
 *   $store = new QueueStore(
 *       queueDir:      '/var/data/webhook-queue',
 *       deadLetterDir: '/var/data/webhook-dlq',
 *   );
 *
 *   // Enqueue on receipt
 *   $id = $store->enqueue(['source' => 'whatsapp', 'payload' => $body]);
 *
 *   // Process loop
 *   foreach ($store->pending() as $event) {
 *       try {
 *           dispatch($event);
 *           $store->ack($event['_file']);
 *       } catch (Throwable $e) {
 *           $store->nack($event, $e->getMessage());
 *       }
 *   }
 */
class QueueStore
{
    public const MAX_ATTEMPTS = 5;

    public function __construct(
        private readonly string $queueDir,
        private readonly string $deadLetterDir,
    ) {
        self::ensureDir($this->queueDir);
        self::ensureDir($this->deadLetterDir);
    }

    // ── Public API ─────────────────────────────────────────────────────────────

    /**
     * Persist a new event to the queue. Returns the assigned event ID.
     *
     * @param  array<string,mixed> $event
     * @return string  Event ID (hex)
     */
    public function enqueue(array $event): string
    {
        $id = $event['id'] ?? bin2hex(random_bytes(12));
        $event['id']         = $id;
        $event['attempts']   = $event['attempts'] ?? 0;
        $event['created_at'] = $event['created_at'] ?? gmdate('c');

        $path = $this->queueDir . DIRECTORY_SEPARATOR . $id . '.json';
        file_put_contents($path, json_encode($event, JSON_THROW_ON_ERROR), LOCK_EX);

        return $id;
    }

    /**
     * Return all pending events (sorted oldest-first).
     *
     * @return array<int,array<string,mixed>>
     */
    public function pending(): array
    {
        $events = [];
        foreach (glob($this->queueDir . DIRECTORY_SEPARATOR . '*.json') ?: [] as $file) {
            $content = file_get_contents($file);
            if ($content === false) continue;
            $payload = json_decode($content, true);
            if (is_array($payload)) {
                $payload['_file'] = $file;
                $events[] = $payload;
            }
        }
        // Process oldest-first
        usort($events, fn($a, $b) => strcmp($a['created_at'] ?? '', $b['created_at'] ?? ''));
        return $events;
    }

    /**
     * Acknowledge successful processing — remove from queue.
     */
    public function ack(string $filePath): void
    {
        if (is_file($filePath)) {
            @unlink($filePath);
        }
    }

    /**
     * Negative acknowledgement — increment attempt counter.
     * If MAX_ATTEMPTS is reached, move to dead-letter queue.
     *
     * @param array<string,mixed> $event   The event array (must contain _file key)
     * @param string              $reason  Error description for dead-letter record
     */
    public function nack(array $event, string $reason): void
    {
        $filePath = $event['_file'] ?? null;
        unset($event['_file']);

        $event['attempts'] = (int) ($event['attempts'] ?? 0) + 1;
        $event['last_error'] = $reason;
        $event['last_error_at'] = gmdate('c');

        if ($event['attempts'] >= self::MAX_ATTEMPTS) {
            $this->deadLetter($event, $reason);
            if ($filePath && is_file($filePath)) {
                @unlink($filePath);
            }
            return;
        }

        // Update in place
        if ($filePath && is_file($filePath)) {
            file_put_contents($filePath, json_encode($event, JSON_THROW_ON_ERROR), LOCK_EX);
        }
    }

    /**
     * Write directly to dead-letter queue (without counting as an attempt).
     *
     * @param array<string,mixed> $event
     * @param string              $reason
     */
    public function deadLetter(array $event, string $reason): void
    {
        unset($event['_file']);
        $event['dead_letter_reason'] = $reason;
        $event['dead_letter_at']     = gmdate('c');
        $id = $event['id'] ?? bin2hex(random_bytes(12));

        file_put_contents(
            $this->deadLetterDir . DIRECTORY_SEPARATOR . $id . '.json',
            json_encode($event, JSON_THROW_ON_ERROR),
            LOCK_EX
        );
    }

    /**
     * Return all dead-letter events.
     *
     * @return array<int,array<string,mixed>>
     */
    public function deadLetterItems(): array
    {
        $events = [];
        foreach (glob($this->deadLetterDir . DIRECTORY_SEPARATOR . '*.json') ?: [] as $file) {
            $content = file_get_contents($file);
            if ($content === false) continue;
            $payload = json_decode($content, true);
            if (is_array($payload)) {
                $payload['_file'] = $file;
                $events[] = $payload;
            }
        }
        return $events;
    }

    // ── Helpers ────────────────────────────────────────────────────────────────

    private static function ensureDir(string $path): void
    {
        if (!is_dir($path)) {
            mkdir($path, 0750, true);
        }
    }
}
