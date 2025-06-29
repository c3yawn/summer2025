#!/usr/bin/env python3
"""
ECS Container Compiler Script
Handles compilation and execution for all supported languages
"""

import os
import sys
import subprocess
import json
import boto3
import time
from pathlib import Path

# AWS clients
s3_client = boto3.client('s3')

def log(message):
    """Log with timestamp"""
    print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {message}", flush=True)

def download_files_from_s3(bucket, prefix, local_dir):
    """Download source files from S3"""
    log(f"Downloading files from s3://{bucket}/{prefix}")
    
    # List objects in S3 prefix
    response = s3_client.list_objects_v2(Bucket=bucket, Prefix=prefix)
    
    if 'Contents' not in response:
        log("No files found in S3")
        return []
    
    downloaded_files = []
    for obj in response['Contents']:
        key = obj['Key']
        # Skip the prefix directory itself
        if key.endswith('/'):
            continue
            
        # Get relative filename
        relative_path = key[len(prefix):].lstrip('/')
        local_path = os.path.join(local_dir, relative_path)
        
        # Create directory if needed
        os.makedirs(os.path.dirname(local_path), exist_ok=True)
        
        # Download file
        log(f"Downloading {key} to {local_path}")
        s3_client.download_file(bucket, key, local_path)
        downloaded_files.append(local_path)
    
    return downloaded_files

def upload_result_to_s3(bucket, key, content):
    """Upload compilation result to S3"""
    log(f"Uploading result to s3://{bucket}/{key}")
    s3_client.put_object(
        Bucket=bucket,
        Key=key,
        Body=content,
        ContentType='application/json'
    )

def run_command(cmd, timeout=60):
    """Run command with timeout and capture output"""
    log(f"Running command: {' '.join(cmd)}")
    
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
            cwd='/app'
        )
        
        return {
            'returncode': result.returncode,
            'stdout': result.stdout,
            'stderr': result.stderr
        }
    except subprocess.TimeoutExpired:
        return {
            'returncode': -1,
            'stdout': '',
            'stderr': f'Command timed out after {timeout} seconds'
        }
    except Exception as e:
        return {
            'returncode': -1,
            'stdout': '',
            'stderr': f'Command failed: {str(e)}'
        }

def compile_and_run_java(files):
    """Compile and run Java code"""
    log("Processing Java compilation")
    
    # Find main class
    main_class = None
    for file_path in files:
        if file_path.endswith('.java'):
            # Extract class name from filename
            class_name = os.path.splitext(os.path.basename(file_path))[0]
            # Check if it contains main method
            with open(file_path, 'r') as f:
                content = f.read()
                if 'public static void main' in content:
                    main_class = class_name
                    break
    
    if not main_class:
        return {
            'success': False,
            'output': '',
            'error': 'No main class found with main() method'
        }
    
    # Compile all Java files
    java_files = [f for f in files if f.endswith('.java')]
    compile_cmd = ['javac'] + java_files
    
    compile_result = run_command(compile_cmd, timeout=60)
    
    if compile_result['returncode'] != 0:
        return {
            'success': False,
            'output': compile_result['stdout'],
            'error': compile_result['stderr']
        }
    
    # Run the main class
    run_cmd = ['java', main_class]
    run_result = run_command(run_cmd, timeout=30)
    
    return {
        'success': run_result['returncode'] == 0,
        'output': run_result['stdout'],
        'error': run_result['stderr']
    }

def compile_and_run_cpp(files):
    """Compile and run C++ code"""
    log("Processing C++ compilation")
    
    # Find main source file (usually main.cpp or the first .cpp file)
    cpp_files = [f for f in files if f.endswith(('.cpp', '.cc', '.cxx'))]
    
    if not cpp_files:
        return {
            'success': False,
            'output': '',
            'error': 'No C++ source files found'
        }
    
    # Compile
    output_file = '/app/executable'
    compile_cmd = ['g++', '-std=c++17', '-Wall', '-o', output_file] + cpp_files
    
    compile_result = run_command(compile_cmd, timeout=60)
    
    if compile_result['returncode'] != 0:
        return {
            'success': False,
            'output': compile_result['stdout'],
            'error': compile_result['stderr']
        }
    
    # Run
    run_cmd = [output_file]
    run_result = run_command(run_cmd, timeout=30)
    
    return {
        'success': run_result['returncode'] == 0,
        'output': run_result['stdout'],
        'error': run_result['stderr']
    }

