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
            # Write all C++ files
            cpp_files = []
            main_file = None
            
            for file_info in files:
                filename = file_info['filename']
                content = file_info['content']
                
                file_path = os.path.join(temp_dir, filename)
                with open(file_path, 'w') as f:
                    f.write(content)
                
                if filename.endswith(('.cpp', '.cc', '.cxx', '.c++')):
                    cpp_files.append(file_path)
                    if 'main' in filename.lower() or len(cpp_files) == 1:
                        main_file = file_path
                elif filename.endswith('.c'):
                    cpp_files.append(file_path)
                    if 'main' in filename.lower() or len(cpp_files) == 1:
                        main_file = file_path
            
            if not cpp_files:
                return {
                    'statusCode': 400,
                    'headers': {'Content-Type': 'application/json'},
                    'body': json.dumps({
                        'success': False,
                        'output': '',
                        'error': 'No C++ files found'
                    })
                }
            
            # Use the first file as main if no main file detected
            if not main_file:
                main_file = cpp_files[0]
            
            # Verify GCC is available
            try:
                gcc_version = subprocess.run(['gcc', '--version'], 
                                           capture_output=True, text=True, timeout=5)
                gpp_version = subprocess.run(['g++', '--version'], 
                                           capture_output=True, text=True, timeout=5)
            except Exception as e:
                return {
                    'statusCode': 500,
                    'headers': {'Content-Type': 'application/json'},
                    'body': json.dumps({
                        'success': False,
                        'output': '',
                        'error': f'C++ compiler not available in container: {str(e)}'
                    })
                }
            
            # Compile C++ files
            try:
                output_binary = os.path.join(temp_dir, 'program')
                
                # Determine compiler (g++ for .cpp files, gcc for .c files)
                compiler = 'g++' if any(f.endswith(('.cpp', '.cc', '.cxx', '.c++')) for f in cpp_files) else 'gcc'
                
                compile_cmd = [compiler, '-o', output_binary, '-std=c++17'] + cpp_files
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
                
                # Run the compiled program
                run_result = subprocess.run(
                    [output_binary],
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
