from flask import Flask, jsonify, request
import os
import json
import logging
from sqlalchemy import create_engine, text, inspect
from sqlalchemy.exc import SQLAlchemyError
import traceback
from datetime import datetime
import httpx
from typing import Dict, Any
import time
from dotenv import load_dotenv

# Load environment variables from .env file (for local development)
load_dotenv()

app = Flask(__name__)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)

# Global variables for lazy loading
_db_engine = None
_config = None

def load_config():
    """Load configuration from environment variables with defaults (lazy loading)"""
    global _config
    if _config is not None:
        return _config
    
    try:
        # Load all configuration from environment variables with sensible defaults
        _config = {
            # Database configuration
            'database_url': os.getenv('DATABASE_URL'),
            'database_schema': os.getenv('DATABASE_SCHEMA'),
            
            # API configuration
            'api_base_url': os.getenv('API_BASE_URL'),
            'api_key': os.getenv('API_KEY'),
            'api_deployment_id': os.getenv('API_DEPLOYMENT_ID', 'model-router'),
            'api_version': os.getenv('API_VERSION', '2025-01-01-preview'),
            
            # AI model configuration with defaults
            'api_max_tokens': int(os.getenv('API_MAX_TOKENS', '8192')),
            'api_temperature': float(os.getenv('API_TEMPERATURE', '0.7')),
            'api_timeout': float(os.getenv('API_TIMEOUT', '60.0')),
            'api_max_retries': int(os.getenv('API_MAX_RETRIES', '3')),
            
            # Server configuration
            'port': int(os.getenv('PORT', '5000')),
            
            # AI prompt template
            'api_prompt_template': os.getenv('API_PROMPT_TEMPLATE', 
                'Analyze this database schema and create a comprehensive business data glossary. '
                'Based on the table names, column names, and their relationships, analyze the business at hand, '
                'and organize the business terms into a hierarchical structure. '
                'Return ONLY valid JSON in this exact format: '
                '{{ "Root Glossary Name": [ {{ "Category Under Root": [ "Simple Leaf Term", '
                '{{ "Parent Leaf Term": [ "Nested Leaf Term" ] }} ] }} ] }}. '
                'Use meaningful business terms derived from the schema. Schema to analyze: {schema_summary}')
        }
        
        # Validate required configuration
        required_vars = ['database_url', 'api_base_url', 'api_key']
        missing_vars = [var for var in required_vars if not _config.get(var)]
        
        if missing_vars:
            logger.error(f"Missing required environment variables: {', '.join(missing_vars)}")
            logger.error("Please check your environment configuration or .env file")
            return None
        
        logger.info("Configuration loaded successfully from environment variables")
        return _config
        
    except Exception as e:
        logger.error(f"Error loading configuration: {e}")
        return None

def get_database_engine():
    """Get database engine with lazy loading and connection pooling"""
    global _db_engine
    if _db_engine is not None:
        return _db_engine
    
    try:
        config = load_config()
        if not config or not config.get('database_url'):
            logger.error("No database URL configured")
            return None
        
        # Create engine with connection timeout and retry logic
        _db_engine = create_engine(
            config['database_url'],
            pool_timeout=10,
            pool_recycle=3600,
            pool_pre_ping=True,
            connect_args={"connect_timeout": 10}
        )
        
        # Test connection
        with _db_engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        
        logger.info("Database connection established successfully")
        return _db_engine
        
    except Exception as e:
        logger.error(f"Database connection failed: {e}")
        _db_engine = None
        return None

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
        logger.info("Successfully parsed and validated JSON response")
        return json_obj
    except json.JSONDecodeError as e:
        logger.warning(f"Invalid JSON in API response: {e}")
        return None

