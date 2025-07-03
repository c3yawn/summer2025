# lambda_function.py
import json
import subprocess
import tempfile
import os
import sys
from pathlib import Path

def lambda_handler(event, context):
    try:
        # Parse the incoming request
        if isinstance(event, str):
            body = json.loads(event)
        else:
            body = event.get('body', event)
            if isinstance(body, str):
                body = json.loads(body)
        
        files = body.get('files', [])
        main_file = body.get('mainClassName', 'main')
        
        if not files:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'success': False,
                    'output': '',
                    'error': 'No files provided',
                    'executionType': '🚀 🐍 Container-based Lambda with Python 3.11',
                    'serverless': True,
                    'language': 'PYTHON',
                    'architecture': '100% Serverless'
                })
            }
        
        # Create temporary directory
        with tempfile.TemporaryDirectory() as temp_dir:
            # Write files to temp directory
            main_file_path = None
            for file_info in files:
                filename = file_info['filename']
                content = file_info['content']
                
                file_path = os.path.join(temp_dir, filename)
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                
                # Determine main file
                if filename.endswith('.py') and (main_file in filename or len(files) == 1):
                    main_file_path = file_path
            
            if not main_file_path:
                # Default to first Python file or create main.py
                python_files = [f for f in files if f['filename'].endswith('.py')]
                if python_files:
                    main_file_path = os.path.join(temp_dir, python_files[0]['filename'])
                else:
                    main_file_path = os.path.join(temp_dir, 'main.py')
                    with open(main_file_path, 'w', encoding='utf-8') as f:
                        f.write(files[0]['content'])
            
            # Execute Python code
            result = subprocess.run(
                [sys.executable, main_file_path],
                cwd=temp_dir,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'success': result.returncode == 0,
                    'output': result.stdout,
                    'error': result.stderr,
                    'executionType': '🚀 🐍 Container-based Lambda with Python 3.11',
                    'serverless': True,
                    'language': 'PYTHON',
                    'architecture': '100% Serverless'
                })
            }
            
    except subprocess.TimeoutExpired:
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': False,
                'output': '',
                'error': 'Execution timeout (30 seconds)',
                'executionType': '🚀 🐍 Container-based Lambda with Python 3.11',
                'serverless': True,
                'language': 'PYTHON',
                'architecture': '100% Serverless'
            })
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': False,
                'output': '',
                'error': f'Internal error: {str(e)}',
                'executionType': '🚀 🐍 Container-based Lambda with Python 3.11',
                'serverless': True,
                'language': 'PYTHON',
                'architecture': '100% Serverless'
            })
        }
