#!/usr/bin/env python3

import json
import base64
import subprocess
import tempfile
import os
import sys
from flask import Flask, request, jsonify
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy", "service": "cpp-compiler"}), 200

@app.route('/compile', methods=['POST'])
def compile_cpp():
    try:
        logger.info("Received C++ compilation request")
        
        # Parse the request
        data = request.get_json()
        if not data:
            return jsonify({
                'status': 'Error',
                'compilationErrors': 'No JSON data provided',
                'programOutput': '',
                'hasError': True
            }), 400

        # Extract data
        source_files = data.get('sourceFiles', [])
        main_class_name = data.get('mainClassName', 'main')
        
        if not source_files:
            return jsonify({
                'status': 'Error',
                'compilationErrors': 'No source files provided',
                'programOutput': '',
                'hasError': True
            }), 400

        logger.info(f"Processing {len(source_files)} C++ files")
        
        # Create temporary directory for compilation
        with tempfile.TemporaryDirectory() as temp_dir:
            logger.info(f"Working in: {temp_dir}")
            
            # Write all C++ files to temp directory
            cpp_file_paths = []
            for file_info in source_files:
                filename = file_info.get('filename', 'main.cpp')
                content = file_info.get('content', '')
                
                # Handle base64 encoded content if needed
                if is_base64(content):
                    try:
                        content = base64.b64decode(content).decode('utf-8')
                    except Exception as e:
                        logger.warning(f"Failed to decode base64 for {filename}, using as plain text")
                
                file_path = os.path.join(temp_dir, filename)
                with open(file_path, 'w') as f:
                    f.write(content)
                
                cpp_file_paths.append(file_path)
                logger.info(f"Created file: {filename} ({len(content)} chars)")
            
            # Prepare compilation command
            executable_path = os.path.join(temp_dir, f'{main_class_name}_executable')
            compile_cmd = ['g++', '-std=c++17', '-Wall', '-O2'] + cpp_file_paths + ['-o', executable_path]
            
            logger.info(f"Compiling: {' '.join(compile_cmd)}")
            
            try:
                # Compile the C++ files
                compile_result = subprocess.run(
                    compile_cmd,
                    cwd=temp_dir,
                    capture_output=True,
                    text=True,
                    timeout=60
                )
                
                logger.info(f"Compilation exit code: {compile_result.returncode}")
                
                if compile_result.returncode != 0:
                    # Compilation failed
                    error_output = compile_result.stderr or compile_result.stdout
                    logger.error(f"Compilation failed: {error_output}")
                    
                    return jsonify({
                        'status': 'Compilation Failed',
                        'compilationErrors': error_output,
                        'programOutput': '',
                        'hasError': True
                    })
                
                logger.info("Compilation successful! Executing program...")
                
                # Execute the compiled program
                try:
                    execution_result = subprocess.run(
                        [executable_path],
                        cwd=temp_dir,
                        capture_output=True,
                        text=True,
                        timeout=30
                    )
                    
                    logger.info(f"Execution exit code: {execution_result.returncode}")
                    
                    # Get program output
                    program_output = execution_result.stdout
                    if execution_result.stderr:
                        program_output += "\nStderr: " + execution_result.stderr
                    
                    if execution_result.returncode == 0:
                        # Successful execution
                        final_output = program_output.strip() if program_output.strip() else "✅ Program executed successfully!\n(No console output produced)"
                        
                        return jsonify({
                            'status': 'Success',
                            'compilationErrors': '',
                            'programOutput': final_output,
                            'hasError': False
                        })
                    else:
                        # Runtime error
                        return jsonify({
                            'status': 'Runtime Error',
                            'compilationErrors': '',
                            'programOutput': f'💥 Program crashed with exit code {execution_result.returncode}\n\nOutput:\n{program_output}',
                            'hasError': True
                        })
                
                except subprocess.TimeoutExpired:
                    logger.warning("Program execution timed out")
                    return jsonify({
                        'status': 'Execution Timeout',
                        'compilationErrors': '',
                        'programOutput': '⏱️ Program execution timed out after 30 seconds.\nCheck for infinite loops or very slow operations.',
                        'hasError': True
                    })
                
            except subprocess.TimeoutExpired:
                logger.warning("Compilation timed out")
                return jsonify({
                    'status': 'Compilation Timeout',
                    'compilationErrors': 'Compilation timed out after 60 seconds. Code may be too complex.',
                    'programOutput': '',
                    'hasError': True
                })
            
            except Exception as compile_error:
                logger.error(f"Compilation error: {compile_error}")
                return jsonify({
                    'status': 'Compilation Error',
                    'compilationErrors': str(compile_error),
                    'programOutput': '',
                    'hasError': True
                })
        
    except Exception as e:
        logger.error(f"Service error: {e}")
        return jsonify({
            'status': 'Service Error',
            'compilationErrors': '',
            'programOutput': f'Service error: {str(e)}',
            'hasError': True
        }), 500

def is_base64(s):
    """Check if string is base64 encoded"""
    try:
        if isinstance(s, str):
            # Check if string looks like base64
            sb_bytes = bytes(s, 'ascii')
        elif isinstance(s, bytes):
            sb_bytes = s
        else:
            raise ValueError("Argument must be string or bytes")
        return base64.b64encode(base64.b64decode(sb_bytes)) == sb_bytes
    except Exception:
        return False

if __name__ == '__main__':
    logger.info("Starting C++ Compiler Service on port 8080")
    app.run(host='0.0.0.0', port=8080, debug=False)