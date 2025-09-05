#!/usr/bin/env python3
"""
Schema Validator and Quality Assurance Framework

This script provides comprehensive validation for JSON schemas and outputs
from the Prompting-Gold-Standard repository. It includes:

- JSON Schema validation against predefined schemas
- Batch processing of multiple files
- Quality scoring and reporting
- Automated testing integration
- Detailed error reporting and suggestions

Usage:
    python schema-validator.py [options] [files...]

Options:
    --schema-dir DIR    Directory containing JSON schemas (default: ../JSON-Schemas)
    --batch             Process all files in batch mode
    --report            Generate detailed HTML report
    --strict            Fail on first validation error
    --quiet             Suppress non-error output
    --help             Show this help message

Examples:
    # Validate a single file
    python schema-validator.py output.json

    # Batch validate all quickstart outputs
    python schema-validator.py --batch --schema-dir ../JSON-Schemas

    # Generate detailed report
    python schema-validator.py --report --batch > validation_report.html
"""

import json
import jsonschema
import argparse
import sys
import os
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

@dataclass
class ValidationResult:
    """Result of a single validation operation."""
    file_path: str
    schema_name: str
    is_valid: bool
    errors: List[str]
    warnings: List[str]
    score: float
    metadata: Dict[str, Any]

@dataclass
class ValidationReport:
    """Comprehensive validation report."""
    timestamp: datetime
    total_files: int
    valid_files: int
    invalid_files: int
    total_score: float
    results: List[ValidationResult]
    summary: Dict[str, Any]

