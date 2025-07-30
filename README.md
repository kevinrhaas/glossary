# Database Schema Glossary Generator Web Service

A Flask-based web service that analyzes database schemas and generates hierarchical business glossaries using AI. 

**Supports multiple database types:** PostgreSQL, MySQL/MariaDB, SQLite, Microsoft SQL Server, Oracle, and any database with SQLAlchemy support.

## Installation

1. Install required packages:
```bash
pip install -r requirements.txt
```

2. Run the service:
```bash
python app.py
```

The service will start on `http://localhost:5000`

## Database Compatibility

This service works with multiple database types by changing the connection URL format:

### PostgreSQL
```json
{
  "database": {
    "url": "postgresql://username:password@host:port/database_name",
    "schema": "schema_name"
  }
}
```

### MySQL/MariaDB
```json
{
  "database": {
    "url": "mysql://username:password@host:port/database_name",
    "schema": null
  }
}
```

### SQLite
```json
{
  "database": {
    "url": "sqlite:///path/to/database.db",
    "schema": null
  }
}
```

### Microsoft SQL Server
```json
{
  "database": {
    "url": "mssql+pyodbc://username:password@host:port/database_name?driver=ODBC+Driver+17+for+SQL+Server",
    "schema": "dbo"
  }
}
```

### Oracle
```json
{
  "database": {
    "url": "oracle://username:password@host:port/service_name",
    "schema": "schema_name"
  }
}
```

## API Endpoints

### GET /
Service information and available endpoints

### GET /docs
Complete API documentation with examples

### POST /analyze
Main endpoint to analyze database schema and generate glossary

**Request Body (all fields optional - uses defaults from config.json):**
```json
{
  "database": {
    "url": "postgresql://user:password@host:port/database",
    "schema": "schema_name"
  },
  "api": {
    "base_url": "your-api-endpoint.com",
    "api_key": "your-api-key",
    "prompt_template": "Custom prompt with {schema_summary} placeholder",
    "max_retries": 3,
    "max_tokens": 8192,
    "temperature": 0.7
  }
}
```

**Minimal request (using configured defaults):**
```json
{
  "database": {
    "url": "mysql://user:password@host:port/database"
  }
}
```

**Empty request body (uses all defaults from config.json):**
```bash
curl -X POST http://localhost:5000/analyze \
  -H "Content-Type: application/json" \
  -d "{}"
```

**Response:**
```json
{
  "success": true,
  "data": {
    "Root Glossary Name": [
      {
        "Category Under Root": [
          "Simple Leaf Term",
          {
            "Parent Leaf Term": ["Nested Leaf Term"]
          }
        ]
      }
    ]
  },
  "metadata": {
    "tables_analyzed": 15,
    "schema_name": "public",
    "processing_time": 2.3
  }
}
```

### GET /health
Service health check

### GET /defaults
View current default configuration (with sensitive data masked)

**Response:**
```json
{
  "defaults": {
    "database": {
      "url": "postgresql://user:***@host:port/database",
      "schema": "public"
    },
    "api": {
      "base_url": "your-api-endpoint.com",
      "api_key": "abc1***xyz9",
      "max_retries": 3,
      "temperature": 0.7
    }
  },
  "note": "Sensitive data (passwords, API keys) are masked with ***"
}
```

## Example Usage

### Using PostgreSQL with custom configuration:
```bash
curl -X POST http://localhost:5000/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "database": {
      "url": "postgresql://user:pass@localhost:5432/mydb",
      "schema": "public"
    }
  }'
```

### Using MySQL with defaults:
```bash
curl -X POST http://localhost:5000/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "database": {
      "url": "mysql://user:pass@localhost:3306/mydb"
    }
  }'
```

### Using SQLite:
```bash
curl -X POST http://localhost:5000/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "database": {
      "url": "sqlite:///./my_database.db"
    }
  }'
```

### Using all defaults from config.json:
```bash
curl -X POST http://localhost:5000/analyze \
  -H "Content-Type: application/json" \
  -d "{}"
```

## Configuration

The service supports a `config.json` file for default values. Any field in the request body will override the corresponding default value. This allows you to:

1. Set up common defaults (API keys, database URLs) in `config.json`
2. Override specific values per request
3. Use empty request bodies to rely entirely on defaults

**Example config.json:**
```json
{
  "database": {
    "url": "postgresql://user:password@host:port/database",
    "schema": "public"
  },
  "api": {
    "base_url": "your-api-endpoint.com",
    "api_key": "your-api-key",
    "max_retries": 3,
    "temperature": 0.7
  }
}
```
