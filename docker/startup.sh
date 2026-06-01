#!/bin/sh
set -e

# Run database migrations if DB is available
if [ -n "$DB_HOST" ]; then
    echo "Waiting for MySQL at $DB_HOST:${DB_PORT:-3306}..."
    for i in $(seq 1 30); do
        if mysqladmin ping -h"$DB_HOST" -P"${DB_PORT:-3306}" -u"$DB_USER" -p"$DB_PASSWORD" --silent 2>/dev/null; then
            echo "MySQL ready."
            break
        fi
        echo "  attempt $i/30..."
        sleep 2
    done

    # Run migrations
    if [ -d "/var/www/html/database/migrations" ]; then
        for f in /var/www/html/database/migrations/*.sql; do
            echo "Running migration: $f"
            mysql -h"$DB_HOST" -P"${DB_PORT:-3306}" -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "$f" 2>/dev/null || true
        done
    fi
fi

# Ensure upload/storage directories exist and are writable
mkdir -p "${UPLOAD_DIR:-/var/www/html/storage/uploads}"
mkdir -p "${QUEUE_DIR:-/var/data/queues}"
chmod -R 775 "${UPLOAD_DIR:-/var/www/html/storage/uploads}" || true
chmod -R 775 "${QUEUE_DIR:-/var/data/queues}" || true

# Ensure log directories exist
mkdir -p /var/log/php /var/log/nginx /var/log/supervisor

# Start supervisor (manages nginx + php-fpm)
exec supervisord -c /etc/supervisor/conf.d/supervisord.conf
