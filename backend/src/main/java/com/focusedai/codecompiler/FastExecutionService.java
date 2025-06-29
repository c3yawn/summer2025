package com.focusedai.codecompiler;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.*;
import java.nio.file.*;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

@Service
public class FastExecutionService {
    
    private static final int MAX_CODE_SIZE = 2048; // 2KB max for fast execution
    private static final int MAX_EXECUTION_TIME = 10; // 10 seconds max
    private static final String TEMP_DIR_PREFIX = "fast-compile-";
    
    /**
     * Check if code can be executed using fast path
     */
    public boolean canExecuteFast(String language, List<MultipartFile> files) {
        // Only single file for fast execution
        if (files.size() != 1) {
            System.out.println("❌ Fast path: Multiple files not supported");
            return false;
        }
        
        MultipartFile file = files.get(0);
        
        // Check file size
        if (file.getSize() > MAX_CODE_SIZE) {
            System.out.println("❌ Fast path: File too large (" + file.getSize() + " bytes)");
            return false;
        }
        
        // Only support Python and JavaScript for fast execution
        // (These don't require compilation, just interpretation)
        boolean isSupported = language.equals("python") || language.equals("javascript");
        if (!isSupported) {
            System.out.println("❌ Fast path: Language not supported (" + language + ")");
            return false;
        }
        
        // Check if we have the required runtime installed
        if (!isRuntimeAvailable(language)) {
            System.out.println("❌ Fast path: Runtime not available for " + language);
            return false;
        }
        
        System.out.println("✅ Fast path: Criteria met for " + language + " (" + file.getSize() + " bytes)");
        return true;
    }
    
    /**
     * Execute code using fast path (direct execution on host)
     */
    public CompilationResult executeFast(String language, MultipartFile file) {
        System.out.println("🚀 Fast path: Executing " + language + " code...");
        long startTime = System.currentTimeMillis();
        
        Path tempDir = null;
        try {
            // Create temporary directory
            tempDir = Files.createTempDirectory(TEMP_DIR_PREFIX);
            System.out.println("📁 Fast path: Created temp dir: " + tempDir);
            
            // Determine file extension
            String extension = getFileExtension(language);
            String filename = getCleanFilename(file.getOriginalFilename(), extension);
            Path codeFile = tempDir.resolve(filename);
            
            // Write code to file
            Files.write(codeFile, file.getBytes());
            System.out.println("📝 Fast path: Written code to: " + codeFile);
            
            // Execute the code
            CompilationResult result = executeCode(language, codeFile, tempDir);
            
            long duration = System.currentTimeMillis() - startTime;
            System.out.println("⚡ Fast path: Completed in " + duration + "ms");
            
            return result;
            
        } catch (Exception e) {
            long duration = System.currentTimeMillis() - startTime;
            System.err.println("❌ Fast path: Failed after " + duration + "ms: " + e.getMessage());
            
            return CompilationResult.builder()
                .success(false)
                .output("")
                .error("Fast execution failed: " + e.getMessage())
                .build();
        } finally {
            // Cleanup temporary directory
            cleanupTempDir(tempDir);
        }
    }
    
    private CompilationResult executeCode(String language, Path codeFile, Path workingDir) throws Exception {
        ProcessBuilder pb = new ProcessBuilder();
        
        if (language.equals("python")) {
            // Find working Python command
            String[] pythonCommands = {"python", "py", "python3"};
            String pythonCmd = null;
            
            for (String cmd : pythonCommands) {
                try {
                    ProcessBuilder testPb = new ProcessBuilder(cmd, "--version");
                    Process testProcess = testPb.start();
                    if (testProcess.waitFor(2, TimeUnit.SECONDS) && testProcess.exitValue() == 0) {
                        pythonCmd = cmd;
                        System.out.println("🐍 Fast path: Using Python command: " + pythonCmd);
                        break;
                    }
                } catch (Exception e) {
                    System.out.println("❌ Fast path: Python command test failed: " + cmd);
                }
            }
            
            if (pythonCmd == null) {
                throw new RuntimeException("No working Python command found");
            }
            
            pb.command(pythonCmd, codeFile.toString());
            
        } else if (language.equals("javascript")) {
            pb.command("node", codeFile.toString());
            System.out.println("🟢 Fast path: Using Node.js");
        } else {
            throw new IllegalArgumentException("Unsupported language for fast execution: " + language);
        }
        
        // Set working directory and environment
        pb.directory(workingDir.toFile());
        pb.redirectErrorStream(false);
        
        System.out.println("🔧 Fast path: Executing command: " + String.join(" ", pb.command()));
        
        // Start the process
        Process process = pb.start();
        
        // Wait for completion with timeout
        boolean finished = process.waitFor(MAX_EXECUTION_TIME, TimeUnit.SECONDS);
        
        if (!finished) {
            process.destroyForcibly();
            System.out.println("⏰ Fast path: Process timed out after " + MAX_EXECUTION_TIME + " seconds");
            return CompilationResult.builder()
                .success(false)
                .output("")
                .error("Execution timed out after " + MAX_EXECUTION_TIME + " seconds")
                .build();
        }
        
        // Read output streams
        String output = readStream(process.getInputStream());
        String error = readStream(process.getErrorStream());
        int exitCode = process.exitValue();
        
        System.out.println("📤 Fast path: Exit code: " + exitCode);
        System.out.println("📤 Fast path: Output length: " + output.length() + " chars");
        if (!error.isEmpty()) {
            System.out.println("⚠️ Fast path: Error output: " + error.substring(0, Math.min(error.length(), 100)) + "...");
        }
        
        return CompilationResult.builder()
            .success(exitCode == 0)
            .output(output)
            .error(error)
            .build();
    }
    
