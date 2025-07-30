## pip install httpx

import httpx
import json

deploymentId = 'model-router'
api_version = '2025-01-01-preview'

message = {"messages": [
                        {
                            "role": "user",
                            "content": "Write a comprehensive account of solo backpacking adventure through South America, covering countries like Colombia, Peru, Bolivia, and Argentina. Detail the challenges and triumphs of traveling solo, your interactions with locals, and the cultural diversity you encountered along the way. Include must-visit attractions, unique experiences like hiking the Inca Trail or exploring Patagonia, and recommendations for budget travelers. Provide a structured itinerary, a cost breakdown, and safety tips for solo adventurers in the region."
                        }
                    ],
                    "max_tokens": 8192,
                    "temperature": 0.7,
                    "top_p": 0.95,
                    "frequency_penalty": 0,
                    "presence_penalty": 0,
                    "model": "model-router"
                }
data = json.dumps(message)

base_url = "rg-llm-api-management.azure-api.net/openai-presales"

r = httpx.post(f'http://{base_url}/deployments/{deploymentId}/chat/completions?api-version={api_version}',
               headers={'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*',
                        'Access-Control-Allow-Credentials': 'true',
                        'api-key':'9a86acaf479142db935eb1691307d568'},
               data=data,
               timeout=60.0)

print(r)
print(r.content)
print(r.url)