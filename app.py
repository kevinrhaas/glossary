from flask import Flask, request, jsonify, render_template_string
import os
import json
import logging
import httpx
from typing import Dict, Any
from sqlalchemy import create_engine, MetaData, Table
from sqlalchemy.orm import sessionmaker

app = Flask(__name__)

# Load default configuration from config.json or environment variables
DEFAULT_CONFIG = {}
try:
    if os.path.exists('config.json'):
        with open('config.json', 'r') as f:
            DEFAULT_CONFIG = json.load(f)
        logging.info("Default configuration loaded from config.json")
    else:
        logging.info("config.json not found, using environment variables")
        
    # Override with environment variables if present (for containerized deployment)
    env_config = {
        "database": {
            "url": os.getenv('DATABASE_URL', DEFAULT_CONFIG.get("database", {}).get("url", "")),
            "schema": os.getenv('DATABASE_SCHEMA', DEFAULT_CONFIG.get("database", {}).get("schema", ""))
        },
        "api": {
            "base_url": os.getenv('API_BASE_URL', DEFAULT_CONFIG.get("api", {}).get("base_url", "")),
            "api_key": os.getenv('API_KEY', DEFAULT_CONFIG.get("api", {}).get("api_key", "")),
            "deployment_id": os.getenv('API_DEPLOYMENT_ID', DEFAULT_CONFIG.get("api", {}).get("deployment_id", "model-router")),
            "api_version": os.getenv('API_VERSION', DEFAULT_CONFIG.get("api", {}).get("api_version", "2025-01-01-preview")),
            "prompt_template": os.getenv('API_PROMPT_TEMPLATE', DEFAULT_CONFIG.get("api", {}).get("prompt_template", "Analyze this database schema: {schema_summary}")),
            "max_tokens": int(os.getenv('API_MAX_TOKENS', DEFAULT_CONFIG.get("api", {}).get("max_tokens", 8192))),
            "temperature": float(os.getenv('API_TEMPERATURE', DEFAULT_CONFIG.get("api", {}).get("temperature", 0.7))),
            "top_p": float(os.getenv('API_TOP_P', DEFAULT_CONFIG.get("api", {}).get("top_p", 0.95))),
            "frequency_penalty": float(os.getenv('API_FREQUENCY_PENALTY', DEFAULT_CONFIG.get("api", {}).get("frequency_penalty", 0))),
            "presence_penalty": float(os.getenv('API_PRESENCE_PENALTY', DEFAULT_CONFIG.get("api", {}).get("presence_penalty", 0))),
            "model": os.getenv('API_MODEL', DEFAULT_CONFIG.get("api", {}).get("model", "model-router")),
            "timeout": float(os.getenv('API_TIMEOUT', DEFAULT_CONFIG.get("api", {}).get("timeout", 60.0))),
            "max_retries": int(os.getenv('API_MAX_RETRIES', DEFAULT_CONFIG.get("api", {}).get("max_retries", 3)))
        }
    }
    
    # Use environment config if any environment variables are set
    if any([os.getenv('DATABASE_URL'), os.getenv('API_BASE_URL'), os.getenv('API_KEY')]):
        DEFAULT_CONFIG = env_config
        logging.info("Configuration loaded from environment variables")
        
except Exception as e:
    logging.error(f"Error loading configuration: {e}")
    DEFAULT_CONFIG = {}

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def merge_with_defaults(request_config: Dict[str, Any]) -> Dict[str, Any]:
    """Merge request configuration with defaults from config.json."""
    merged_config = {}
    
    # Merge database configuration
    merged_config["database"] = {}
    default_db = DEFAULT_CONFIG.get("database", {})
    request_db = request_config.get("database", {})
    
    merged_config["database"]["url"] = request_db.get("url") or default_db.get("url")
    merged_config["database"]["schema"] = request_db.get("schema") or default_db.get("schema")
    
    # Merge API configuration
    merged_config["api"] = {}
    default_api = DEFAULT_CONFIG.get("api", {})
    request_api = request_config.get("api", {})
    
    merged_config["api"]["base_url"] = request_api.get("base_url") or default_api.get("base_url")
    merged_config["api"]["deployment_id"] = request_api.get("deployment_id") or default_api.get("deployment_id", "model-router")
    merged_config["api"]["api_version"] = request_api.get("api_version") or default_api.get("api_version", "2025-01-01-preview")
    merged_config["api"]["api_key"] = request_api.get("api_key") or default_api.get("api_key")
    merged_config["api"]["prompt_template"] = request_api.get("prompt_template") or default_api.get("prompt_template", "Analyze this database schema: {schema_summary}")
    merged_config["api"]["max_tokens"] = request_api.get("max_tokens") or default_api.get("max_tokens", 8192)
    merged_config["api"]["temperature"] = request_api.get("temperature") if request_api.get("temperature") is not None else default_api.get("temperature", 0.7)
    merged_config["api"]["top_p"] = request_api.get("top_p") if request_api.get("top_p") is not None else default_api.get("top_p", 0.95)
    merged_config["api"]["frequency_penalty"] = request_api.get("frequency_penalty") if request_api.get("frequency_penalty") is not None else default_api.get("frequency_penalty", 0)
    merged_config["api"]["presence_penalty"] = request_api.get("presence_penalty") if request_api.get("presence_penalty") is not None else default_api.get("presence_penalty", 0)
    merged_config["api"]["model"] = request_api.get("model") or default_api.get("model", "model-router")
    merged_config["api"]["timeout"] = request_api.get("timeout") or default_api.get("timeout", 60.0)
    merged_config["api"]["max_retries"] = request_api.get("max_retries") or default_api.get("max_retries", 3)
    
    return merged_config


