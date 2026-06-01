# Multi-stage Docker build for Gulf Lands application
# Stage 1: PHP Backend
FROM php:8.2-fpm-alpine AS backend

# Install system dependencies
RUN apk add --no-cache \
    nginx \
    supervisor \
    mysql-client \
    redis \
    curl \
    zip \
    unzip \
    git \
    composer

# Install PHP extensions
RUN docker-php-ext-install \
    pdo_mysql \
    mysqli \
    json \
    mbstring \
    tokenizer \
    bcmath \
    ctype \
    fileinfo \
    simplexml \
    xml \
    dom \
    intl \
    opcache

# Install Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Configure PHP
RUN echo "memory_limit=512M" > /usr/local/etc/php/conf.d/memory-limit.ini && \
    echo "opcache.enable=1" > /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.memory_consumption=256" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.interned_strings_buffer=8" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.max_accelerated_files=10000" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "upload_max_filesize=10M" > /usr/local/etc/php/conf.d/upload.ini && \
    echo "post_max_size=10M" >> /usr/local/etc/php/conf.d/upload.ini

# Set working directory
WORKDIR /var/www/html

# Copy backend files
COPY backend/ .

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Set permissions
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html && \
    mkdir -p /var/www/html/storage/logs && \
    chown -R www-data:www-data /var/www/html/storage

# Copy Nginx configuration
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/default.conf /etc/nginx/conf.d/default.conf

# Copy Supervisor configuration
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose ports
EXPOSE 80

# Start services
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Stage 2: Flutter Web Frontend
FROM ghcr.io/cirruslabs/flutter:stable AS frontend

WORKDIR /app

# Copy Flutter files
COPY lib/ ./lib/
COPY pubspec.yaml pubspec.lock ./
COPY web/ ./web/

# Install Flutter dependencies
RUN flutter pub get --no-example

# Generate JSON serialization code (ignore if no build_runner targets)
RUN dart run build_runner build --delete-conflicting-outputs 2>/dev/null || true

# Build web application
RUN flutter config --enable-web && \
    flutter build web --release --no-tree-shake-icons

# Stage 3: Final combined application — reuse backend base so PHP-FPM is available
FROM php:8.2-fpm-alpine AS final

# Re-install runtime dependencies needed in the final image
RUN apk add --no-cache nginx supervisor curl mysql-client

# Re-install PHP extensions
RUN docker-php-ext-install pdo_mysql mysqli opcache
RUN pecl install redis && docker-php-ext-enable redis

# Configure PHP
RUN echo "memory_limit=512M" > /usr/local/etc/php/conf.d/memory-limit.ini && \
    echo "opcache.enable=1" > /usr/local/etc/php/conf.d/opcache.ini && \
    echo "upload_max_filesize=16M" > /usr/local/etc/php/conf.d/upload.ini && \
    echo "post_max_size=16M" >> /usr/local/etc/php/conf.d/upload.ini

# Copy backend from stage 1
COPY --from=backend /var/www/html /var/www/html
COPY --from=backend /usr/local/etc/php /usr/local/etc/php

# Copy Flutter web build
COPY --from=frontend /app/build/web /var/www/html/web

# Nginx + Supervisor configuration
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/final.conf /etc/nginx/http.d/default.conf
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Startup script
COPY docker/startup.sh /startup.sh
RUN chmod +x /startup.sh

# Storage directories
RUN mkdir -p /var/www/html/storage/uploads /var/data/queues \
             /var/log/php /var/log/nginx /var/log/supervisor && \
    chown -R www-data:www-data /var/www/html/storage /var/data/queues

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost/api/v1/health || exit 1

CMD ["/startup.sh"]
