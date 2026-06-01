FROM python:3.11-slim

# Create non-root user before installing dependencies
RUN useradd -m -u 1001 appuser

WORKDIR /app

# Install dependencies as root, then hand off ownership
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt \
    && chown -R appuser:appuser /app

COPY --chown=appuser:appuser . .

# Drop privileges
USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4", "--log-level", "info"]