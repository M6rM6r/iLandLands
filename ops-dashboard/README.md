# Ops Dashboard

This is the Product Telemetry Dashboard for Gulflands, providing insights into key metrics for product analytics.

## Structure

- `frontend/`: React-based dashboard application
- `etl/`: Python scripts for data aggregation
- `data/`: Sample data files
- `docs/`: Documentation including KPI definitions

## Setup

### Frontend
1. Navigate to `frontend/`
2. Run `npm install`
3. Run `npm start` to start the development server

### ETL
1. Navigate to `etl/`
2. Install dependencies: `pip install -r requirements.txt`
3. Run aggregation: `python aggregate.py`

## Performance
The dashboard is optimized to load in under 2 seconds with sample data.

## Metrics
See `docs/kpi_definitions.md` for detailed KPI definitions.