class SchemaValidator:
    """Main schema validation engine."""

    def __init__(self, schema_dir: str = "../JSON-Schemas"):
        self.schema_dir = Path(schema_dir)
        self.schemas: Dict[str, Dict] = {}
        self.load_schemas()

    def load_schemas(self) -> None:
        """Load all JSON schemas from the schema directory."""
        if not self.schema_dir.exists():
            logger.warning(f"Schema directory {self.schema_dir} does not exist")
            return

        for schema_file in self.schema_dir.glob("*.json"):
            try:
                with open(schema_file, 'r', encoding='utf-8') as f:
                    schema = json.load(f)
                    schema_name = schema_file.stem
                    self.schemas[schema_name] = schema
                    logger.info(f"Loaded schema: {schema_name}")
            except Exception as e:
                logger.error(f"Failed to load schema {schema_file}: {e}")

    def detect_schema_type(self, data: Dict) -> Optional[str]:
        """Auto-detect the appropriate schema based on data content."""
        # Schema detection logic based on data structure
        if 'image_metadata' in data and 'quality_assessment' in data:
            return 'image-analysis'
        elif 'stream_metadata' in data and 'data_schema' in data:
            return 'streaming-data'
        elif 'message_id' in data and 'sender_agent' in data:
            return 'agent-communication'
        elif 'findings' in data and 'hypothesis' in data:
            return 'research-analysis'
        else:
            return 'research-analysis'  # Default fallback

    def validate_file(self, file_path: str, schema_name: Optional[str] = None) -> ValidationResult:
        """Validate a single JSON file against a schema."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
        except Exception as e:
            return ValidationResult(
                file_path=file_path,
                schema_name=schema_name or 'unknown',
                is_valid=False,
                errors=[f"Failed to load JSON: {e}"],
                warnings=[],
                score=0.0,
                metadata={}
            )

        # Auto-detect schema if not provided
        if not schema_name:
            schema_name = self.detect_schema_type(data)

        # Get the appropriate schema
        schema = self.schemas.get(schema_name)
        if not schema:
            return ValidationResult(
                file_path=file_path,
                schema_name=schema_name,
                is_valid=False,
                errors=[f"Schema '{schema_name}' not found"],
                warnings=[],
                score=0.0,
                metadata={}
            )

        # Perform validation
        errors = []
        warnings = []
        score = 100.0

        try:
            jsonschema.validate(data, schema)
            logger.info(f"✅ {file_path} validates against {schema_name}")
        except jsonschema.ValidationError as e:
            errors.append(f"Schema validation error: {e.message}")
            score -= 50  # Major penalty for schema errors
        except jsonschema.SchemaError as e:
            errors.append(f"Schema error: {e.message}")
            score = 0

        # Additional quality checks
        score, additional_warnings = self.perform_quality_checks(data, schema_name)
        warnings.extend(additional_warnings)

        # Calculate final score
        final_score = max(0.0, min(100.0, score))

        return ValidationResult(
            file_path=file_path,
            schema_name=schema_name,
            is_valid=len(errors) == 0,
            errors=errors,
            warnings=warnings,
            score=final_score,
            metadata={
                'file_size': os.path.getsize(file_path),
                'data_keys': list(data.keys()) if isinstance(data, dict) else [],
                'schema_version': schema.get('$id', 'unknown')
            }
        )

    def perform_quality_checks(self, data: Dict, schema_name: str) -> Tuple[float, List[str]]:
        """Perform additional quality checks beyond basic schema validation."""
        score_penalty = 0
        warnings = []

        # Schema-specific quality checks
        if schema_name == 'image-analysis':
            score_penalty, warnings = self.check_image_analysis_quality(data)
        elif schema_name == 'streaming-data':
            score_penalty, warnings = self.check_streaming_data_quality(data)
        elif schema_name == 'agent-communication':
            score_penalty, warnings = self.check_agent_communication_quality(data)
        elif schema_name == 'research-analysis':
            score_penalty, warnings = self.check_research_analysis_quality(data)

        # General quality checks
        if isinstance(data, dict):
            # Check for empty required fields
            for key, value in data.items():
                if value is None or (isinstance(value, (list, str)) and len(value) == 0):
                    warnings.append(f"Empty or null field: {key}")
                    score_penalty += 5

        return score_penalty, warnings

    def check_image_analysis_quality(self, data: Dict) -> Tuple[float, List[str]]:
        """Quality checks specific to image analysis results."""
        penalty = 0
        warnings = []

        # Check confidence scores
        if 'content_analysis' in data:
            for element in data['content_analysis'].get('key_elements', []):
                confidence = element.get('confidence', 0)
                if confidence < 0.5:
                    warnings.append(f"Low confidence score: {confidence} for element {element.get('element_type', 'unknown')}")
                    penalty += 10

        # Check for required medical fields in medical domain
        if data.get('domain_specific_analysis', {}).get('domain') == 'medical':
            findings = data.get('domain_specific_analysis', {}).get('findings', [])
            if len(findings) == 0:
                warnings.append("No findings recorded for medical image analysis")
                penalty += 20

        return penalty, warnings

    def check_streaming_data_quality(self, data: Dict) -> Tuple[float, List[str]]:
        """Quality checks specific to streaming data configurations."""
        penalty = 0
        warnings = []

        # Check for monitoring configuration
        if not data.get('monitoring_configuration', {}).get('metrics_collection', {}).get('enabled', False):
            warnings.append("Metrics collection not enabled for streaming pipeline")
            penalty += 15

        # Check for alerting configuration
        alert_rules = data.get('alerting_configuration', {}).get('alert_rules', [])
        if len(alert_rules) == 0:
            warnings.append("No alert rules configured for streaming pipeline")
            penalty += 20

        # Check for auto-scaling
        if not data.get('scaling_configuration', {}).get('auto_scaling', {}).get('enabled', False):
            warnings.append("Auto-scaling not enabled for streaming pipeline")
            penalty += 10

        return penalty, warnings

    def check_agent_communication_quality(self, data: Dict) -> Tuple[float, List[str]]:
        """Quality checks specific to agent communication."""
        penalty = 0
        warnings = []

        # Check for response requirements
        if data.get('requires_response', False):
            if not data.get('response_deadline'):
                warnings.append("Response required but no deadline specified")
                penalty += 15

        # Check message type validity
        valid_types = [
            "task_assignment", "progress_update", "result_delivery",
            "error_report", "coordination_request", "status_check"
        ]
        if data.get('message_type') not in valid_types:
            warnings.append(f"Invalid message type: {data.get('message_type')}")
            penalty += 10

        # Check for security context
        if not data.get('security_context'):
            warnings.append("No security context specified for agent communication")
            penalty += 5

        return penalty, warnings

    def check_research_analysis_quality(self, data: Dict) -> Tuple[float, List[str]]:
        """Quality checks specific to research analysis."""
        penalty = 0
        warnings = []

        # Check for methodology section
        if 'methodology' not in data:
            warnings.append("Missing methodology section in research analysis")
            penalty += 25

        # Check for evidence citations
        findings = data.get('findings', [])
        uncited_findings = 0
        for finding in findings:
            if not finding.get('evidence') or len(finding.get('evidence', [])) == 0:
                uncited_findings += 1

        if uncited_findings > 0:
            warnings.append(f"{uncited_findings} findings lack evidence citations")
            penalty += uncited_findings * 5

        return penalty, warnings

    def batch_validate(self, file_patterns: List[str]) -> ValidationReport:
        """Validate multiple files in batch mode."""
        results = []

        for pattern in file_patterns:
            path = Path(pattern)
            if path.is_file():
                result = self.validate_file(str(path))
                results.append(result)
            elif path.is_dir() or '*' in pattern:
                for file_path in Path('.').glob(pattern):
                    if file_path.is_file() and file_path.suffix == '.json':
                        result = self.validate_file(str(file_path))
                        results.append(result)

        # Generate summary
        total_files = len(results)
        valid_files = sum(1 for r in results if r.is_valid)
        invalid_files = total_files - valid_files
        avg_score = sum(r.score for r in results) / total_files if total_files > 0 else 0

        summary = {
            'total_files': total_files,
            'valid_files': valid_files,
            'invalid_files': invalid_files,
            'average_score': round(avg_score, 2),
            'validation_rate': round(valid_files / total_files * 100, 2) if total_files > 0 else 0
        }

        return ValidationReport(
            timestamp=datetime.now(),
            total_files=total_files,
            valid_files=valid_files,
            invalid_files=invalid_files,
            total_score=round(avg_score, 2),
            results=results,
            summary=summary
        )

    def generate_html_report(self, report: ValidationReport) -> str:
        """Generate an HTML report from validation results."""
        html = f"""