    private String readStream(InputStream inputStream) throws IOException {
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream))) {
            return reader.lines().collect(Collectors.joining("\n"));
        }
    }
    
    private String getFileExtension(String language) {
        switch (language.toLowerCase()) {
            case "python": return ".py";
            case "javascript": return ".js";
            default: return ".txt";
        }
    }
    
    private String getCleanFilename(String originalFilename, String defaultExtension) {
        if (originalFilename != null && !originalFilename.isEmpty()) {
            // Use original filename if it has the right extension
            if (originalFilename.endsWith(defaultExtension)) {
                return originalFilename;
            }
            // Add extension if missing
            return originalFilename + defaultExtension;
        }
        return "code" + defaultExtension;
    }
    
    private boolean isRuntimeAvailable(String language) {
        try {
            if (language.equals("python")) {
                // Windows typically uses 'python' or 'py', not 'python3'
                String[] pythonCommands = {"python", "py", "python3"};
                
                for (String cmd : pythonCommands) {
                    try {
                        ProcessBuilder pb = new ProcessBuilder(cmd, "--version");
                        Process process = pb.start();
                        boolean finished = process.waitFor(5, TimeUnit.SECONDS);
                        if (finished && process.exitValue() == 0) {
                            System.out.println("✅ Fast path: Python runtime found using: " + cmd);
                            return true;
                        }
                    } catch (Exception e) {
                        System.out.println("❌ Fast path: Python command failed: " + cmd + " - " + e.getMessage());
                    }
                }
                System.out.println("❌ Fast path: No working Python command found");
                return false;
                
            } else if (language.equals("javascript")) {
                ProcessBuilder pb = new ProcessBuilder("node", "--version");
                Process process = pb.start();
                boolean finished = process.waitFor(5, TimeUnit.SECONDS);
                boolean available = finished && process.exitValue() == 0;
                if (available) {
                    System.out.println("✅ Fast path: Node.js runtime found");
                } else {
                    System.out.println("❌ Fast path: Node.js runtime not found");
                }
                return available;
            } else {
                return false;
            }
            
        } catch (Exception e) {
            System.err.println("❌ Fast path: Runtime check failed for " + language + ": " + e.getMessage());
            return false;
        }
    }
    
    private void cleanupTempDir(Path tempDir) {
        if (tempDir != null && Files.exists(tempDir)) {
            try {
                Files.walk(tempDir)
                    .sorted((a, b) -> b.compareTo(a)) // Delete files before directories
                    .forEach(path -> {
                        try {
                            Files.delete(path);
                        } catch (IOException e) {
                            System.err.println("Failed to delete: " + path + " - " + e.getMessage());
                        }
                    });
                System.out.println("🧹 Fast path: Cleaned up temp directory");
            } catch (IOException e) {
                System.err.println("Failed to cleanup temp directory: " + e.getMessage());
            }
        }
    }
    
    /**
     * Get statistics about fast execution usage
     */
    public Map<String, Object> getFastExecutionStats() {
        return Map.of(
            "max_file_size_bytes", MAX_CODE_SIZE,
            "max_execution_time_seconds", MAX_EXECUTION_TIME,
            "supported_languages", List.of("python", "javascript"),
            "temp_dir_prefix", TEMP_DIR_PREFIX
        );
    }
}