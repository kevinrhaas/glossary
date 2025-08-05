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

### `GET /prompts`
List available route-based prompt templates

**Response:**
```json
{
  "prompt_templates": {
    "analyze": {
      "name": "Database Schema Analyzer",
      "description": "Analyzes database schemas and generates comprehensive business glossaries"
    },
    "generate": {
      "name": "Glossary Format Generator",
      "description": "Transforms glossary data into different output formats"
    }
  },
  "available_routes": ["analyze", "generate"],
  "usage": "Each route automatically uses its corresponding prompt template",
  "count": 2
}
```

### `POST /analyze`
Generate business glossary from database schema

**Basic request:**
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

### `POST /generate`
Transform glossary data into PDC export format with GUIDs and hierarchical relationships

**Request (uses output from /analyze):**
```bash
curl -X POST http://localhost:5000/generate \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "Healthcare Laboratory Operations": [
        {
          "Patients": [
            "Patient Identification",
            "Patient Demographics"
          ]
        },
        {
          "Tests": [
            "Test Code", 
            "Test Name"
          ]
        }
      ]
    }
  }'
```

**Response (PDC Export Format):**
```json
{
  "success": true,
  "data": {
    "pdc_export": [
      {
        "_id": "2a5178c3-95c2-421e-b063-5392c7234936",
        "name": "Healthcare Laboratory Operations",
        "type": "glossary",
        "fqdn": "Healthcare Laboratory Operations",
        "rootId": "2a5178c3-95c2-421e-b063-5392c7234936",
        "attributes": {
          "style": {"color": "#70759C"},
          "info": {
            "definition": "...",
            "status": "Draft"
          }
        },
        "createdAt": "2025-08-04T14:43:58.000Z",
        "updatedAt": "2025-08-04T14:43:58.000Z"
      },
      {
        "_id": "c7c0e5a0-3000-4758-a44e-dee69249818e",
        "name": "Patients",
        "type": "category",
        "parentId": "2a5178c3-95c2-421e-b063-5392c7234936",
        "fqdn": "Healthcare Laboratory Operations/Patients",
        "rootId": "2a5178c3-95c2-421e-b063-5392c7234936",
        "attributes": {
          "style": {"color": "#70759C"}
        }
      }
    ]
  }
}

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

## API Request Options

### Route-Based Prompt Templates

The system uses route-based prompt templates stored in `prompts.json`:
- **`/analyze`**: Uses "analyze" prompt - analyzes database schemas and generates hierarchical business glossaries
- **`/generate`**: Uses "generate" prompt - transforms glossary data into PDC export format with GUIDs and parent-child relationships

Each route automatically uses its corresponding prompt template. Use `GET /prompts` to see all available routes and their descriptions.

### Two-Stage Workflow

1. **Analyze Database** → `/analyze` generates hierarchical business glossary from schema
2. **Generate PDC Export** → `/generate` transforms glossary into PDC format with GUIDs, types (glossary/category/term), and proper parent-child relationships

### API Parameter Overrides

You can override any API parameter per request while keeping environment defaults:

```json
{
  "api": {
    "temperature": 0.3,
    "max_tokens": 4096
  }
}
```

For the `/generate` endpoint, provide the data to transform:

```json
{
  "data": { /* hierarchical glossary data from /analyze */ },
  "api": {
    "temperature": 0.3
  }
}
```

The request overrides are merged with environment defaults, so you only need to specify what you want to change.