<!DOCTYPE html>
<html>
<head>
    <title>Schema Validation Report</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 40px; }}
        .summary {{ background: #f0f0f0; padding: 20px; border-radius: 5px; margin-bottom: 20px; }}
        .result {{ margin-bottom: 10px; padding: 10px; border: 1px solid #ddd; }}
        .valid {{ background: #d4edda; border-color: #c3e6cb; }}
        .invalid {{ background: #f8d7da; border-color: #f5c6cb; }}
        .errors {{ color: #721c24; }}
        .warnings {{ color: #856404; }}
        .score {{ font-weight: bold; }}
        table {{ border-collapse: collapse; width: 100%; }}
        th, td {{ border: 1px solid #ddd; padding: 8px; text-align: left; }}
        th {{ background-color: #f2f2f2; }}
    </style>
</head>
<body>
    <h1>Schema Validation Report</h1>
    <div class="summary">
        <h2>Summary</h2>
        <p><strong>Generated:</strong> {report.timestamp.strftime('%Y-%m-%d %H:%M:%S')}</p>
        <p><strong>Total Files:</strong> {report.total_files}</p>
        <p><strong>Valid Files:</strong> {report.valid_files}</p>
        <p><strong>Invalid Files:</strong> {report.invalid_files}</p>
        <p><strong>Average Score:</strong> {report.total_score}%</p>
        <p><strong>Validation Rate:</strong> {report.summary['validation_rate']}%</p>
    </div>

    <h2>Detailed Results</h2>
"""

        for result in report.results:
            status_class = "valid" if result.is_valid else "invalid"
            html += f"""
    <div class="result {status_class}">
        <h3>{result.file_path}</h3>
        <p><strong>Schema:</strong> {result.schema_name}</p>
        <p><strong>Score:</strong> <span class="score">{result.score}%</span></p>
"""

            if result.errors:
                html += '<div class="errors"><strong>Errors:</strong><ul>'
                for error in result.errors:
                    html += f'<li>{error}</li>'
                html += '</ul></div>'

            if result.warnings:
                html += '<div class="warnings"><strong>Warnings:</strong><ul>'
                for warning in result.warnings:
                    html += f'<li>{warning}</li>'
                html += '</ul></div>'

            html += '</div>'

        html += """
</body>
</html>
"""

        return html

def main():
    parser = argparse.ArgumentParser(description="Schema Validator for Prompting-Gold-Standard")
    parser.add_argument('files', nargs='*', help='JSON files to validate')
    parser.add_argument('--schema-dir', default='../JSON-Schemas', help='Directory containing schemas')
    parser.add_argument('--batch', action='store_true', help='Process all JSON files in current directory')
    parser.add_argument('--report', action='store_true', help='Generate HTML report')
    parser.add_argument('--strict', action='store_true', help='Fail on first validation error')
    parser.add_argument('--quiet', action='store_true', help='Suppress non-error output')

    args = parser.parse_args()

    if args.quiet:
        logger.setLevel(logging.ERROR)

    validator = SchemaValidator(args.schema_dir)

    if args.batch:
        # Batch process all JSON files
        report = validator.batch_validate(['*.json'])
    elif args.files:
        # Process specific files
        results = []
        for file_path in args.files:
            result = validator.validate_file(file_path)
            results.append(result)
            if not result.is_valid and args.strict:
                print(f"❌ {file_path} failed validation", file=sys.stderr)
                sys.exit(1)

        report = ValidationReport(
            timestamp=datetime.now(),
            total_files=len(results),
            valid_files=sum(1 for r in results if r.is_valid),
            invalid_files=sum(1 for r in results if not r.is_valid),
            total_score=sum(r.score for r in results) / len(results) if results else 0,
            results=results,
            summary={}
        )
    else:
        parser.print_help()
        sys.exit(1)

    # Output results
    if args.report:
        html_report = validator.generate_html_report(report)
        print(html_report)
    else:
        print(f"Validation Report - {report.timestamp.strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"Total Files: {report.total_files}")
        print(f"Valid: {report.valid_files}")
        print(f"Invalid: {report.invalid_files}")
        print(".2f")
        print(".2f")

        for result in report.results:
            status = "✅" if result.is_valid else "❌"
            print(f"{status} {result.file_path} (Score: {result.score}%)")
            if result.errors:
                for error in result.errors:
                    print(f"   Error: {error}")
            if result.warnings:
                for warning in result.warnings:
                    print(f"   Warning: {warning}")

if __name__ == '__main__':
    main()