def make_api_call(schema_summary: str, api_config: dict = None) -> dict:
    """Make an API call with the schema summary and configured prompt."""
    config = load_config()
    if not config:
        logger.error("No configuration available")
        return None
    
    # Start with defaults from environment configuration
    default_api_config = {
        'base_url': config.get('api_base_url'),
        'api_key': config.get('api_key'),
        'deployment_id': config.get('api_deployment_id', 'model-router'),
        'api_version': config.get('api_version', '2025-01-01-preview'),
        'max_tokens': config.get('api_max_tokens', 8192),
        'temperature': config.get('api_temperature', 0.7),
        'timeout': config.get('api_timeout', 60.0),
        'max_retries': config.get('api_max_retries', 3),
        'top_p': 0.95,
        'frequency_penalty': 0,
        'presence_penalty': 0,
        'model': 'model-router'
    }
    
    # Merge with any provided overrides
    if api_config:
        # Update defaults with any provided overrides
        default_api_config.update(api_config)
    
    # Use the merged configuration
    api_config = default_api_config
    
    base_url = api_config.get('base_url')
    deployment_id = api_config.get('deployment_id', 'model-router')
    api_version = api_config.get('api_version', '2025-01-01-preview')
    api_key = api_config.get('api_key')
    max_retries = api_config.get('max_retries', 3)
    
    if not all([base_url, api_key]):
        logger.error("Missing required API configuration (base_url, api_key)")
        return None
    
    # Default prompt template for glossary generation
    prompt_template = """Analyze this database schema and create a comprehensive business glossary in JSON format.
    
Schema: {schema_summary}

Create a hierarchical glossary that organizes business terms by categories. Use this exact JSON structure:

{{
  "Business Glossary": [
    {{
      "Customer & Demographics": [
        "Customer",
        "Customer Segment", 
        "Demographics",
        {{
          "Customer Lifecycle": [
            "Customer Acquisition",
            "Customer Retention"
          ]
        }}
      ]
    }},
    {{
      "Campaign & Marketing": [
        "Campaign",
        "Channel",
        "Campaign Performance"
      ]
    }}
  ]
}}

Rules:
1. Organize terms into logical business categories
2. Use array items for simple terms 
3. Use objects with arrays for subcategories
4. Include terms that business users would understand
5. Focus on business concepts, not technical database details
6. Return ONLY valid JSON, no explanations or markdown"""
    
    formatted_prompt = prompt_template.format(schema_summary=schema_summary)
    
    # Log the first 300 characters of the formatted prompt for debugging
    logger.info(f"Generated prompt for AI ({len(formatted_prompt)} chars): {formatted_prompt[:300]}{'...' if len(formatted_prompt) > 300 else ''}")
    
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
        logger.info(f"Making API call attempt {attempt}/{max_retries} to: {base_url}")
        
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
            
            logger.info(f"API response status: {response.status_code}")
            
            if response.status_code == 200:
                logger.info(f"API call attempt {attempt} successful")
                response_data = response.json()
                content = response_data.get("choices", [{}])[0].get("message", {}).get("content", "")
                
                # Log the first 200 characters of the response for debugging
                logger.info(f"AI response received ({len(content)} chars): {content[:200]}{'...' if len(content) > 200 else ''}")
                
                # Clean and validate JSON
                parsed_json = clean_and_validate_json(content)
                if parsed_json is not None:
                    logger.info(f"Valid JSON parsed successfully on attempt {attempt}")
                    return parsed_json
                else:
                    logger.warning(f"Invalid JSON received on attempt {attempt}, retrying...")
                    if attempt < max_retries:
                        # Modify the prompt slightly for retry to encourage better JSON
                        message["messages"][0]["content"] = formatted_prompt + " Please ensure your response is valid JSON only, without any markdown formatting or extra text."
                    continue
            else:
                logger.error(f"API call attempt {attempt} failed with status {response.status_code}: {response.text}")
                if attempt < max_retries:
                    continue
                
        except Exception as e:
            logger.error(f"API call attempt {attempt} error: {e}")
            if attempt < max_retries:
                continue
    
    logger.error(f"All {max_retries} API call attempts failed")
    return None

def create_schema_summary(engine, schema_name: str = None) -> str:
    """Create a concise summary of the database schema for API consumption."""
    try:
        with engine.connect() as conn:
            inspector = inspect(engine)
            
            if schema_name:
                tables = inspector.get_table_names(schema=schema_name)
            else:
                tables = inspector.get_table_names()
            
            table_count = len(tables)
            schema_prefix = f"Schema '{schema_name}': " if schema_name else "Database: "
            
            summary_parts = [f"{schema_prefix}{table_count} tables"]
            
            # Add table details
            table_details = []
            for table_name in tables:
                columns = inspector.get_columns(table_name, schema=schema_name)
                column_names = [col['name'] for col in columns]
                
                # Limit column names to keep summary concise
                if len(column_names) > 10:
                    column_summary = f"{', '.join(column_names[:10])}... ({len(column_names)} total columns)"
                else:
                    column_summary = ', '.join(column_names)
                
                table_details.append(f"Table {table_name}: {column_summary}")
            
            summary_parts.extend(table_details)
            schema_summary = '\n'.join(summary_parts)
            
            # Log the first 500 characters of the schema summary for debugging
            logger.info(f"Generated schema summary ({len(schema_summary)} chars): {schema_summary[:500]}{'...' if len(schema_summary) > 500 else ''}")
            return schema_summary
            
    except Exception as e:
        logger.error(f"Error creating schema summary: {e}")
        return f"Error: Unable to create schema summary - {str(e)}"

