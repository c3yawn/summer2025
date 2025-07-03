const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

exports.handler = async (event, context) => {
    try {
        let body = event.body ? (typeof event.body === 'string' ? JSON.parse(event.body) : event.body) : event;
        const files = body.files || [];
        
        if (files.length === 0) {
            return { statusCode: 200, body: JSON.stringify({ success: false, output: '', error: 'No files provided' }) };
        }
        
        const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'js-'));
        let mainFilePath = null;
        
        for (const fileData of files) {
            const filename = fileData.filename || 'main.js';
            const filePath = path.join(tempDir, filename);
            fs.writeFileSync(filePath, fileData.content || '');
            if (!mainFilePath) mainFilePath = filePath;
        }
        
        const result = await new Promise((resolve) => {
            const child = spawn('node', [path.basename(mainFilePath)], { cwd: tempDir });
            let stdout = '', stderr = '';
            
            child.stdout.on('data', (data) => stdout += data);
            child.stderr.on('data', (data) => stderr += data);
            
            const timeout = setTimeout(() => {
                child.kill();
                resolve({ success: false, output: '', error: 'Timeout' });
            }, 10000);
            
            child.on('close', (code) => {
                clearTimeout(timeout);
                resolve({ success: code === 0, output: stdout, error: stderr });
            });
        });
        
        fs.rmSync(tempDir, { recursive: true, force: true });
        
        return {
            statusCode: 200,
            headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
            body: JSON.stringify(result)
        };
        
    } catch (error) {
        return {
            statusCode: 200,
            body: JSON.stringify({ success: false, output: '', error: error.message })
        };
    }
};
