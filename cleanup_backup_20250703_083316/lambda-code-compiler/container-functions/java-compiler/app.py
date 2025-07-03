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
        main_class_name = body.get('mainClassName', '')
        
        if not files:
            return create_response(False, '', 'No files provided')
        
        with tempfile.TemporaryDirectory() as temp_dir:
            java_files = []
            
            # Write all Java files
            for file_data in files:
                filename = file_data.get('filename', 'Main.java')
                content = file_data.get('content', '')
                filepath = os.path.join(temp_dir, filename)
                
                with open(filepath, 'w') as f:
                    f.write(content)
                
                if filename.endswith('.java'):
                    java_files.append(filepath)
            
            if not java_files:
                return create_response(False, '', 'No Java files provided')
            
            # Determine main class name
            if not main_class_name:
                main_file = os.path.basename(java_files[0])
                main_class_name = os.path.splitext(main_file)[0]
            
            # Compile Java files
            compile_cmd = ['javac', '-cp', temp_dir] + java_files
            compile_result = subprocess.run(
                compile_cmd,
                cwd=temp_dir,
                capture_output=True,
                text=True,
                timeout=20
            )
            
            if compile_result.returncode != 0:
                return create_response(False, '', f'Compilation error: {compile_result.stderr}')
            
            # Execute Java program
            run_cmd = ['java', '-cp', temp_dir, main_class_name]
            run_result = subprocess.run(
                run_cmd,
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