@app.route('/health')
def health():
    """Health check endpoint with database connectivity test"""
    health_status = {
        "status": "healthy",
        "message": "Service is running",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "checks": {
            "service": "ok"
        }
    }
    
    # Test database connection (non-blocking)
    try:
        engine = get_database_engine()
        if engine:
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            health_status["checks"]["database"] = "ok"
        else:
            health_status["checks"]["database"] = "unavailable"
            health_status["status"] = "degraded"
    except Exception as e:
        health_status["checks"]["database"] = f"error: {str(e)[:100]}"
        health_status["status"] = "degraded"
    
    return jsonify(health_status)

@app.route('/')
def home():
    """Basic home endpoint with configuration info"""
    config = load_config()
    
    return jsonify({
        "service": "Database Schema Glossary Generator",
        "status": "running",
        "version": "v2.1-unified-config",
        "endpoints": [
            "/health - Health check with database connectivity",
            "/config - Complete configuration with sources (env vars vs defaults)",
            "/analyze - POST: Generate AI-powered business glossary from database schema",
            "/docs - API documentation"
        ],
        "database_configured": bool(config and config.get('database_url')),
        "api_configured": bool(config and config.get('api_base_url') and config.get('api_key'))
    })

@app.route('/config')
def show_config():
    """Show complete configuration with sources and security masking"""
    config = load_config()
    
    if not config:
        return jsonify({
            "error": "Configuration not loaded",
            "message": "Please check your environment variables or .env file",
            "required_env_vars": ["DATABASE_URL", "API_BASE_URL", "API_KEY"],
            "help": "Copy .env.example to .env and fill in your values"
        }), 500
    
    # Track which values come from environment vs defaults
    config_with_sources = {}
    
    # Check each config value against environment variables
    env_mapping = {
        'database_url': 'DATABASE_URL',
        'database_schema': 'DATABASE_SCHEMA', 
        'api_base_url': 'API_BASE_URL',
        'api_key': 'API_KEY',
        'api_deployment_id': 'API_DEPLOYMENT_ID',
        'api_version': 'API_VERSION',
        'api_max_tokens': 'API_MAX_TOKENS',
        'api_temperature': 'API_TEMPERATURE',
        'api_timeout': 'API_TIMEOUT',
        'api_max_retries': 'API_MAX_RETRIES',
        'api_prompt_template': 'API_PROMPT_TEMPLATE',
        'port': 'PORT'
    }
    
    for key, value in config.items():
        env_var_name = env_mapping.get(key, key.upper())
        env_value = os.getenv(env_var_name)
        
        # Determine source
        if env_value is not None:
            source = "environment_variable"
            env_var = env_var_name
        else:
            source = "default_value"
            env_var = env_var_name
        
        # Apply security masking
        if value is None or value == '':
            masked_value = "NOT_SET"
        elif 'password' in key.lower() or 'key' in key.lower():
            if len(str(value)) > 8:
                masked_value = str(value)[:4] + "***" + str(value)[-4:]
            elif value:
                masked_value = "***"
            else:
                masked_value = "NOT_SET"
        elif 'url' in key.lower() and value and "@" in str(value):
            # Special handling for database URLs with credentials
            url_str = str(value)
            parts = url_str.split("://")
            if len(parts) == 2:
                protocol = parts[0]
                rest = parts[1]  
                if "@" in rest:
                    auth_part, host_part = rest.split("@", 1)
                    if ":" in auth_part:
                        user, _ = auth_part.split(":", 1)
                        masked_value = f"{protocol}://{user}:***@{host_part}"
                    else:
                        masked_value = f"{protocol}://{auth_part}:***@{host_part}"
                else:
                    masked_value = value
            else:
                masked_value = value
        else:
            masked_value = value
            
        config_with_sources[key] = {
            "value": masked_value,
            "source": source,
            "env_var": env_var
        }

    return jsonify({
        "service": "Database Schema Glossary Generator",
        "version": "v2.1-unified-config",
        "configuration": config_with_sources,
        "summary": {
            "total_settings": len(config_with_sources),
            "from_environment": len([c for c in config_with_sources.values() if c["source"] == "environment_variable"]),
            "using_defaults": len([c for c in config_with_sources.values() if c["source"] == "default_value"])
        },
        "setup_help": {
            "required_env_vars": ["DATABASE_URL", "API_BASE_URL", "API_KEY"],
            "optional_env_vars": [
                "DATABASE_SCHEMA", "API_DEPLOYMENT_ID", "API_VERSION",
                "API_MAX_TOKENS", "API_TEMPERATURE", "API_TIMEOUT", 
                "API_MAX_RETRIES", "API_PROMPT_TEMPLATE", "PORT"
            ],
            "local_development": "Copy .env.example to .env and edit with your values",
            "production": "Set environment variables in your deployment platform"
        },
        "note": "Sensitive data (passwords, API keys) are masked with *** for security"
    })

