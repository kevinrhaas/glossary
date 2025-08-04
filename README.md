# Database Schema Glossary Generator

A Flask web service that analyzes database schemas and generates hierarchical business glossaries using AI.

**Supports multiple databases:** PostgreSQL, MySQL/MariaDB, SQLite, SQL Server, Oracle, and any SQLAlchemy-compatible database.

## Quick Start

1. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your database and API credentials
   ```

3. **Run locally:**
   ```bash
   python app.py
   ```

4. **Test the service:**
   ```bash
   curl http://localhost:5000/health
   ```

## Environment Configuration

Create a `.env` file with your settings:

```bash
# Required
DATABASE_URL=postgresql://user:password@host:port/database
API_BASE_URL=your-ai-api-endpoint.com
API_KEY=your-api-key

# Optional (with defaults)
DATABASE_SCHEMA=public
API_DEPLOYMENT_ID=model-router
API_VERSION=2025-01-01-preview
API_MAX_TOKENS=8192
API_TEMPERATURE=0.7
API_TIMEOUT=60.0
API_MAX_RETRIES=3
PORT=5000
```

### Database URL Examples

**PostgreSQL:**
```
DATABASE_URL=postgresql://user:password@host:port/database
DATABASE_SCHEMA=public
```

**MySQL/MariaDB:**
```
DATABASE_URL=mysql://user:password@host:port/database
```

**SQLite:**
```
DATABASE_URL=sqlite:///path/to/database.db
```

**SQL Server:**
```
DATABASE_URL=mssql+pyodbc://user:password@host:port/database?driver=ODBC+Driver+17+for+SQL+Server
DATABASE_SCHEMA=dbo
```

## API Endpoints

### `GET /`
Service information and available endpoints

### `GET /health`
Health check with database connectivity test

### `GET /config`
View current configuration (sensitive values masked)

### `POST /analyze`
Generate business glossary from database schema

**Basic request (uses environment defaults):**
```bash
curl -X POST http://localhost:5000/analyze \
  -H "Content-Type: application/json" \
  -d "{}"
```

**Request with API overrides:**
```bash
curl -X POST http://localhost:5000/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "api": {
      "temperature": 0.3,
      "max_tokens": 4096
    }
  }'
```

**Response:**
```json
{
  "success": true,
  "data": {
    "Business Glossary": [
      {
        "Customer Management": [
          "Customer",
          "Customer Segment",
          {
            "Customer Lifecycle": [
              "Customer Acquisition",
              "Customer Retention"
            ]
          }
        ]
      }
    ]
  },
  "metadata": {
    "tables_analyzed": 7,
    "schema_name": "public",
    "processing_time": 5.2,
    "ai_model_used": "model-router"
  }
}
```

## Deployment

For production deployment, see `DEPLOYMENT.md` for complete AWS deployment instructions with Docker containers.

**Quick deployment:**
```bash
# Deploy to test environment
./deploy/04-deploy-to-test.sh

# Deploy to production (after testing)
./deploy/04-deploy-to-production.sh
```

## API Request Overrides

You can override any API parameter per request while keeping environment defaults:

```json
{
  "api": {
    "temperature": 0.3,
    "max_tokens": 4096,
    "prompt_template": "Custom prompt with {schema_summary} placeholder"
  }
}
```

The request overrides are merged with environment defaults, so you only need to specify what you want to change.
