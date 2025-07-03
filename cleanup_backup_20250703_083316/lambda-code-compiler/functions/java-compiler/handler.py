import json
import subprocess
import tempfile
import os
import logging
from pathlib import Path

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def lambda_handler(event, context):
    try:
        logger.info(f"Java compiler invoked with request ID: {context.aws_request_id}")
        
        if 'body' in event:
            body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']
        else:
            body = event
        
        files = body.get('files', [])
        main_class = body.get('mainClassName', 'Main')
        
        if not files:
            return create_api_response(create_response(False, '', 'No files provided'))
        
        logger.info(f"Compiling {len(files)} Java files, main class: {main_class}")
        result = compile_and_run_java(files, main_class)
        
        logger.info(f"Compilation completed. Success: {result['success']}")
        return create_api_response(result)
        
    except Exception as e:
        logger.error(f"Lambda execution error: {str(e)}")
        error_result = create_response(False, '', f'Lambda error: {str(e)}')
        return create_api_response(error_result)

def compile_and_run_java(files, main_class):
    try:
        with tempfile.TemporaryDirectory() as temp_dir:
            logger.info(f"Working in temporary directory: {temp_dir}")
            
            java_files = []
            for file_data in files:
                filename = file_data.get('filename', 'Main.java')
                content = file_data.get('content', '')
                
                if not filename.endswith('.java'):
                    filename += '.java'
                
                file_path = os.path.join(temp_dir, filename)
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                
                java_files.append(file_path)
                logger.info(f"Created file: {filename} ({len(content)} chars)")
            
            logger.info("Starting Java compilation...")
            compile_result = subprocess.run(
                ['javac', '-cp', temp_dir] + java_files,
                capture_output=True,
                text=True,
                timeout=25,
                cwd=temp_dir
            )
            
            if compile_result.returncode != 0:
                logger.error(f"Compilation failed: {compile_result.stderr}")
                return create_response(False, '', f'Compilation failed: {compile_result.stderr}')
            
            logger.info("Compilation successful, executing...")
            
            run_result = subprocess.run(
                ['java', '-cp', temp_dir, main_class],
                capture_output=True,
                text=True,
                timeout=20,
                cwd=temp_dir
            )
            
            output = run_result.stdout
            error = run_result.stderr
            
            if run_result.returncode == 0:
                logger.info("Execution successful")
                return create_response(True, output, error)
            else:
                logger.warning(f"Execution failed with exit code: {run_result.returncode}")
                return create_response(False, output, error)
            
    except subprocess.TimeoutExpired as e:
        logger.error(f"Process timeout: {str(e)}")
        return create_response(False, '', f'Execution timeout: {str(e)}')
    except Exception as e:
        logger.error(f"Compilation error: {str(e)}")
        return create_response(False, '', f'Compilation error: {str(e)}')

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
