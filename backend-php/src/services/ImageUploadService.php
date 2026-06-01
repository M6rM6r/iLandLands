<?php

namespace App\Services;

/**
 * ImageUploadService — validates, resizes, and converts listing images (Slim 4).
 *
 * @see backend/services/ImageUploadService.php for the vanilla-PHP counterpart.
 *
 * Requirements:
 *   - PHP GD extension with WebP support, OR Imagick extension
 *   - UPLOAD_DIR env var (default /var/www/html/storage/uploads)
 *   - APP_BASE_URL env var (default http://localhost)
 */
class ImageUploadService
{
    private const ALLOWED_MIMES   = ['image/jpeg', 'image/png', 'image/webp'];
    private const MAX_SIZE_BYTES  = 5 * 1024 * 1024;
    private const DEFAULT_WIDTH   = 1920;
    private const DEFAULT_QUALITY = 85;

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
     * Process an uploaded file from a PSR-7 UploadedFileInterface.
     *
     * @param  \Psr\Http\Message\UploadedFileInterface $upload
     * @param  int $maxWidth
     * @param  int $quality
     * @return array{filename: string, path: string, url: string, size: int}
     * @throws \RuntimeException
     */
    public function processUpload(
        \Psr\Http\Message\UploadedFileInterface $upload,
        int $maxWidth  = self::DEFAULT_WIDTH,
        int $quality   = self::DEFAULT_QUALITY
    ): array {
        if ($upload->getError() !== UPLOAD_ERR_OK) {
            throw new \RuntimeException('Upload error code: ' . $upload->getError());
        }

        if ($upload->getSize() > self::MAX_SIZE_BYTES) {
            throw new \RuntimeException(
                'File size exceeds limit of ' . (self::MAX_SIZE_BYTES / 1024 / 1024) . ' MB'
            );
        }

        $stream = $upload->getStream();
        $stream->rewind();
        $header = $stream->read(12);
        $this->validateMagicBytes($header);
        $this->validateMimeType($upload->getClientMediaType() ?? '');

        // Write to temp file for GD/Imagick processing
        $tmpPath = tempnam(sys_get_temp_dir(), 'glfup_');
        if ($tmpPath === false) {
            throw new \RuntimeException('Failed to create temporary file');
        }

        try {
            $stream->rewind();
            file_put_contents($tmpPath, (string) $stream);

            $outputFilename = bin2hex(random_bytes(16)) . '.webp';
            $outputPath     = $this->uploadDir . '/' . $outputFilename;

            $this->convertToWebP($tmpPath, $outputPath, $maxWidth, $quality);
        } finally {
            @unlink($tmpPath);
        }

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
     * Delete a previously stored upload by filename (basename only — prevents path traversal).
     */
    public function deleteUpload(string $filename): void
    {
        $safe = basename($filename);
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

        if (count($b) >= 3 && $b[0] === 0xFF && $b[1] === 0xD8 && $b[2] === 0xFF) {
            return; // JPEG
        }
        if (count($b) >= 4 && $b[0] === 0x89 && $b[1] === 0x50 && $b[2] === 0x4E && $b[3] === 0x47) {
            return; // PNG
        }
        if (
            count($b) >= 12 &&
            $b[0] === 0x52 && $b[1] === 0x49 && $b[2] === 0x46 && $b[3] === 0x46 &&
            $b[8] === 0x57 && $b[9] === 0x45 && $b[10] === 0x42 && $b[11] === 0x50
        ) {
            return; // WebP
        }

        throw new \RuntimeException('Invalid image file (magic byte mismatch)');
    }

    private function validateMimeType(string $clientMime): void
    {
        if (!in_array(strtolower($clientMime), self::ALLOWED_MIMES, true)) {
            throw new \RuntimeException('Only JPEG, PNG, and WebP images are allowed');
        }
    }

    private function convertToWebP(string $src, string $dest, int $maxWidth, int $quality): void
    {
        if (extension_loaded('imagick')) {
            $this->convertWithImagick($src, $dest, $maxWidth, $quality);
        } elseif (extension_loaded('gd')) {
            $this->convertWithGD($src, $dest, $maxWidth, $quality);
        } else {
            throw new \RuntimeException('Neither Imagick nor GD extension is available');
        }
    }

    private function convertWithGD(string $src, string $dest, int $maxWidth, int $quality): void
    {
        $info = @getimagesize($src);
        if ($info === false) {
            throw new \RuntimeException('Cannot read image dimensions');
        }

        [$origW, $origH, $type] = $info;

        $img = match ($type) {
            IMAGETYPE_JPEG => imagecreatefromjpeg($src),
            IMAGETYPE_PNG  => imagecreatefrompng($src),
            IMAGETYPE_WEBP => imagecreatefromwebp($src),
            default        => false,
        };

        if ($img === false) {
            throw new \RuntimeException('GD could not load image');
        }

        if ($origW > $maxWidth) {
            $newH    = (int) round($origH * $maxWidth / $origW);
            $resized = imagecreatetruecolor($maxWidth, $newH);
            imagecopyresampled($resized, $img, 0, 0, 0, 0, $maxWidth, $newH, $origW, $origH);
            imagedestroy($img);
            $img = $resized;
        }

        if (!imagewebp($img, $dest, $quality)) {
            imagedestroy($img);
            throw new \RuntimeException('GD WebP conversion failed');
        }

        imagedestroy($img);
    }

    private function convertWithImagick(string $src, string $dest, int $maxWidth, int $quality): void
    {
        $im = new \Imagick($src);
        $im->stripImage();
        if ($im->getImageWidth() > $maxWidth) {
            $im->resizeImage($maxWidth, 0, \Imagick::FILTER_LANCZOS, 1);
        }
        $im->setImageFormat('WEBP');
        $im->setImageCompressionQuality($quality);
        $im->writeImage($dest);
        $im->destroy();
    }
}