@app.route('/database/tables')
def list_tables():
    """List all tables in the configured database schema"""
    try:
        engine = get_database_engine()
        if not engine:
            return jsonify({"error": "Database connection not available"}), 503
        
        config = load_config()
        schema_name = config.get('database_schema') if config else None
        
        with engine.connect() as conn:
            inspector = inspect(engine)
            
            if schema_name:
                tables = inspector.get_table_names(schema=schema_name)
                return jsonify({
                    "schema": schema_name,
                    "tables": sorted(tables),
                    "count": len(tables)
                })
            else:
                tables = inspector.get_table_names()
                return jsonify({
                    "schema": "default",
                    "tables": sorted(tables),
                    "count": len(tables)
                })
                
    except Exception as e:
        logger.error(f"Error listing tables: {e}")
        return jsonify({
            "error": "Failed to list tables",
            "details": str(e)
        }), 500

@app.route('/database/schema/<table_name>')
def get_table_schema(table_name):
    """Get schema information for a specific table"""
    try:
        engine = get_database_engine()
        if not engine:
            return jsonify({"error": "Database connection not available"}), 503
        
        config = load_config()
        schema_name = config.get('database_schema') if config else None
        
        with engine.connect() as conn:
            inspector = inspect(engine)
            
            # Get columns with proper serialization
            columns = inspector.get_columns(table_name, schema=schema_name)
            serialized_columns = []
            
            for col in columns:
                col_info = {
                    "name": col["name"],
                    "type": str(col["type"]),
                    "nullable": col.get("nullable", True),
                    "default": str(col["default"]) if col.get("default") is not None else None,
                    "comment": col.get("comment")
                }
                serialized_columns.append(col_info)
            
            # Get primary keys
            pk_constraint = inspector.get_pk_constraint(table_name, schema=schema_name)
            
            # Get foreign keys with proper serialization
            foreign_keys = inspector.get_foreign_keys(table_name, schema=schema_name)
            serialized_fks = []
            
            for fk in foreign_keys:
                fk_info = {
                    "name": fk.get("name"),
                    "constrained_columns": fk.get("constrained_columns", []),
                    "referred_table": fk.get("referred_table"),
                    "referred_columns": fk.get("referred_columns", []),
                    "referred_schema": fk.get("referred_schema")
                }
                serialized_fks.append(fk_info)
            
            # Get indexes with proper serialization
            indexes = inspector.get_indexes(table_name, schema=schema_name)
            serialized_indexes = []
            
            for idx in indexes:
                idx_info = {
                    "name": idx.get("name"),
                    "column_names": idx.get("column_names", []),
                    "unique": idx.get("unique", False)
                }
                serialized_indexes.append(idx_info)
            
            return jsonify({
                "table_name": table_name,
                "schema": schema_name or "default",
                "columns": serialized_columns,
                "primary_keys": pk_constraint.get('constrained_columns', []),
                "foreign_keys": serialized_fks,
                "indexes": serialized_indexes,
                "column_count": len(serialized_columns)
            })
            
    except Exception as e:
        logger.error(f"Error getting table schema for {table_name}: {e}")
        return jsonify({
            "error": f"Failed to get schema for table '{table_name}'",
            "details": str(e)
        }), 500

