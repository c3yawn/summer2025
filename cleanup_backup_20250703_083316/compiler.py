#!/usr/bin/env python3
"""
Universal compiler script for ECS Fargate containers
Supports both immediate execution and warm pool mode
"""

import os
import sys
import json
import subprocess
import time
import boto3
from pathlib import Path

def log(message):
    """Thread-safe logging with timestamp"""
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {message}", flush=True)

def download_from_s3(bucket, key, local_path):
    """Download file from S3"""
    try:
        s3_client = boto3.client('s3')
        s3_client.download_file(bucket, key, local_path)
        log(f"📥 Downloaded {key} to {local_path}")
        return True
    except Exception as e:
        log(f"❌ Download failed: {e}")
        return False

def upload_to_s3(bucket, key, local_path):
    """Upload file to S3"""
    try:
        s3_client = boto3.client('s3')
        s3_client.upload_file(local_path, bucket, key)
        log(f"📤 Uploaded {local_path} to {key}")
        return True
    except Exception as e:
        log(f"❌ Upload failed: {e}")
        return False

def compile_and_run(language, source_files):
    """Compile and execute code based on language"""
    log(f"🚀 Starting compilation for language: {language}")
    
    try:
        if language == "python":
            return run_python(source_files)
        elif language == "javascript":
            return run_javascript(source_files)
        elif language == "java":
            return run_java(source_files)
        elif language == "cpp":
            return run_cpp(source_files)
        else:
            return {
                "success": False,
                "output": "",
                "error": f"Unsupported language: {language}"
            }
    except Exception as e:
        return {
            "success": False,
            "output": "",
            "error": f"Compilation error: {str(e)}"
        }

def run_python(source_files):
    """Execute Python code"""
    log("🐍 Processing Python code")
    
    # Find main Python file
    main_file = None
    for file_path in source_files:
        if file_path.name.endswith('.py'):
            main_file = file_path
            break
    
    if not main_file:
        return {"success": False, "output": "", "error": "No Python file found"}
    
    try:
        result = subprocess.run(
            ['python3', str(main_file)],
            capture_output=True,
            text=True,
            timeout=30
        )
        
        return {
            "success": result.returncode == 0,
            "output": result.stdout,
            "error": result.stderr
        }
    except subprocess.TimeoutExpired:
        return {"success": False, "output": "", "error": "Execution timeout"}

def run_javascript(source_files):
    """Execute JavaScript code"""
    log("🟢 Processing JavaScript code")
    
    # Find main JavaScript file
    main_file = None
    for file_path in source_files:
        if file_path.name.endswith('.js'):
            main_file = file_path
            break
    
    if not main_file:
        return {"success": False, "output": "", "error": "No JavaScript file found"}
    
    try:
        result = subprocess.run(
            ['node', str(main_file)],
            capture_output=True,
            text=True,
            timeout=30
        )
        
        return {
            "success": result.returncode == 0,
            "output": result.stdout,
            "error": result.stderr
        }
    except subprocess.TimeoutExpired:
        return {"success": False, "output": "", "error": "Execution timeout"}

def run_java(source_files):
    """Compile and execute Java code"""
    log("☕ Processing Java compilation")
    
    # Find Java files
    java_files = [f for f in source_files if f.name.endswith('.java')]
    if not java_files:
        return {"success": False, "output": "", "error": "No Java files found"}
    
    try:
        # Compile all Java files
        compile_cmd = ['javac'] + [str(f) for f in java_files]
        compile_result = subprocess.run(
            compile_cmd,
            capture_output=True,
            text=True,
            timeout=60
        )
        
        if compile_result.returncode != 0:
            return {
                "success": False,
                "output": "",
                "error": f"Compilation failed: {compile_result.stderr}"
            }
        
        # Find main class (assume first Java file)
        main_class = java_files[0].stem
        
        # Run the main class
        run_result = subprocess.run(
            ['java', main_class],
            capture_output=True,
            text=True,
            timeout=30,
            cwd=java_files[0].parent
        )
        
        return {
            "success": run_result.returncode == 0,
            "output": run_result.stdout,
            "error": run_result.stderr
        }
        
    except subprocess.TimeoutExpired:
        return {"success": False, "output": "", "error": "Execution timeout"}

