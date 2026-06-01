<?php

/**
 * ImageUploadService — validates, resizes, and converts listing images.
 *
 * Ported from Rew/lib/upload.ts (sharp → GD/Imagick).
 * Validates magic bytes (never trusts Content-Type alone), enforces 5 MB max,
 * and outputs lossless-compatible WebP at configurable quality/dimensions.
 *
 * Requirements:
 *   - PHP GD extension with WebP support (--with-webp), OR Imagick extension
 *   - Storage: configurable via UPLOAD_DIR env var (default /var/www/html/storage/uploads)
 *
 * @see backend-php/src/services/ImageUploadService.php for the Slim 4 counterpart.
 */
class ImageUploadService
{
    private const ALLOWED_MIMES  = ['image/jpeg', 'image/png', 'image/webp'];
    private const MAX_SIZE_BYTES = 5 * 1024 * 1024; // 5 MB
    private const DEFAULT_WIDTH  = 1920;
    private const DEFAULT_QUALITY = 85;

    // Magic byte signatures
    private const MAGIC_JPEG = [0xFF, 0xD8, 0xFF];
    private const MAGIC_PNG  = [0x89, 0x50, 0x4E, 0x47];
    private const MAGIC_WEBP_RIFF = [0x52, 0x49, 0x46, 0x46]; // RIFF
    private const MAGIC_WEBP_TAG  = [0x57, 0x45, 0x42, 0x50]; // WEBP at offset 8

    private string $uploadDir;

    public function __construct()
    {
        $this->uploadDir = rtrim((string) (getenv('UPLOAD_DIR') ?: '/var/www/html/storage/uploads'), '/');
        if (!is_dir($this->uploadDir)) {
            mkdir($this->uploadDir, 0750, true);
        }
    }

    // -------------------------------------------------------------------------
    // Public API
    // -------------------------------------------------------------------------

    /**
     * Validate and process an uploaded file (from $_FILES entry or raw bytes).
     *
     * @param  array  $file       $_FILES-style array: ['tmp_name', 'size', 'type', 'name']
     * @param  int    $maxWidth   Resize to fit within this width (preserves ratio)
     * @param  int    $quality    WebP quality 1–100
     * @return array{filename: string, path: string, url: string, size: int}
     * @throws RuntimeException on validation or conversion failure
     */
    public function processUpload(
        array $file,
        int   $maxWidth  = self::DEFAULT_WIDTH,
        int   $quality   = self::DEFAULT_QUALITY
    ): array {
        $tmpPath = (string) ($file['tmp_name'] ?? '');
        $size    = (int)    ($file['size']     ?? 0);

        if ($tmpPath === '' || !is_uploaded_file($tmpPath)) {
            throw new RuntimeException('No valid uploaded file provided');
        }

        if ($size > self::MAX_SIZE_BYTES) {
            throw new RuntimeException(
                'File size exceeds limit of ' . (self::MAX_SIZE_BYTES / 1024 / 1024) . ' MB'
            );
        }

        $bytes = file_get_contents($tmpPath, false, null, 0, 12);
        if ($bytes === false) {
            throw new RuntimeException('Cannot read uploaded file');
        }

        $this->validateMagicBytes($bytes);
        $this->validateMimeType((string) ($file['type'] ?? ''));

        $outputFilename = bin2hex(random_bytes(16)) . '.webp';
        $outputPath     = $this->uploadDir . '/' . $outputFilename;

        $this->convertToWebP($tmpPath, $outputPath, $maxWidth, $quality);

        $finalSize = (int) filesize($outputPath);
        $baseUrl   = rtrim((string) (getenv('APP_BASE_URL') ?: 'http://localhost'), '/');

        return [
            'filename' => $outputFilename,
            'path'     => $outputPath,
            'url'      => $baseUrl . '/storage/uploads/' . $outputFilename,
            'size'     => $finalSize,
        ];
    }

