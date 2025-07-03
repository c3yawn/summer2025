import json
import subprocess
import tempfile
import os

def lambda_handler(event, context):
    try:
        # Parse request
        if 'body' in event and event['body']:
            body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']
        else:
            body = event
        
        files = body.get('files', [])
        if not files:
            return create_response(False, '', 'No files provided')
        
        with tempfile.TemporaryDirectory() as temp_dir:
            cpp_files = []
            
            # Write all C++ files
            for file_data in files:
                filename = file_data.get('filename', 'main.cpp')
                content = file_data.get('content', '')
                filepath = os.path.join(temp_dir, filename)
                
                with open(filepath, 'w') as f:
                    f.write(content)
                
                if filename.endswith(('.cpp', '.cc', '.cxx', '.c')):
                    cpp_files.append(filepath)
            
            if not cpp_files:
                return create_response(False, '', 'No C++ files provided')
            
            # Output executable path
            exe_path = os.path.join(temp_dir, 'program')
            
            # Compile C++ files
            compile_cmd = ['g++', '-o', exe_path, '-std=c++17'] + cpp_files
            compile_result = subprocess.run(
                compile_cmd,
                cwd=temp_dir,
                capture_output=True,
                text=True,
                timeout=20
            )
            
            if compile_result.returncode != 0:
                return create_response(False, '', f'Compilation error: {compile_result.stderr}')
            
            # Execute C++ program
            run_result = subprocess.run(
                [exe_path],
                cwd=temp_dir,
                capture_output=True,
                text=True,
                timeout=20
            )
            
            success = run_result.returncode == 0
            output = run_result.stdout
            error = run_result.stderr
            
            if compile_result.stderr and not error:
                error = f'Compilation warnings: {compile_result.stderr}'
            
            return create_response(success, output, error)
            
    except subprocess.TimeoutExpired:
        return create_response(False, '', 'Execution timeout (20 seconds)')
    except Exception as e:
        return create_response(False, '', f'Error: {str(e)}')

def create_response(success, output, error):
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'success': success,
            'output': output,
            'error': error
        })
    }
