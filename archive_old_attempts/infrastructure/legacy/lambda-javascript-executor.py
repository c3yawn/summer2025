import json
import subprocess
import tempfile
import os
import base64

def lambda_handler(event, context):
    try:
        # Parse the input
        files = event.get('files', [])
        main_file = event.get('mainClassName', 'main') + '.js'
        
        # Create temporary directory
        with tempfile.TemporaryDirectory() as temp_dir:
            # Write all JavaScript files
            for file_info in files:
                filename = file_info['filename']
                content = base64.b64decode(file_info['content']).decode('utf-8')
                
                file_path = os.path.join(temp_dir, filename)
                with open(file_path, 'w') as f:
                    f.write(content)
            
            # Find the main file
            main_file_path = None
            for file_info in files:
                if file_info['filename'] == main_file or file_info['filename'].endswith('.js'):
                    main_file_path = os.path.join(temp_dir, file_info['filename'])
                    break
            
            if not main_file_path:
                return {
                    'status': 'File Not Found',
                    'compilationErrors': f'Main file {main_file} not found',
                    'programOutput': '',
                    'hasError': True
                }
            
            # Execute JavaScript file with Node.js
            run_result = subprocess.run(
                ['node', main_file_path],
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
