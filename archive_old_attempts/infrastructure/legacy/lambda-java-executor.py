import json
import subprocess
import tempfile
import os
import base64
import zipfile
import io

def lambda_handler(event, context):
    try:
        # Parse the input
        files = event.get('files', [])
        main_class = event.get('mainClassName', 'Main')
        
        # Create temporary directory
        with tempfile.TemporaryDirectory() as temp_dir:
            # Write all Java files
            for file_info in files:
                filename = file_info['filename']
                content = base64.b64decode(file_info['content']).decode('utf-8')
                
                file_path = os.path.join(temp_dir, filename)
                with open(file_path, 'w') as f:
                    f.write(content)
            
            # Compile Java files
            compile_cmd = ['javac'] + [os.path.join(temp_dir, f['filename']) for f in files]
            compile_result = subprocess.run(
                compile_cmd,
                cwd=temp_dir,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if compile_result.returncode != 0:
                return {
                    'status': 'Compilation Failed',
                    'compilationErrors': compile_result.stderr,
                    'programOutput': '',
                    'hasError': True
                }
            
            # Run the main class
            run_cmd = ['java', main_class]
            run_result = subprocess.run(
                run_cmd,
                cwd=temp_dir,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            return {
                'status': 'Success' if run_result.returncode == 0 else 'Runtime Error',
                'compilationErrors': '',
                'programOutput': run_result.stdout + run_result.stderr,
                'hasError': run_result.returncode != 0
            }
            
    except subprocess.TimeoutExpired:
        return {
            'status': 'Execution Timeout',
            'compilationErrors': '',
            'programOutput': 'Code execution timed out after 30 seconds',
            'hasError': True
        }
    except Exception as e:
        return {
            'status': 'Lambda Error',
            'compilationErrors': '',
            'programOutput': f'Lambda execution error: {str(e)}',
            'hasError': True
        }
