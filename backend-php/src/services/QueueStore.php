<?php

namespace App\Services;

/**
 * QueueStore — file-based webhook event queue with dead-letter support (Slim 4).
 *
 * Ported from Rew (realestate-saas) services/php-webhooks/src/QueueStore.php.
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

    /**
     * @param  array<string,mixed> $event
     * @return string  Event ID (hex)
     */
    public function enqueue(array $event): string
    {
        $id = $event['id'] ?? bin2hex(random_bytes(12));
        $event['id']         = $id;
        $event['attempts']   = $event['attempts'] ?? 0;
        $event['created_at'] = $event['created_at'] ?? gmdate('c');

        $path = $this->queueDir . \DIRECTORY_SEPARATOR . $id . '.json';
        file_put_contents($path, json_encode($event, \JSON_THROW_ON_ERROR), \LOCK_EX);

        return $id;
    }

    /**
     * @return array<int,array<string,mixed>>
     */
    public function pending(): array
    {
        $events = [];
        foreach (glob($this->queueDir . \DIRECTORY_SEPARATOR . '*.json') ?: [] as $file) {
            $content = file_get_contents($file);
            if ($content === false) continue;
            $payload = json_decode($content, true);
            if (is_array($payload)) {
                $payload['_file'] = $file;
                $events[] = $payload;
            }
        }
        usort($events, fn($a, $b) => strcmp($a['created_at'] ?? '', $b['created_at'] ?? ''));
        return $events;
    }

    public function ack(string $filePath): void
    {
        if (is_file($filePath)) {
            @unlink($filePath);
        }
    }

    /**
     * @param array<string,mixed> $event
     */
    public function nack(array $event, string $reason): void
    {
        $filePath = $event['_file'] ?? null;
        unset($event['_file']);

        $event['attempts']      = (int) ($event['attempts'] ?? 0) + 1;
        $event['last_error']    = $reason;
        $event['last_error_at'] = gmdate('c');

        if ($event['attempts'] >= self::MAX_ATTEMPTS) {
            $this->deadLetter($event, $reason);
            if ($filePath && is_file($filePath)) {
                @unlink($filePath);
            }
            return;
        }

        if ($filePath && is_file($filePath)) {
            file_put_contents($filePath, json_encode($event, \JSON_THROW_ON_ERROR), \LOCK_EX);
        }
    }

    /**
     * @param array<string,mixed> $event
     */
    public function deadLetter(array $event, string $reason): void
    {
        unset($event['_file']);
        $event['dead_letter_reason'] = $reason;
        $event['dead_letter_at']     = gmdate('c');
        $id = $event['id'] ?? bin2hex(random_bytes(12));

        file_put_contents(
            $this->deadLetterDir . \DIRECTORY_SEPARATOR . $id . '.json',
            json_encode($event, \JSON_THROW_ON_ERROR),
            \LOCK_EX
        );
    }

    /**
     * @return array<int,array<string,mixed>>
     */
    public function deadLetterItems(): array
    {
        $events = [];
        foreach (glob($this->deadLetterDir . \DIRECTORY_SEPARATOR . '*.json') ?: [] as $file) {
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

    private static function ensureDir(string $path): void
    {
        if (!is_dir($path)) {
            mkdir($path, 0750, true);
        }
    }
}