def load_config_from_request(config_data: Dict[str, Any]) -> Dict[str, Any]:
    """Load configuration from request data."""
    logging.info("Processing configuration from request")
    return config_data

def create_database_engine(config: Dict[str, Any]):
    """Create database engine from configuration."""
    db_url = config.get("database", {}).get("url")
    if not db_url:
        raise ValueError("Database URL not found in configuration.")

    logging.info(f"Connecting to database: {db_url.split('@')[-1] if '@' in db_url else db_url.split('//')[-1]}")
    engine = create_engine(db_url)
    
    # Test the connection
    try:
        with engine.connect() as conn:
            logging.info("Database connection established successfully")
    except Exception as e:
        logging.error(f"Failed to connect to database: {e}")
        raise
    
    return engine

def reflect_schema(engine, schema_name=None):
    """Reflect database schema and return metadata with table information."""
    if schema_name:
        logging.info(f"Reflecting database schema: {schema_name}")
    else:
        logging.info("Reflecting database schema (default/public)")
    
    metadata = MetaData()
    metadata.reflect(bind=engine, schema=schema_name)
    
    table_count = len(metadata.tables)
    schema_msg = f" in schema '{schema_name}'" if schema_name else " in default schema"
    logging.info(f"Schema reflection complete - found {table_count} tables{schema_msg}")
    
    # Log table names and basic column counts in a concise format
    if table_count > 0:
        table_info = []
        for table_name, table in metadata.tables.items():
            column_count = len(table.columns)
            table_info.append(f"{table_name}({column_count} cols)")
        
        # Group tables for concise logging
        if table_count <= 10:
            logging.info(f"Tables: {', '.join(table_info)}")
        else:
            logging.info(f"First 10 tables: {', '.join(table_info[:10])}")
            logging.info(f"... and {table_count - 10} more tables")
    else:
        logging.warning("No tables found in the database schema")
    
    return metadata

def clean_and_validate_json(response_text: str) -> dict:
    """Clean API response and validate it's proper JSON."""
    if not response_text:
        return None
    
    # Remove markdown code blocks if present
    cleaned_text = response_text.strip()
    
    # Remove ```json and ``` markers
    if cleaned_text.startswith('```json'):
        cleaned_text = cleaned_text[7:]  # Remove ```json
    elif cleaned_text.startswith('```'):
        cleaned_text = cleaned_text[3:]   # Remove ```
    
    if cleaned_text.endswith('```'):
        cleaned_text = cleaned_text[:-3]  # Remove trailing ```
    
    cleaned_text = cleaned_text.strip()
    
    # Try to parse as JSON
    try:
        json_obj = json.loads(cleaned_text)
        logging.info("Successfully parsed and validated JSON response")
        return json_obj
    except json.JSONDecodeError as e:
        logging.warning(f"Invalid JSON in API response: {e}")
        return None