def run_cpp(source_files):
    """Compile and execute C++ code"""
    log("🔧 Processing C++ compilation")
    
    # Find C++ files
    cpp_files = [f for f in source_files if f.name.endswith(('.cpp', '.cc', '.cxx'))]
    if not cpp_files:
        return {"success": False, "output": "", "error": "No C++ files found"}
    
    try:
        output_file = Path("/tmp/executable")
        
        # Compile C++ files
        compile_cmd = ['g++', '-o', str(output_file)] + [str(f) for f in cpp_files]
        compile_result = subprocess.run(
            compile_cmd,
            capture_output=True,
            text=True,
            timeout=60
        )
        
        if compile_result.returncode != 0:
            return {
                "success": False,
                "output": "",
                "error": f"Compilation failed: {compile_result.stderr}"
            }
        
        # Run the executable
        run_result = subprocess.run(
            [str(output_file)],
            capture_output=True,
            text=True,
            timeout=30
        )
        
        return {
            "success": run_result.returncode == 0,
            "output": run_result.stdout,
            "error": run_result.stderr
        }
        
    except subprocess.TimeoutExpired:
        return {"success": False, "output": "", "error": "Execution timeout"}

def process_compilation_job():
    """Process a single compilation job"""
    # Get environment variables
    language = os.environ.get('LANGUAGE')
    s3_bucket = os.environ.get('S3_BUCKET')
    s3_input_prefix = os.environ.get('S3_INPUT_PREFIX')
    s3_output_key = os.environ.get('S3_OUTPUT_KEY')
    
    if not language:
        log("❌ Missing LANGUAGE environment variable")
        return False
        
    if not all([s3_bucket, s3_input_prefix, s3_output_key]):
        log("❌ Missing S3 environment variables (bucket, input prefix, or output key)")
        return False
    
    log(f"📋 Processing job: {language} from {s3_input_prefix}")
    
    # Create working directory
    work_dir = Path("/tmp/work")
    work_dir.mkdir(exist_ok=True)
    
    try:
        # List and download source files from S3
        s3_client = boto3.client('s3')
        
        # List objects with the input prefix
        response = s3_client.list_objects_v2(
            Bucket=s3_bucket,
            Prefix=s3_input_prefix
        )
        
        if 'Contents' not in response:
            log("❌ No source files found in S3")
            return False
        
        source_files = []
        for obj in response['Contents']:
            key = obj['Key']
            filename = key.split('/')[-1]
            if filename:  # Skip directory entries
                local_path = work_dir / filename
                if download_from_s3(s3_bucket, key, str(local_path)):
                    source_files.append(local_path)
        
        if not source_files:
            log("❌ No source files downloaded")
            return False
        
        # Compile and run
        result = compile_and_run(language, source_files)
        log(f"✅ Compilation completed. Success: {result['success']}")
        
        # Upload result to S3
        result_file = work_dir / "result.json"
        with open(result_file, 'w') as f:
            json.dump(result, f, indent=2)
        
        return upload_to_s3(s3_bucket, s3_output_key, str(result_file))
        
    except Exception as e:
        log(f"❌ Job processing failed: {e}")
        return False

def warm_mode_loop():
    """Run in warm mode - stay alive and wait for jobs"""
    language = os.environ.get('LANGUAGE', 'unknown')
    warm_timeout = int(os.environ.get('WARM_TIMEOUT', '3600'))  # 1 hour default
    
    log(f"🔥 Container started in WARM mode for {language}")
    log(f"🔥 Warm timeout: {warm_timeout} seconds")
    log(f"🔥 Warm container for {language} is ready and waiting...")
    
    start_time = time.time()
    
    while True:
        # Check for timeout
        if time.time() - start_time > warm_timeout:
            log(f"⏰ Warm timeout reached for {language}")
            break
        
        # Check if we have a job to process
        if all([
            os.environ.get('S3_BUCKET'),
            os.environ.get('S3_INPUT_PREFIX'),
            os.environ.get('S3_OUTPUT_KEY')
        ]):
            log(f"🚀 Job detected, switching to execution mode")
            if process_compilation_job():
                log(f"✅ Job completed successfully")
            else:
                log(f"❌ Job failed")
            break  # Exit after processing one job
        
        # Wait a bit before checking again
        time.sleep(5)
    
    log(f"🏁 Warm container for {language} is shutting down")

def main():
    """Main entry point"""
    log("🚀 Container starting...")
    
    # Check if running in warm mode
    mode = os.environ.get('MODE', 'EXECUTE')
    language = os.environ.get('LANGUAGE', 'unknown')
    
    log(f"🔧 Mode: {mode}, Language: {language}")
    
    if mode == 'WARM':
        warm_mode_loop()
    else:
        # Regular execution mode
        log("🚀 Starting immediate execution mode")
        if process_compilation_job():
            log("✅ Job completed successfully")
            sys.exit(0)
        else:
            log("❌ Job failed")
            sys.exit(1)

if __name__ == "__main__":
    main()