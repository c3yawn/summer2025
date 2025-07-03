import json
import subprocess
import tempfile
import os
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def lambda_handler(event, context):
    try:
        logger.info(f"C++ compiler invoked with request ID: {context.aws_request_id}")
        
        if 'body' in event:
            body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']
        else:
            body = event
        
        files = body.get('files', [])
        executable_name = body.get('mainClassName', 'main')
        
        if not files:
            return create_api_response(create_response(False, '', 'No files provided'))
        
        # For now, return a message that C++ is not available in this simplified version
        return create_api_response(create_response(False, '', 'C++ compilation not available in this Lambda environment. Use the online compiler instead.'))
        
    except Exception as e:
        logger.error(f"Lambda execution error: {str(e)}")
        error_result = create_response(False, '', f'Lambda error: {str(e)}')
        return create_api_response(error_result)

def create_response(success, output, error):
    return {
        'success': success,
        'output': output.strip() if output else '',
        'error': error.strip() if error else '',
        'executionPath': 'lambda_direct'
    }

def create_api_response(result):
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'POST, OPTIONS'
        },
        'body': json.dumps(result)
    }
