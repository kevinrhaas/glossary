# read from a database schema provided from a config file
import os
import json 
import logging
import httpx
from typing import Dict, Any
from sqlalchemy import create_engine, MetaData, Table
from sqlalchemy.orm import sessionmaker

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
def load_config(config_path: str) -> Dict[str, Any]:
    """Load configuration from a JSON file."""
    if not os.path.exists(config_path):
        raise FileNotFoundError(f"Configuration file not found: {config_path}")
    
    logging.info(f"Loading configuration from: {config_path}")
    with open(config_path, 'r') as file:
        config = json.load(file)
    
    logging.info("Configuration loaded successfully")
    return config


def create_database_engine(config: Dict[str, Any]):
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


logging.info("Starting database schema analysis...")
config = load_config("config.json")
engine = create_database_engine(config)

# Get schema name from config if specified
schema_name = config.get("database", {}).get("schema")
metadata = reflect_schema(engine, schema_name)

# Create schema summary for API call
schema_summary = create_schema_summary(metadata, schema_name)
logging.info("Schema summary created for API call")

# Make API call with schema summary
api_response = make_api_call(config, schema_summary)
if api_response:
    logging.info("API analysis completed successfully")
    print("\n" + "="*50)
    print("AI ANALYSIS RESULT (JSON):")
    print("="*50)
    print(json.dumps(api_response, indent=2))
    print("="*50)
else:
    logging.warning("API call was skipped or failed")

logging.info("Listing all table names:")
for table in metadata.tables:
    print(table)  # prints each table name
logging.info("Schema analysis complete")
