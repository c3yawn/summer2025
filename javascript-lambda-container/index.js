// index.js
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

exports.handler = async (event, context) => {
    try {
        // Parse the incoming request
        let body;
        if (typeof event === 'string') {
            body = JSON.parse(event);
        } else {
            body = event.body ? JSON.parse(event.body) : event;
        }
        
        const files = body.files || [];
        const mainFile = body.mainClassName || 'main';
        
        if (!files || files.length === 0) {
            return {
                statusCode: 400,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                body: JSON.stringify({
                    success: false,
                    output: '',
                    error: 'No files provided',
                    executionType: '🚀 📜 Container-based Lambda with Node.js 18',
                    serverless: true,
                    language: 'JAVASCRIPT',
                    architecture: '100% Serverless'
                })
            };
        }
        
        // Create temporary directory
        const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'js-exec-'));
        
        try {
            // Write files to temp directory
            let mainFilePath = null;
            for (const fileInfo of files) {
                const filename = fileInfo.filename;
                const content = fileInfo.content;
                
                const filePath = path.join(tempDir, filename);
                fs.writeFileSync(filePath, content, 'utf8');
                
                // Determine main file
                if (filename.endsWith('.js') && (filename.includes(mainFile) || files.length === 1)) {
                    mainFilePath = filePath;
                }
            }
            
            if (!mainFilePath) {
                // Default to first JS file or create main.js
                const jsFiles = files.filter(f => f.filename.endsWith('.js'));
                if (jsFiles.length > 0) {
                    mainFilePath = path.join(tempDir, jsFiles[0].filename);
                } else {
                    mainFilePath = path.join(tempDir, 'main.js');
                    fs.writeFileSync(mainFilePath, files[0].content, 'utf8');
                }
            }
            
            // Execute JavaScript code
            const result = await executeNodeScript(mainFilePath, tempDir);
            
            return {
                statusCode: 200,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                body: JSON.stringify({
                    success: result.success,
                    output: result.output,
                    error: result.error,
                    executionType: '🚀 📜 Container-based Lambda with Node.js 18',
                    serverless: true,
                    language: 'JAVASCRIPT',
                    architecture: '100% Serverless'
                })
            };
            
        } finally {
            // Clean up temp directory
            fs.rmSync(tempDir, { recursive: true, force: true });
        }
        
    } catch (error) {
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                success: false,
                output: '',
                error: `Internal error: ${error.message}`,
                executionType: '🚀 📜 Container-based Lambda with Node.js 18',
                serverless: true,
                language: 'JAVASCRIPT',
                architecture: '100% Serverless'
            })
        };
    }
};

function executeNodeScript(scriptPath, cwd) {
    return new Promise((resolve) => {
        const child = spawn('node', [scriptPath], {
            cwd: cwd,
            stdio: ['pipe', 'pipe', 'pipe']
        });
        
        let output = '';
        let errorOutput = '';
        
        child.stdout.on('data', (data) => {
            output += data.toString();
        });
        
        child.stderr.on('data', (data) => {
            errorOutput += data.toString();
        });
        
        const timeoutId = setTimeout(() => {
            child.kill('SIGTERM');
            resolve({
                success: false,
                output: output,
                error: errorOutput + '\nExecution timeout (30 seconds)'
            });
        }, 30000);
        
        child.on('close', (code) => {
            clearTimeout(timeoutId);
            resolve({
                success: code === 0,
                output: output,
                error: errorOutput
            });
        });
        
        child.on('error', (error) => {
            clearTimeout(timeoutId);
            resolve({
                success: false,
                output: output,
                error: errorOutput + '\nExecution error: ' + error.message
            });
        });
    });
}