    /**
     * Delete a previously stored upload by filename (basename only — no path traversal).
     */
    public function deleteUpload(string $filename): void
    {
        $safe = basename($filename);
        // Only allow hex.webp pattern from our own processUpload
        if (!preg_match('/^[0-9a-f]{32}\.webp$/i', $safe)) {
            error_log('[ImageUploadService] deleteUpload: rejected filename ' . $safe);
            return;
        }

        $path = $this->uploadDir . '/' . $safe;
        if (file_exists($path)) {
            unlink($path);
        }
    }

    // -------------------------------------------------------------------------
    // Internal
    // -------------------------------------------------------------------------

    private function validateMagicBytes(string $bytes): void
    {
        $b = array_values(unpack('C*', $bytes) ?: []);

        // JPEG: FF D8 FF
        if (count($b) >= 3 && $b[0] === 0xFF && $b[1] === 0xD8 && $b[2] === 0xFF) {
            return;
        }

        // PNG: 89 50 4E 47
        if (count($b) >= 4 && $b[0] === 0x89 && $b[1] === 0x50 && $b[2] === 0x4E && $b[3] === 0x47) {
            return;
        }

        // WebP: RIFF????WEBP
        if (
            count($b) >= 12 &&
            $b[0] === 0x52 && $b[1] === 0x49 && $b[2] === 0x46 && $b[3] === 0x46 &&
            $b[8] === 0x57 && $b[9] === 0x45 && $b[10] === 0x42 && $b[11] === 0x50
        ) {
            return;
        }

        throw new RuntimeException('Invalid image file (magic byte mismatch)');
    }

    private function validateMimeType(string $clientMime): void
    {
        if (!in_array(strtolower($clientMime), self::ALLOWED_MIMES, true)) {
            throw new RuntimeException('Only JPEG, PNG, and WebP images are allowed');
        }
    }

    private function convertToWebP(string $src, string $dest, int $maxWidth, int $quality): void
    {
        if (extension_loaded('imagick')) {
            $this->convertWithImagick($src, $dest, $maxWidth, $quality);
        } elseif (extension_loaded('gd')) {
            $this->convertWithGD($src, $dest, $maxWidth, $quality);
        } else {
            throw new RuntimeException('Neither Imagick nor GD extension is available');
        }
    }

    private function convertWithGD(string $src, string $dest, int $maxWidth, int $quality): void
    {
        $info = @getimagesize($src);
        if ($info === false) {
            throw new RuntimeException('Cannot read image dimensions');
        }

        [$origW, $origH, $type] = $info;

        $img = match ($type) {
            IMAGETYPE_JPEG => imagecreatefromjpeg($src),
            IMAGETYPE_PNG  => imagecreatefrompng($src),
            IMAGETYPE_WEBP => imagecreatefromwebp($src),
            default        => false,
        };

        if ($img === false) {
            throw new RuntimeException('GD could not load image');
        }

        // Resize if wider than $maxWidth
        if ($origW > $maxWidth) {
            $newH  = (int) round($origH * $maxWidth / $origW);
            $resized = imagecreatetruecolor($maxWidth, $newH);
            imagecopyresampled($resized, $img, 0, 0, 0, 0, $maxWidth, $newH, $origW, $origH);
            imagedestroy($img);
            $img = $resized;
        }

        if (!imagewebp($img, $dest, $quality)) {
            imagedestroy($img);
            throw new RuntimeException('GD WebP conversion failed');
        }

        imagedestroy($img);
    }

    private function convertWithImagick(string $src, string $dest, int $maxWidth, int $quality): void
    {
        $im = new \Imagick($src);
        $im->stripImage(); // remove EXIF / metadata
        [$origW] = [$im->getImageWidth()];
        if ($origW > $maxWidth) {
            $im->resizeImage($maxWidth, 0, \Imagick::FILTER_LANCZOS, 1);
        }
        $im->setImageFormat('WEBP');
        $im->setImageCompressionQuality($quality);
        $im->writeImage($dest);
        $im->destroy();
    }
}