@app.route('/analyze', methods=['POST'])
def analyze_schema():
    """Main endpoint to analyze database schema and generate AI-powered business glossary."""
    try:
        start_time = time.time()
        
        # Get configuration from request body (optional)
        request_data = request.get_json() or {}
        
        logger.info("Starting database schema analysis for glossary generation...")
        
        # Check if database configuration is provided in request
        request_db_config = request_data.get('database', {})
        if request_db_config:
            # Use database config from request
            db_url = request_db_config.get('url')
            schema_name = request_db_config.get('schema')
            
            if not db_url:
                return jsonify({
                    "success": False,
                    "error": "Database URL is required when providing database configuration",
                    "details": "Include 'url' in the database configuration object"
                }), 400
            
            # Create engine with request database config
            try:
                logger.info(f"Using database configuration from request")
                engine = create_engine(
                    db_url,
                    pool_timeout=10,
                    pool_recycle=3600,
                    pool_pre_ping=True,
                    connect_args={"connect_timeout": 10}
                )
                
                # Test the connection
                with engine.connect() as conn:
                    conn.execute(text("SELECT 1"))
                logger.info("Database connection from request config established successfully")
                
            except Exception as e:
                logger.error(f"Database connection failed with request config: {e}")
                return jsonify({
                    "success": False,
                    "error": "Database connection failed",
                    "details": f"Could not connect to database with provided configuration: {str(e)}"
                }), 503
        else:
            # Use default database engine
            engine = get_database_engine()
            if not engine:
                return jsonify({
                    "success": False,
                    "error": "Database connection not available",
                    "details": "Could not establish database connection. Check your DATABASE_URL configuration or provide database config in request."
                }), 503
            
            # Get schema name from default config
            config = load_config()
            schema_name = config.get('database_schema') if config else None
        
        # Create schema summary for API call
        schema_summary = create_schema_summary(engine, schema_name)
        logger.info("Schema summary created for AI analysis")
        
        # Extract API configuration from request or use defaults
        api_config = request_data.get('api', {}) if request_data else {}
        
        # Make API call with schema summary
        api_response = make_api_call(schema_summary, api_config if api_config else None)
        
        processing_time = round(time.time() - start_time, 2)
        
        # Get table count for metadata
        with engine.connect() as conn:
            inspector = inspect(engine)
            if schema_name:
                tables = inspector.get_table_names(schema=schema_name)
            else:
                tables = inspector.get_table_names()
            table_count = len(tables)
        
        if api_response:
            logger.info("AI-powered glossary generation completed successfully")
            return jsonify({
                "success": True,
                "data": api_response,
                "metadata": {
                    "tables_analyzed": table_count,
                    "schema_name": schema_name or "default",
                    "processing_time": processing_time,
                    "ai_model_used": api_config.get('model', 'model-router') if api_config else 'model-router',
                    "database_source": "request_override" if request_db_config else "environment_config"
                }
            })
        else:
            return jsonify({
                "success": False,
                "error": "AI analysis failed after all retry attempts",
                "details": "The AI service could not generate a valid glossary. Check your API configuration and try again.",
                "metadata": {
                    "tables_analyzed": table_count,
                    "schema_name": schema_name or "default",
                    "processing_time": processing_time
                }
            }), 500
            
    except Exception as e:
        logger.error(f"Error in analyze_schema: {e}")
        return jsonify({
            "success": False,
            "error": "Internal server error during analysis",
            "details": str(e)
        }), 500

@app.route('/docs', methods=['GET'])
def documentation():
    """API documentation endpoint."""
    config = load_config()
    
    # Get actual default values from configuration
    masked_db_url = ""
    masked_api_key = ""
    default_base_url = ""
    default_schema = ""
    
    if config:
        db_url = config.get('database_url', '')
        if db_url and "@" in db_url:
            parts = db_url.split("://")
            if len(parts) == 2:
                protocol = parts[0]
                rest = parts[1]  
                if "@" in rest:
                    auth_part, host_part = rest.split("@", 1)
                    if ":" in auth_part:
                        user, _ = auth_part.split(":", 1)
                        masked_db_url = f"{protocol}://{user}:***@{host_part}"
        else:
            masked_db_url = db_url if db_url else "NOT_CONFIGURED"
        
        api_key = config.get('api_key', '')
        if len(api_key) > 8:
            masked_api_key = api_key[:4] + "***" + api_key[-4:]
        elif api_key:
            masked_api_key = "***"
        else:
            masked_api_key = "NOT_CONFIGURED"
        
        default_base_url = config.get('api_base_url', '') or "NOT_CONFIGURED"
        default_schema = config.get('database_schema', '') or "public"
    
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
        <p>Generate AI-powered business glossaries from database schemas using advanced language models.</p>
        
        <div class="endpoint">
            <h3><span class="method post">POST</span> /analyze</h3>
            <p>Analyzes a database schema and generates a hierarchical business glossary using AI.</p>
            <p><strong>Note:</strong> All parameters are optional. Environment variables provide defaults, and any request parameters override/merge with those defaults.</p>
            
            <h4>Request Body (JSON) - Optional overrides:</h4>
            <pre>{{
  "database": {{
    "url": "<span class=\"optional\">string</span> - Override database URL (current: {masked_db_url})",
    "schema": "<span class=\"optional\">string</span> - Override schema name (current: {default_schema})"
  }},
  "api": {{
    "base_url": "<span class=\"optional\">string</span> - Override API base URL (current: {default_base_url})",
    "api_key": "<span class=\"optional\">string</span> - Override API key (current: {masked_api_key})",
    "deployment_id": "<span class=\"optional\">string</span> - Deployment ID (default: 'model-router')",
    "api_version": "<span class=\"optional\">string</span> - API version (default: '2025-01-01-preview')",
    "max_tokens": "<span class=\"optional\">number</span> - Max response tokens (default: 8192)",
    "temperature": "<span class=\"optional\">number</span> - AI temperature 0-1 (default: 0.7)",
    "timeout": "<span class=\"optional\">number</span> - Request timeout in seconds (default: 60)",
    "max_retries": "<span class=\"optional\">number</span> - Max retry attempts (default: 3)"
  }}
}}</pre>

            <h4>Simple Example Request (use all defaults):</h4>
            <pre>POST /analyze