def make_api_call(config: Dict[str, Any], schema_summary: str) -> dict:
    """Make an API call with the schema summary and configured prompt."""
    api_config = config.get("api", {})
    if not api_config:
        logging.warning("No API configuration found, skipping API call")
        return None
    
    base_url = api_config.get("base_url")
    deployment_id = api_config.get("deployment_id", "model-router")
    api_version = api_config.get("api_version", "2025-01-01-preview")
    api_key = api_config.get("api_key")
    prompt_template = api_config.get("prompt_template", "Analyze this database schema: {schema_summary}")
    max_retries = api_config.get("max_retries", 3)
    
    if not all([base_url, api_key]):
        logging.error("Missing required API configuration (base_url, api_key)")
        return None
    
    # Format the prompt with the schema summary
    formatted_prompt = prompt_template.format(schema_summary=schema_summary)
    
    message = {
        "messages": [
            {
                "role": "user",
                "content": formatted_prompt
            }
        ],
        "max_tokens": api_config.get("max_tokens", 8192),
        "temperature": api_config.get("temperature", 0.7),
        "top_p": api_config.get("top_p", 0.95),
        "frequency_penalty": api_config.get("frequency_penalty", 0),
        "presence_penalty": api_config.get("presence_penalty", 0),
        "model": api_config.get("model", "model-router")
    }
    
    for attempt in range(1, max_retries + 1):
        logging.info(f"Making API call attempt {attempt}/{max_retries} to: {base_url}")
        
        try:
            response = httpx.post(
                f'http://{base_url}/deployments/{deployment_id}/chat/completions?api-version={api_version}',
                headers={
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Credentials': 'true',
                    'api-key': api_key
                },
                json=message,
                timeout=api_config.get("timeout", 60.0)
            )
            
            if response.status_code == 200:
                logging.info(f"API call attempt {attempt} successful")
                response_data = response.json()
                content = response_data.get("choices", [{}])[0].get("message", {}).get("content", "")
                
                # Clean and validate JSON
                parsed_json = clean_and_validate_json(content)
                if parsed_json is not None:
                    logging.info(f"Valid JSON received on attempt {attempt}")
                    return parsed_json
                else:
                    logging.warning(f"Invalid JSON received on attempt {attempt}, retrying...")
                    if attempt < max_retries:
                        # Modify the prompt slightly for retry to encourage better JSON
                        message["messages"][0]["content"] = formatted_prompt + " Please ensure your response is valid JSON only, without any markdown formatting or extra text."
                    continue
            else:
                logging.error(f"API call attempt {attempt} failed with status {response.status_code}: {response.text}")
                if attempt < max_retries:
                    continue
                
        except Exception as e:
            logging.error(f"API call attempt {attempt} error: {e}")
            if attempt < max_retries:
                continue
    
    logging.error(f"All {max_retries} API call attempts failed")
    return None

def create_schema_summary(metadata: MetaData, schema_name: str = None) -> str:
    """Create a concise summary of the database schema for API consumption."""
    table_count = len(metadata.tables)
    schema_prefix = f"Schema '{schema_name}': " if schema_name else "Database: "
    
    summary_parts = [f"{schema_prefix}{table_count} tables"]
    
    # Add table details
    table_details = []
    for table_name, table in metadata.tables.items():
        column_names = [col.name for col in table.columns]
        # Limit column names to keep summary concise
        if len(column_names) > 10:
            column_summary = f"{', '.join(column_names[:10])}... ({len(column_names)} total columns)"
        else:
            column_summary = ', '.join(column_names)
        
        table_details.append(f"Table {table_name}: {column_summary}")
    
    summary_parts.extend(table_details)
    return '\n'.join(summary_parts)

@app.route('/', methods=['GET'])
def home():
    """Home page with basic information."""
    return jsonify({
        "service": "Database Schema Glossary Generator",
        "version": "1.0.0",
        "endpoints": {
            "/": "This endpoint - service information",
            "/docs": "API documentation",
            "/analyze": "POST - Analyze database schema and generate glossary",
            "/defaults": "GET - View current default configuration",
            "/health": "Service health check"
        }
    })

@app.route('/defaults', methods=['GET'])
def show_defaults():
    """Show current default configuration (with sensitive data masked)."""
    safe_defaults = json.loads(json.dumps(DEFAULT_CONFIG))  # Deep copy
    
    # Mask sensitive information
    if "database" in safe_defaults and "url" in safe_defaults["database"]:
        url = safe_defaults["database"]["url"]
        if "@" in url:
            # Mask password in database URL
            parts = url.split("://")
            if len(parts) == 2:
                protocol = parts[0]
                rest = parts[1]
                if "@" in rest:
                    auth_part, host_part = rest.split("@", 1)
                    if ":" in auth_part:
                        user, _ = auth_part.split(":", 1)
                        safe_defaults["database"]["url"] = f"{protocol}://{user}:***@{host_part}"
    
    if "api" in safe_defaults and "api_key" in safe_defaults["api"]:
        # Mask API key
        api_key = safe_defaults["api"]["api_key"]
        if len(api_key) > 8:
            safe_defaults["api"]["api_key"] = api_key[:4] + "***" + api_key[-4:]
        else:
            safe_defaults["api"]["api_key"] = "***"
    
    return jsonify({
        "defaults": safe_defaults,
        "note": "Sensitive data (passwords, API keys) are masked with ***"
    })