def run_python(files):
    """Run Python code"""
    log("Processing Python execution")
    
    # Find main Python file
    py_files = [f for f in files if f.endswith('.py')]
    
    if not py_files:
        return {
            'success': False,
            'output': '',
            'error': 'No Python files found'
        }
    
    # Use the first Python file as main
    main_file = py_files[0]
    
    # Run Python
    run_cmd = ['python3', main_file]
    run_result = run_command(run_cmd, timeout=30)
    
    return {
        'success': run_result['returncode'] == 0,
        'output': run_result['stdout'],
        'error': run_result['stderr']
    }

def run_javascript(files):
    """Run JavaScript code"""
    log("Processing JavaScript execution")
    
    # Find main JavaScript file
    js_files = [f for f in files if f.endswith('.js')]
    
    if not js_files:
        return {
            'success': False,
            'output': '',
            'error': 'No JavaScript files found'
        }
    
    # Use the first JavaScript file as main
    main_file = js_files[0]
    
    # Run Node.js
    run_cmd = ['node', main_file]
    run_result = run_command(run_cmd, timeout=30)
    
    return {
        'success': run_result['returncode'] == 0,
        'output': run_result['stdout'],
        'error': run_result['stderr']
    }

def main():
    """Main compilation orchestrator"""
    # Get environment variables
    language = os.environ.get('LANGUAGE', '').lower()
    s3_bucket = os.environ.get('S3_BUCKET')
    s3_input_prefix = os.environ.get('S3_INPUT_PREFIX')
    s3_output_key = os.environ.get('S3_OUTPUT_KEY')
    
    log(f"Starting compilation for language: {language}")
    log(f"S3 Bucket: {s3_bucket}")
    log(f"Input prefix: {s3_input_prefix}")
    log(f"Output key: {s3_output_key}")
    
    if not all([language, s3_bucket, s3_input_prefix, s3_output_key]):
        log("ERROR: Missing required environment variables")
        sys.exit(1)
    
    # Create working directory
    work_dir = '/app'
    os.makedirs(work_dir, exist_ok=True)
    os.chdir(work_dir)
    
    try:
        # Download source files
        files = download_files_from_s3(s3_bucket, s3_input_prefix, work_dir)
        
        if not files:
            result = {
                'success': False,
                'output': '',
                'error': 'No source files found'
            }
        else:
            # Process based on language
            if language == 'java':
                result = compile_and_run_java(files)
            elif language == 'cpp':
                result = compile_and_run_cpp(files)
            elif language == 'python':
                result = run_python(files)
            elif language == 'javascript':
                result = run_javascript(files)
            else:
                result = {
                    'success': False,
                    'output': '',
                    'error': f'Unsupported language: {language}'
                }
        
        # Upload result
        result_json = json.dumps(result, indent=2)
        upload_result_to_s3(s3_bucket, s3_output_key, result_json)
        
        log(f"Compilation completed. Success: {result['success']}")
        
        # Exit with appropriate code
        sys.exit(0 if result['success'] else 1)
        
    except Exception as e:
        log(f"ERROR: {str(e)}")
        
        # Upload error result
        error_result = {
            'success': False,
            'output': '',
            'error': f'Internal error: {str(e)}'
        }
        
        try:
            result_json = json.dumps(error_result, indent=2)
            upload_result_to_s3(s3_bucket, s3_output_key, result_json)
        except:
            pass  # Ignore S3 upload errors in error handling
        
        sys.exit(1)

if __name__ == '__main__':
    main()