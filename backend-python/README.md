# Gulf Lands Backend API

A FastAPI-based backend service for the Gulf Lands real estate application.

## Features

- RESTful API for land listings
- Filtering and sorting capabilities
- Pagination support
- Health check endpoints
- Analytics event tracking

## Running Locally

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Run the server:
   ```bash
   uvicorn main:app --reload
   ```

3. Open http://localhost:8000/docs for API documentation.

## Docker

```bash
docker build -t gulflands-backend .
docker run -p 8000:8000 gulflands-backend
```