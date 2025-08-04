# Configuration Management

This application follows **12-Factor App** principles for configuration management using environment variables exclusively for production deployments.

## Configuration Approach

### ✅ Best Practice: Environment Variables
- **Production**: Use environment variables set by your deployment platform
- **Local Development**: Use `.env` file (automatically loaded)
- **Security**: Never commit credentials to git
- **Flexibility**: Different values per environment (dev/staging/prod)

### ❌ Deprecated: config.json
- The old `config.json` approach has been replaced
- `config.template.json` provided as reference only
- Local `config.local.json` is gitignored for backward compatibility

## Setup Instructions

### Local Development

1. **Copy the environment template:**
```bash
cp .env.example .env
```

2. **Edit `.env` with your values:**
```bash
# Required
DATABASE_URL=postgresql://user:pass@host:5432/db?sslmode=require
API_BASE_URL=your-endpoint.azure-api.net/openai-presales
API_KEY=your-api-key

# Optional (uses defaults if not set)
DATABASE_SCHEMA=your_schema
API_MAX_TOKENS=8192
API_TEMPERATURE=0.7
```

3. **Run the application:**
```bash
python app.py
```

The app automatically loads `.env` for local development.

### Production Deployment

Set environment variables directly in your deployment platform:

**AWS ECS:**
```json
"environment": [
  {"name": "DATABASE_URL", "value": "postgresql://..."},
  {"name": "API_BASE_URL", "value": "your-endpoint.azure-api.net/..."},
  {"name": "API_KEY", "value": "your-key"}
]
```

**Docker:**
```bash
docker run -e DATABASE_URL="postgresql://..." -e API_KEY="..." myapp
```

**AWS App Runner / Lambda:**
Set via console or deployment scripts.

## Configuration Reference

### Required Environment Variables
- `DATABASE_URL` - PostgreSQL connection string
- `API_BASE_URL` - AI API endpoint
- `API_KEY` - AI API authentication key

### Optional Environment Variables (with defaults)
- `DATABASE_SCHEMA` - Database schema name
- `API_DEPLOYMENT_ID` - API deployment ID (default: "model-router")  
- `API_VERSION` - API version (default: "2025-01-01-preview")
- `API_MAX_TOKENS` - Max response tokens (default: 8192)
- `API_TEMPERATURE` - AI temperature (default: 0.7)
- `API_TIMEOUT` - Request timeout in seconds (default: 60.0)
- `API_MAX_RETRIES` - Max retry attempts (default: 3)
- `API_PROMPT_TEMPLATE` - Custom AI prompt template
- `PORT` - Server port (default: 5000)

## Verification

Check your configuration with:
```bash
curl http://localhost:5000/defaults
```

This shows all loaded configuration (with sensitive values masked).

## Security Notes

- **Never commit** `.env`, `config.json`, or any files with real credentials
- Use your deployment platform's secure secret management
- The `/defaults` endpoint masks sensitive values for security
- All credential-containing files are in `.gitignore` and `.dockerignore`
