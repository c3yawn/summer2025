import json
import subprocess
import tempfile
import os
import shutil
import sys
from pathlib import Path

def lambda_handler(event, context):
    try:
        # Parse the request
        if 'body' in event:
            body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']
        else:
            body = event
        
        files = body.get('files', [])
        main_class_name = body.get('mainClassName', 'Main')
        
        if not files:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({
                    'success': False,
                    'output': '',
                    'error': 'No files provided'
                })
            }
        
        # Create temporary directory for compilation
        with tempfile.TemporaryDirectory() as temp_dir:
            # Write all Java files
            java_files = []
            for file_info in files:
                filename = file_info['filename']
                content = file_info['content']
                
                file_path = os.path.join(temp_dir, filename)
                with open(file_path, 'w') as f:
                    f.write(content)
                
                if filename.endswith('.java'):
                    java_files.append(file_path)
            
            if not java_files:
                return {
                    'statusCode': 400,
                    'headers': {'Content-Type': 'application/json'},
                    'body': json.dumps({
                        'success': False,
                        'output': '',
                        'error': 'No Java files found'
                    })
                }
            
            # Verify Java is available
            try:
                java_version = subprocess.run(['java', '-version'], 
                                            capture_output=True, text=True, timeout=5)
                javac_version = subprocess.run(['javac', '-version'], 
                                             capture_output=True, text=True, timeout=5)
            except Exception as e:
                return {
                    'statusCode': 500,
                    'headers': {'Content-Type': 'application/json'},
                    'body': json.dumps({
                        'success': False,
                        'output': '',
                        'error': f'Java not available in container: {str(e)}'
                    })
                }
            
            # Compile Java files
            try:
                compile_cmd = ['javac', '-cp', temp_dir] + java_files
                compile_result = subprocess.run(
                    compile_cmd,
                    cwd=temp_dir,
                    capture_output=True,
                    text=True,
                    timeout=15
                )
                
                if compile_result.returncode != 0:
                    return {
                        'statusCode': 200,
                        'headers': {'Content-Type': 'application/json'},
                        'body': json.dumps({
                            'success': False,
                            'output': '',
                            'error': f'Compilation failed: {compile_result.stderr}'
                        })
                    }
                
                # Run the Java program
                run_cmd = ['java', '-cp', temp_dir, main_class_name]
                run_result = subprocess.run(
                    run_cmd,
                    cwd=temp_dir,
                    capture_output=True,
                    text=True,
                    timeout=10
                )
                
                # Return result
                return {
                    'statusCode': 200,
                    'headers': {'Content-Type': 'application/json'},
                    'body': json.dumps({
                        'success': run_result.returncode == 0,
                        'output': run_result.stdout,
                        'error': run_result.stderr if run_result.returncode != 0 else ''
                    })
                }
                
            except subprocess.TimeoutExpired:
                return {
                    'statusCode': 200,
                    'headers': {'Content-Type': 'application/json'},
                    'body': json.dumps({
                        'success': False,
                        'output': '',
                        'error': 'Execution timeout (10 seconds)'
                    })
                }
            except Exception as e:
                return {
                    'statusCode': 500,
                    'headers': {'Content-Type': 'application/json'},
                    'body': json.dumps({
                        'success': False,
                        'output': '',
                        'error': f'Execution error: {str(e)}'
                    })
                }
    
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'success': False,
                'output': '',
                'error': f'Handler error: {str(e)}'
            })
        }