Content-Type: application/json

{{}}</pre>

            <h4>Database Override Example (merge with API defaults):</h4>
            <pre>{{
  "database": {{
    "url": "postgresql://user:pass@host:port/dbname?sslmode=require",
    "schema": "my_schema"
  }}
}}</pre>

            <h4>API Override Example (merge with database defaults):</h4>
            <pre>{{
  "api": {{
    "temperature": 0.3,
    "max_retries": 5
  }}
}}</pre>

            <h4>Full Override Example:</h4>
            <pre>{{
  "database": {{
    "url": "postgresql://user:pass@host:port/dbname?sslmode=require", 
    "schema": "custom_schema"
  }},
  "api": {{
    "temperature": 0.3,
    "max_retries": 5
  }}
}}</pre>

            <h4>Response:</h4>
            <pre>{{
  "success": true,
  "data": {{
    "Business Glossary": [
      {{
        "Customer & Demographics": [
          "Customer",
          "Customer Segment",
          {{
            "Customer Lifecycle": [
              "Customer Acquisition",
              "Customer Retention"
            ]
          }}
        ]
      }},
      {{
        "Campaign & Marketing": [
          "Campaign",
          "Channel", 
          "Campaign Performance"
        ]
      }}
    ]
  }},
  "metadata": {{
    "tables_analyzed": 7,
    "schema_name": "{default_schema}",
    "processing_time": 2.3,
    "ai_model_used": "model-router"
  }}
}}</pre>
        </div>
        
        <div class="endpoint">
            <h3><span class="method get">GET</span> /config</h3>
            <p>View current configuration status (sensitive data masked).</p>
        </div>

        <div class="endpoint">
            <h3><span class="method get">GET</span> /health</h3>
            <p>Check service health with database connectivity test.</p>
            <h4>Response:</h4>
            <pre>{{
  "status": "healthy",
  "timestamp": "2025-08-01T18:39:47.267694Z",
  "checks": {{
    "service": "ok",
    "database": "ok"
  }}
}}</pre>
        </div>

        <h3>Configuration</h3>
        <p>Set these environment variables:</p>
        <ul>
            <li><strong>DATABASE_URL</strong> - PostgreSQL connection string (current: {masked_db_url})</li>
            <li><strong>DATABASE_SCHEMA</strong> - Schema name (current: {default_schema})</li>
            <li><strong>API_BASE_URL</strong> - AI API endpoint (current: {default_base_url})</li>
            <li><strong>API_KEY</strong> - AI API key (current: {masked_api_key})</li>
            <li><strong>API_DEPLOYMENT_ID</strong> - Model deployment ID (optional)</li>
            <li><strong>API_VERSION</strong> - API version (optional)</li>
        </ul>

        <h3>Error Responses</h3>
        <p>All endpoints return error responses in this format:</p>
        <pre>{{
  "success": false,
  "error": "Error description",
  "details": "Additional error details (optional)"
}}</pre>

        <h3>Common Error Codes</h3>
        <ul>
            <li><strong>400</strong> - Bad Request (invalid JSON)</li>
            <li><strong>500</strong> - Internal Server Error (database connection, API call failures)</li>
            <li><strong>503</strong> - Service Unavailable (database not accessible)</li>
        </ul>
    </body>
    </html>
    """
    return docs_html

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
