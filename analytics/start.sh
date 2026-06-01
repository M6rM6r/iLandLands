#!/bin/bash

# Analytics Service Startup Script
# This script handles the startup of the Gulf Lands Analytics service

set -e

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check if service is ready
check_ready() {
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f http://localhost:8000/health > /dev/null 2>&1; then
            log "Service is ready"
            return 0
        fi
        
        log "Waiting for service to be ready... (attempt $attempt/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done
    
    log "Service failed to become ready within expected time"
    return 1
}

# Function to run database migrations
run_migrations() {
    log "Running database migrations..."
    
    # Check if alembic is available
    if command -v alembic &> /dev/null; then
        alembic upgrade head
        log "Database migrations completed"
    else
        log "Alembic not found, skipping migrations"
    fi
}

# Function to initialize ML models
initialize_models() {
    log "Initializing ML models..."
    
    # Create models directory if it doesn't exist
    mkdir -p /app/models
    
    # Check if pre-trained models exist
    if [ ! -f "/app/models/price_model.pkl" ]; then
        log "No pre-trained models found, will train on first startup"
    else
        log "Pre-trained models found"
    fi
}

# Function to setup logging
setup_logging() {
    log "Setting up logging..."
    
    # Create logs directory
    mkdir -p /app/logs
    
    # Set log file permissions
    chmod 755 /app/logs
    
    log "Logging setup completed"
}

# Function to check dependencies
check_dependencies() {
    log "Checking dependencies..."
    
    # Check Python packages
    python -c "import fastapi, asyncpg, aioredis, pandas, numpy, sklearn" || {
        log "ERROR: Required Python packages not found"
        exit 1
    }
    
    # Check database connection
    python -c "
import asyncio
import asyncpg

async def check_db():
    try:
        conn = await asyncpg.connect('postgresql://gulflands_user:secure_password_123@mysql/gulflands')
        await conn.close()
        print('Database connection successful')
    except Exception as e:
        print(f'Database connection failed: {e}')
        exit(1)

asyncio.run(check_db())
" || {
        log "ERROR: Database connection failed"
        exit 1
    }
    
    # Check Redis connection
    python -c "
import asyncio
import aioredis

async def check_redis():
    try:
        redis = await aioredis.from_url('redis://:redis_password_123@redis:6379/0')
        await redis.ping()
        await redis.close()
        print('Redis connection successful')
    except Exception as e:
        print(f'Redis connection failed: {e}')
        exit(1)

asyncio.run(check_redis())
" || {
        log "ERROR: Redis connection failed"
        exit 1
    }
    
    log "Dependencies check completed"
}

# Function to start the application
start_app() {
    log "Starting Gulf Lands Analytics service..."
    
    # Set environment variables
    export PYTHONPATH=/app
    export LOG_LEVEL=${LOG_LEVEL:-INFO}
    export WORKERS=${WORKERS:-4}
    export HOST=${HOST:-0.0.0.0}
    export PORT=${PORT:-8000}
    
    # Start the application with uvicorn
    exec uvicorn app:app \
        --host $HOST \
        --port $PORT \
        --workers $WORKERS \
        --log-level $LOG_LEVEL \
        --access-log \
        --log-config /app/logging.conf \
        --reload
}

# Function to handle graceful shutdown
graceful_shutdown() {
    log "Received shutdown signal, gracefully shutting down..."
    
    # Send SIGTERM to uvicorn process group
    kill -TERM -$PID
    
    # Wait for processes to finish
    wait $PID
    
    log "Service stopped gracefully"
    exit 0
}

# Function to handle errors
error_handler() {
    log "ERROR: An error occurred during startup"
    exit 1
}

# Set up error handling
trap error_handler ERR
trap graceful_shutdown SIGTERM SIGINT

# Main startup sequence
main() {
    log "Starting Gulf Lands Analytics service initialization..."
    
    # Run startup checks
    setup_logging
    check_dependencies
    run_migrations
    initialize_models
    
    # Start the application
    start_app
}

# Run main function
main

# This should never be reached
log "ERROR: Startup script unexpectedly exited"
exit 1
