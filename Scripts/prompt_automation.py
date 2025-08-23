#!/usr/bin/env python3
"""
Prompt Automation Script for 2025 AI Models
==========================================

This script provides automated prompt engineering workflows for GPT-5, Claude 4.1, and XAI Grok.
It includes validation, optimization, and batch processing capabilities.

Author: Prompting-Gold-Standard Community
Version: 1.0.0 (2025)
License: MIT
"""

import os
import json
import time
import logging
from typing import Dict, List, Optional, Any
from datetime import datetime
from dataclasses import dataclass
import asyncio
from concurrent.futures import ThreadPoolExecutor
import requests
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('prompt_automation.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

@dataclass
class ModelConfig:
    """Configuration for different AI models"""
    name: str
    api_key_env: str
    base_url: str
    max_tokens: int
    temperature: float
    context_window: int
    supports_streaming: bool = False
    supports_json_mode: bool = False

class PromptAutomation:
    """
    Comprehensive prompt automation system for 2025 AI models

    Features:
    - Multi-model support (GPT-5, Claude 4.1, Grok)
    - Batch processing capabilities
    - Content validation and optimization
    - Performance monitoring
    - Cost optimization
    """

    def __init__(self):
        self.models = {
            'gpt-5': ModelConfig(
                name='GPT-5',
                api_key_env='OPENAI_API_KEY',
                base_url='https://api.openai.com/v1',
                max_tokens=8192,
                temperature=0.7,
                context_window=128000,
                supports_streaming=True,
                supports_json_mode=True
            ),
            'claude-4.1': ModelConfig(
                name='Claude 4.1',
                api_key_env='ANTHROPIC_API_KEY',
                base_url='https://api.anthropic.com/v1',
                max_tokens=8192,
                temperature=0.7,
                context_window=200000,
                supports_streaming=True,
                supports_json_mode=True
            ),
            'grok-4': ModelConfig(
                name='Grok-4',
                api_key_env='XAI_API_KEY',
                base_url='https://api.x.ai/v1',
                max_tokens=8192,
                temperature=0.7,
                context_window=128000,
                supports_streaming=True,
                supports_json_mode=True
            )
        }

        self.executor = ThreadPoolExecutor(max_workers=3)
        self.session_stats = {
            'total_requests': 0,
            'successful_requests': 0,
            'failed_requests': 0,
            'total_tokens': 0,
            'total_cost': 0.0
        }

    def validate_api_keys(self) -> Dict[str, bool]:
        """Validate that required API keys are available"""
        key_status = {}
        for model_name, config in self.models.items():
            api_key = os.getenv(config.api_key_env)
            key_status[model_name] = api_key is not None and len(api_key) > 0

            if key_status[model_name]:
                logger.info(f"✅ API key found for {model_name}")
            else:
                logger.warning(f"❌ API key missing for {model_name}")

        return key_status

    async def query_model(self, model_name: str, prompt: str,
                         temperature: Optional[float] = None,
                         max_tokens: Optional[int] = None,
                         json_mode: bool = False) -> Dict[str, Any]:
        """Query a specific model with optimized parameters"""

        if model_name not in self.models:
            raise ValueError(f"Unknown model: {model_name}")

        config = self.models[model_name]
        api_key = os.getenv(config.api_key_env)

        if not api_key:
            raise ValueError(f"API key not found for {model_name}")

        # Use provided parameters or defaults
        temp = temperature if temperature is not None else config.temperature
        max_tok = max_tokens if max_tokens is not None else config.max_tokens

        try:
            start_time = time.time()

            if model_name == 'gpt-5':
                response = await self._query_openai(config, api_key, prompt, temp, max_tok, json_mode)
            elif model_name == 'claude-4.1':
                response = await self._query_anthropic(config, api_key, prompt, temp, max_tok, json_mode)
            elif model_name == 'grok-4':
                response = await self._query_xai(config, api_key, prompt, temp, max_tok, json_mode)
            else:
                raise ValueError(f"Model {model_name} not implemented")

            end_time = time.time()

            # Update statistics
            self.session_stats['total_requests'] += 1
            self.session_stats['successful_requests'] += 1

            return {
                'model': model_name,
                'response': response,
                'tokens_used': len(response.split()),  # Rough estimate
                'processing_time': end_time - start_time,
                'temperature': temp,
                'max_tokens': max_tok,
                'success': True
            }

        except Exception as e:
            logger.error(f"Error querying {model_name}: {str(e)}")
            self.session_stats['total_requests'] += 1
            self.session_stats['failed_requests'] += 1

            return {
                'model': model_name,
                'response': None,
                'error': str(e),
                'success': False
            }

    async def _query_openai(self, config: ModelConfig, api_key: str,
                           prompt: str, temp: float, max_tokens: int, json_mode: bool) -> str:
        """Query OpenAI GPT-5 model"""
        import openai

        client = openai.AsyncOpenAI(api_key=api_key)

        messages = [{"role": "user", "content": prompt}]
        response_format = {"type": "json_object"} if json_mode else {"type": "text"}

        response = await client.chat.completions.create(
            model="gpt-5",
            messages=messages,
            temperature=temp,
            max_tokens=max_tokens,
            response_format=response_format
        )

        return response.choices[0].message.content

    async def _query_anthropic(self, config: ModelConfig, api_key: str,
                              prompt: str, temp: float, max_tokens: int, json_mode: bool) -> str:
        """Query Anthropic Claude 4.1 model"""
        import anthropic

        client = anthropic.AsyncAnthropic(api_key=api_key)

        system_prompt = "You are Claude 4.1, a helpful AI assistant." + \
                       (" Respond with valid JSON only." if json_mode else "")

        response = await client.messages.create(
            model="claude-4-1-opus-20241221",
            max_tokens=max_tokens,
            temperature=temp,
            system=system_prompt,
            messages=[{"role": "user", "content": prompt}]
        )

        return response.content[0].text

    async def _query_xai(self, config: ModelConfig, api_key: str,
                        prompt: str, temp: float, max_tokens: int, json_mode: bool) -> str:
        """Query XAI Grok model"""
        headers = {
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'application/json'
        }

        data = {
            'model': 'grok-4',
            'messages': [{'role': 'user', 'content': prompt}],
            'temperature': temp,
            'max_tokens': max_tokens
        }

        if json_mode:
            data['response_format'] = {'type': 'json_object'}

        async with aiohttp.ClientSession() as session:
            async with session.post(f"{config.base_url}/chat/completions", headers=headers, json=data) as response:
                result = await response.json()
                return result['choices'][0]['message']['content']

    async def batch_process(self, tasks: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Process multiple prompts in batch"""

        async def process_single_task(task):
            return await self.query_model(
                task['model'],
                task['prompt'],
                task.get('temperature'),
                task.get('max_tokens'),
                task.get('json_mode', False)
            )

        # Process tasks concurrently
        results = await asyncio.gather(
            *[process_single_task(task) for task in tasks],
            return_exceptions=True
        )

        # Handle any exceptions
        processed_results = []
        for i, result in enumerate(results):
            if isinstance(result, Exception):
                logger.error(f"Task {i} failed with error: {str(result)}")
                processed_results.append({
                    'task_id': i,
                    'success': False,
                    'error': str(result)
                })
            else:
                processed_results.append(result)

        return processed_results

    def optimize_prompt(self, base_prompt: str, target_model: str = 'gpt-5') -> str:
        """Optimize a prompt for a specific model"""

        optimizations = {
            'gpt-5': [
                "Be specific about the desired output format",
                "Include context about your expertise level",
                "Request step-by-step reasoning for complex tasks",
                "Specify the desired tone and style",
                "Include examples for complex tasks"
            ],
            'claude-4.1': [
                "Focus on constitutional AI principles",
                "Provide clear ethical guidelines",
                "Emphasize helpfulness and accuracy",
                "Include safety considerations",
                "Request comprehensive analysis"
            ],
            'grok-4': [
                "Leverage real-time information access",
                "Include humor when appropriate",
                "Request witty and engaging responses",
                "Focus on truth-seeking approaches",
                "Include current event analysis"
            ]
        }

        model_opts = optimizations.get(target_model, [])

        optimized = f"""You are working with {target_model.upper()}, an advanced AI model with specific capabilities.

Task: {base_prompt}

Optimization Guidelines for {target_model.upper()}:
{chr(10).join(f"- {opt}" for opt in model_opts)}

Please provide your response using these optimized guidelines."""

        return optimized

    def validate_content(self, content: str, content_type: str = 'academic') -> Dict[str, Any]:
        """Validate AI-generated content for quality and accuracy"""

        validation_criteria = {
            'academic': {
                'required_elements': ['citations', 'methodology', 'conclusion'],
                'quality_checks': ['factual_accuracy', 'logical_flow', 'academic_tone'],
                'word_count_range': (500, 5000)
            },
            'technical': {
                'required_elements': ['code_examples', 'specifications', 'implementation_details'],
                'quality_checks': ['technical_accuracy', 'completeness', 'clarity'],
                'word_count_range': (300, 3000)
            },
            'creative': {
                'required_elements': ['original_ideas', 'engaging_content', 'appropriate_style'],
                'quality_checks': ['creativity', 'engagement', 'style_consistency'],
                'word_count_range': (200, 2000)
            }
        }

        if content_type not in validation_criteria:
            raise ValueError(f"Unknown content type: {content_type}")

        criteria = validation_criteria[content_type]
        word_count = len(content.split())

        # Basic validation checks
        validation_results = {
            'word_count': word_count,
            'word_count_appropriate': criteria['word_count_range'][0] <= word_count <= criteria['word_count_range'][1],
            'has_required_elements': all(element in content.lower() for element in criteria['required_elements']),
            'content_length_score': min(10, max(1, word_count // 100)),  # Rough scoring
            'overall_quality_score': 7  # Placeholder for more sophisticated scoring
        }

        return validation_results

    def generate_report(self, results: List[Dict[str, Any]]) -> str:
        """Generate a comprehensive report of automation results"""

        successful_requests = sum(1 for r in results if r.get('success', False))
        total_requests = len(results)

        report = f"""
# Prompt Automation Report
Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## Summary Statistics
- Total Requests: {total_requests}
- Successful Requests: {successful_requests}
- Success Rate: {successful_requests/total_requests*100:.1f}%
- Failed Requests: {total_requests - successful_requests}

## Model Performance
"""

        # Group results by model
        model_results = {}
        for result in results:
            model = result.get('model', 'unknown')
            if model not in model_results:
                model_results[model] = []
            model_results[model].append(result)

        for model, model_data in model_results.items():
            successful = sum(1 for r in model_data if r.get('success', False))
            avg_time = sum(r.get('processing_time', 0) for r in model_data if r.get('success', False)) / max(successful, 1)

            report += f"""
### {model.upper()}
- Requests: {len(model_data)}
- Success Rate: {successful/len(model_data)*100:.1f}%
- Average Processing Time: {avg_time:.2f}s
"""

        report += "\n## Detailed Results\n"

        for i, result in enumerate(results):
            report += f"\n### Request {i+1}\n"
            report += f"- Model: {result.get('model', 'N/A')}\n"
            report += f"- Success: {result.get('success', False)}\n"

            if result.get('success'):
                report += f"- Processing Time: {result.get('processing_time', 0):.2f}s\n"
                report += f"- Response Length: {len(result.get('response', ''))} characters\n"
            else:
                report += f"- Error: {result.get('error', 'Unknown error')}\n"

        return report

async def main():
    """Main automation function with example usage"""

    # Initialize the automation system
    automation = PromptAutomation()

    # Validate API keys
    key_status = automation.validate_api_keys()
    logger.info(f"API Key Status: {key_status}")

    # Example prompts for different use cases
    prompts = {
        'academic': "Analyze the impact of AI on academic research methodologies in 2025. Provide specific examples and cite recent developments.",
        'technical': "Create a Python function to validate JSON output from AI models using schema validation. Include error handling and type checking.",
        'creative': "Write a short story about the future of human-AI collaboration in scientific research, focusing on ethical considerations."
    }

    # Create batch tasks
    batch_tasks = []
    for content_type, prompt in prompts.items():
        for model in ['gpt-5', 'claude-4.1', 'grok-4']:
            if key_status.get(model, False):  # Only add if API key is available
                optimized_prompt = automation.optimize_prompt(prompt, model)
                batch_tasks.append({
                    'model': model,
                    'prompt': optimized_prompt,
                    'content_type': content_type,
                    'temperature': 0.7 if content_type != 'technical' else 0.3
                })

    # Process batch tasks
    if batch_tasks:
        logger.info(f"Processing {len(batch_tasks)} batch tasks...")
        results = await automation.batch_process(batch_tasks)

        # Validate results
        for result in results:
            if result.get('success') and result.get('response'):
                content_type = next((t['content_type'] for t in batch_tasks
                                   if t['model'] == result['model']), 'academic')
                validation = automation.validate_content(result['response'], content_type)
                result['validation'] = validation

        # Generate report
        report = automation.generate_report(results)
        print(report)

        # Save report to file
        with open('automation_report.md', 'w') as f:
            f.write(report)

        logger.info("Automation completed successfully!")
    else:
        logger.warning("No valid API keys found. Please configure API keys to run automation.")

if __name__ == "__main__":
    try:
        # Check if running in Jupyter or as script
        import sys
        if 'ipykernel' in sys.modules:
            # Running in Jupyter - use nest_asyncio
            import nest_asyncio
            nest_asyncio.apply()
            asyncio.run(main())
        else:
            # Running as script
            asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("Automation interrupted by user")
    except Exception as e:
        logger.error(f"Automation failed: {str(e)}")