@app.route('/docs', methods=['GET'])
def documentation():
    """API documentation endpoint."""
    
    # Get default values for documentation
    default_db_url = DEFAULT_CONFIG.get("database", {}).get("url", "")
    default_schema = DEFAULT_CONFIG.get("database", {}).get("schema", "")
    default_base_url = DEFAULT_CONFIG.get("api", {}).get("base_url", "")
    default_api_key = DEFAULT_CONFIG.get("api", {}).get("api_key", "")
    
    # Mask sensitive defaults for display
    masked_db_url = default_db_url
    if "@" in masked_db_url:
        parts = masked_db_url.split("://")
        if len(parts) == 2:
            protocol = parts[0]
            rest = parts[1]
            if "@" in rest:
                auth_part, host_part = rest.split("@", 1)
                if ":" in auth_part:
                    user, _ = auth_part.split(":", 1)
                    masked_db_url = f"{protocol}://{user}:***@{host_part}"
    
    masked_api_key = default_api_key
    if len(masked_api_key) > 8:
        masked_api_key = masked_api_key[:4] + "***" + masked_api_key[-4:]
    elif masked_api_key:
        masked_api_key = "***"
    
    docs_html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Database Schema Glossary Generator - API Documentation</title>
        <style>
            body {{ font-family: Arial, sans-serif; margin: 20px; line-height: 1.6; }}
            .endpoint {{ background: #f4f4f4; padding: 15px; margin: 10px 0; border-radius: 5px; }}
            .method {{ color: #fff; padding: 3px 8px; border-radius: 3px; font-weight: bold; }}
            .post {{ background: #28a745; }}
            .get {{ background: #007bff; }}
            pre {{ background: #f8f9fa; padding: 15px; border-radius: 5px; overflow-x: auto; }}
            .required {{ color: #dc3545; font-weight: bold; }}
            .optional {{ color: #6c757d; }}
        </style>
    </head>
    <body>
        <h1>Database Schema Glossary Generator API</h1>
        
        <div class="endpoint">
            <h3><span class="method post">POST</span> /analyze</h3>
            <p>Analyzes a database schema and generates a hierarchical business glossary using AI.</p>
            <p><strong>Note:</strong> Request values override defaults. You can omit fields that have default values.</p>
            
            <h4>Request Body (JSON):</h4>
            <pre>{{
  "database": {{
    "url": "<span class=\"optional\">string</span> - Database connection URL (default: {masked_db_url})",
    "schema": "<span class=\"optional\">string</span> - Schema name (default: {default_schema})"
  }},
  "api": {{
    "base_url": "<span class=\"optional\">string</span> - API base URL (default: {default_base_url})",
    "deployment_id": "<span class=\"optional\">string</span> - Deployment ID (default: 'model-router')",
    "api_version": "<span class=\"optional\">string</span> - API version (default: '2025-01-01-preview')",
    "api_key": "<span class=\"optional\">string</span> - API key (default: {masked_api_key})",
    "prompt_template": "<span class=\"optional\">string</span> - Override glossary generation prompt with {{schema_summary}} placeholder",
    "max_tokens": "<span class=\"optional\">number</span> - Max response tokens (default: 8192)",
    "temperature": "<span class=\"optional\">number</span> - AI temperature 0-1 (default: 0.7)",
    "timeout": "<span class=\"optional\">number</span> - Request timeout in seconds (default: 60)",
    "max_retries": "<span class=\"optional\">number</span> - Max retry attempts (default: 3)"
  }}
}}</pre>

            <h4>Minimal Example Request (using defaults):</h4>
            <pre>{{
  "database": {{
    "url": "postgresql://user:password@host:port/database",
    "schema": "schema_name"
  }}
}}</pre>

            <h4>Full Override Example:</h4>
            <pre>{{
  "database": {{
    "url": "postgresql://user:password@your-host:port/database",
    "schema": "public"
  }},
  "api": {{
    "base_url": "your-api-endpoint.com",
    "api_key": "your-api-key",
    "temperature": 0.3,
    "max_retries": 5
  }}
}}</pre>

            <h4>Response:</h4>
            <pre>{{
  "success": true,
  "data": {{
    "Root Glossary Name": [
      {{
        "Category Under Root": [
          "Simple Leaf Term",
          {{
            "Parent Leaf Term": [
              "Nested Leaf Term"
            ]
          }}
        ]
      }}
    ]
  }},
  "metadata": {{
    "tables_analyzed": 15,
    "schema_name": "public",
    "processing_time": 2.3
  }}
}}</pre>
        </div>
        
        <div class="endpoint">
            <h3><span class="method get">GET</span> /defaults</h3>
            <p>View current default configuration (sensitive data masked).</p>
            <h4>Response:</h4>
            <pre>{{
  "defaults": {{
    "database": {{
      "url": "{masked_db_url}",
      "schema": "{default_schema}"
    }},
    "api": {{
      "base_url": "{default_base_url}",
      "api_key": "{masked_api_key}",
      ...
    }}
  }},
  "note": "Sensitive data (passwords, API keys) are masked with ***"
}}</pre>
        </div>

        <div class="endpoint">
            <h3><span class="method get">GET</span> /health</h3>
            <p>Check service health status.</p>
            <h4>Response:</h4>
            <pre>{{
  "status": "healthy",
  "timestamp": "2025-07-30T10:30:00Z"
}}</pre>
        </div>

        <h3>Error Responses</h3>
        <p>All endpoints return error responses in this format:</p>
        <pre>{{
  "success": false,
  "error": "Error description",
  "details": "Additional error details (optional)"
}}</pre>

        <h3>Common Error Codes</h3>
        <ul>
            <li><strong>400</strong> - Bad Request (missing required fields, invalid JSON)</li>
            <li><strong>500</strong> - Internal Server Error (database connection, API call failures)</li>
        </ul>
    </body>
    </html>
    """
    return docs_html

@app.route('/analyze', methods=['POST'])
def analyze_schema():
    """Main endpoint to analyze database schema and generate glossary."""
    try:
        import time
        start_time = time.time()
        
        # Get configuration from request and merge with defaults
        try:
            request_config = request.get_json(force=True)
        except Exception as json_error:
            # If no JSON body or invalid JSON, use empty dict (will use all defaults)
            logging.info("No JSON body provided, using all defaults from config")
            request_config = {}
            
        if not request_config:
            logging.info("Empty JSON object provided, using all defaults from config")
            request_config = {}
        
        # Merge request config with defaults (empty request_config means all defaults)
        config_data = merge_with_defaults(request_config)
        
        # Validate required fields after merging
        if not config_data.get("database", {}).get("url"):
            return jsonify({
                "success": False,  
                "error": "Database URL is required",
                "details": "Either provide database.url in request body or ensure it's configured in your defaults"
            }), 400
        
        if "api" not in config_data or not config_data.get("api"):
            return jsonify({
                "success": False,
                "error": "API configuration is required",
                "details": "Either provide api configuration in request body or ensure it's configured in your defaults"
            }), 400
        
        api_config = config_data.get("api", {})
        if not api_config.get("base_url") or not api_config.get("api_key"):
            return jsonify({
                "success": False,
                "error": "API base_url and api_key are required",
                "details": "Either provide api.base_url and api.api_key in request body or ensure they're configured in your defaults"
            }), 400
        
        logging.info("Starting database schema analysis via API...")
        
        # Create database engine
        engine = create_database_engine(config_data)
        
        # Get schema name from config if specified
        schema_name = config_data.get("database", {}).get("schema")
        metadata = reflect_schema(engine, schema_name)
        
        # Create schema summary for API call
        schema_summary = create_schema_summary(metadata, schema_name)
        logging.info("Schema summary created for API call")
        
        # Make API call with schema summary
        api_response = make_api_call(config_data, schema_summary)
        
        processing_time = round(time.time() - start_time, 2)
        
        if api_response:
            logging.info("API analysis completed successfully")
            return jsonify({
                "success": True,
                "data": api_response,
                "metadata": {
                    "tables_analyzed": len(metadata.tables),
                    "schema_name": schema_name or "default",
                    "processing_time": processing_time
                }
            })
        else:
            return jsonify({
                "success": False,
                "error": "API call failed after all retry attempts",
                "metadata": {
                    "tables_analyzed": len(metadata.tables),
                    "schema_name": schema_name or "default",
                    "processing_time": processing_time
                }
            }), 500
            
    except Exception as e:
        logging.error(f"Error in analyze_schema: {e}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint."""
    from datetime import datetime
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat() + "Z"
    })

if __name__ == '__main__':
    # Use PORT environment variable for cloud deployment, default to 5000
    port = int(os.getenv('PORT', 5000))
    app.run(debug=False, host='0.0.0.0', port=port)
