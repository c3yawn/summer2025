package com.focusedai.codecompiler.service;

import org.springframework.stereotype.Service;
import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.TimeUnit;

@Service
public class CodeExecutionService {

    private static final String TEMP_DIR = System.getProperty("java.io.tmpdir") + "/code-compiler/";
    private static final int TIMEOUT_SECONDS = 10;

    public Map<String, Object> executeCode(String language, List<Map<String, String>> files, String mainClassName) {
        Map<String, Object> result = new HashMap<>();
        
        try {
            // Create temporary directory
            Path tempDir = Paths.get(TEMP_DIR + UUID.randomUUID().toString());
            Files.createDirectories(tempDir);

            switch (language.toLowerCase()) {
                case "java":
                    result = executeJavaCode(tempDir, files, mainClassName);
                    break;
                case "javascript":
                    result = executeJavaScriptCode(tempDir, files, mainClassName);
                    break;
                case "python":
                    result = executePythonCode(tempDir, files, mainClassName);
                    break;
                case "cpp":
                    result = executeCppCode(tempDir, files, mainClassName);
                    break;
                default:
                    result.put("success", false);
                    result.put("error", "Unsupported language: " + language);
                    result.put("output", "");
            }

            // Cleanup
            deleteDirectory(tempDir.toFile());

        } catch (Exception e) {
            result.put("success", false);
            result.put("error", "Execution failed: " + e.getMessage());
            result.put("output", "");
        }

        return result;
    }

    private Map<String, Object> executeJavaCode(Path tempDir, List<Map<String, String>> files, String mainClassName) {
        Map<String, Object> result = new HashMap<>();
        
        try {
            // Write Java files
            for (Map<String, String> file : files) {
                String filename = file.get("filename");
                String content = file.get("content");
                
                if (!filename.endsWith(".java")) {
                    filename += ".java";
                }
                
                Path filePath = tempDir.resolve(filename);
                Files.write(filePath, content.getBytes());
            }

            // Compile Java code
            String mainFile = mainClassName + ".java";
            ProcessBuilder compileBuilder = new ProcessBuilder("javac", mainFile);
            compileBuilder.directory(tempDir.toFile());
            compileBuilder.redirectErrorStream(true);

            Process compileProcess = compileBuilder.start();
            String compileOutput = readProcessOutput(compileProcess);
            
            if (compileProcess.waitFor(TIMEOUT_SECONDS, TimeUnit.SECONDS) && compileProcess.exitValue() == 0) {
                // Compilation successful, now run
                ProcessBuilder runBuilder = new ProcessBuilder("java", mainClassName);
                runBuilder.directory(tempDir.toFile());
                runBuilder.redirectErrorStream(true);

                Process runProcess = runBuilder.start();
                String runOutput = readProcessOutput(runProcess);
                
                if (runProcess.waitFor(TIMEOUT_SECONDS, TimeUnit.SECONDS)) {
                    result.put("success", runProcess.exitValue() == 0);
                    result.put("output", runOutput);
                    result.put("error", runProcess.exitValue() != 0 ? "Runtime error (exit code: " + runProcess.exitValue() + ")" : "");
                } else {
                    result.put("success", false);
                    result.put("output", runOutput);
                    result.put("error", "Execution timeout");
                }
            } else {
                result.put("success", false);
                result.put("output", "");
                result.put("error", "Compilation failed:\n" + compileOutput);
            }

        } catch (Exception e) {
            result.put("success", false);
            result.put("output", "");
            result.put("error", "Java execution error: " + e.getMessage());
        }

        return result;
    }

    private Map<String, Object> executeJavaScriptCode(Path tempDir, List<Map<String, String>> files, String mainClassName) {
        Map<String, Object> result = new HashMap<>();
        
        try {
            // Write JavaScript file
            String content = files.get(0).get("content");
            String filename = mainClassName + ".js";
            Path filePath = tempDir.resolve(filename);
            Files.write(filePath, content.getBytes());

            // Run with Node.js
            ProcessBuilder builder = new ProcessBuilder("node", filename);
            builder.directory(tempDir.toFile());
            builder.redirectErrorStream(true);

            Process process = builder.start();
            String output = readProcessOutput(process);
            
            if (process.waitFor(TIMEOUT_SECONDS, TimeUnit.SECONDS)) {
                result.put("success", process.exitValue() == 0);
                result.put("output", output);
                result.put("error", process.exitValue() != 0 ? "Runtime error (exit code: " + process.exitValue() + ")" : "");
            } else {
                result.put("success", false);
                result.put("output", output);
                result.put("error", "Execution timeout");
            }

        } catch (Exception e) {
            result.put("success", false);
            result.put("output", "");
            result.put("error", "JavaScript execution error: " + e.getMessage() + "\n(Make sure Node.js is installed)");
        }

        return result;
    }

    private Map<String, Object> executePythonCode(Path tempDir, List<Map<String, String>> files, String mainClassName) {
        Map<String, Object> result = new HashMap<>();
        
        try {
            // Write Python file
            String content = files.get(0).get("content");
            String filename = mainClassName + ".py";
            Path filePath = tempDir.resolve(filename);
            Files.write(filePath, content.getBytes());

            // Run with Python
            ProcessBuilder builder = new ProcessBuilder("python", filename);
            builder.directory(tempDir.toFile());
            builder.redirectErrorStream(true);

            Process process = builder.start();
            String output = readProcessOutput(process);
            
            if (process.waitFor(TIMEOUT_SECONDS, TimeUnit.SECONDS)) {
                result.put("success", process.exitValue() == 0);
                result.put("output", output);
                result.put("error", process.exitValue() != 0 ? "Runtime error (exit code: " + process.exitValue() + ")" : "");
            } else {
                result.put("success", false);
                result.put("output", output);
                result.put("error", "Execution timeout");
            }

        } catch (Exception e) {
            result.put("success", false);
            result.put("output", "");
            result.put("error", "Python execution error: " + e.getMessage() + "\n(Make sure Python is installed)");
        }

        return result;
    }

    private Map<String, Object> executeCppCode(Path tempDir, List<Map<String, String>> files, String mainClassName) {
        Map<String, Object> result = new HashMap<>();
        
        try {
            // Write C++ file
            String content = files.get(0).get("content");
            String filename = mainClassName + ".cpp";
            Path filePath = tempDir.resolve(filename);
            Files.write(filePath, content.getBytes());

            // Compile C++
            String executableName = mainClassName + (System.getProperty("os.name").toLowerCase().contains("win") ? ".exe" : "");
            ProcessBuilder compileBuilder = new ProcessBuilder("g++", "-o", executableName, filename);
            compileBuilder.directory(tempDir.toFile());
            compileBuilder.redirectErrorStream(true);

            Process compileProcess = compileBuilder.start();
            String compileOutput = readProcessOutput(compileProcess);
            
            if (compileProcess.waitFor(TIMEOUT_SECONDS, TimeUnit.SECONDS) && compileProcess.exitValue() == 0) {
                // Compilation successful, now run
                ProcessBuilder runBuilder = new ProcessBuilder("./" + executableName);
                runBuilder.directory(tempDir.toFile());
                runBuilder.redirectErrorStream(true);

                Process runProcess = runBuilder.start();
                String runOutput = readProcessOutput(runProcess);
                
                if (runProcess.waitFor(TIMEOUT_SECONDS, TimeUnit.SECONDS)) {
                    result.put("success", runProcess.exitValue() == 0);
                    result.put("output", runOutput);
                    result.put("error", runProcess.exitValue() != 0 ? "Runtime error (exit code: " + runProcess.exitValue() + ")" : "");
                } else {
                    result.put("success", false);
                    result.put("output", runOutput);
                    result.put("error", "Execution timeout");
                }
            } else {
                result.put("success", false);
                result.put("output", "");
                result.put("error", "Compilation failed:\n" + compileOutput);
            }

        } catch (Exception e) {
            result.put("success", false);
            result.put("output", "");
            result.put("error", "C++ execution error: " + e.getMessage() + "\n(Make sure g++ is installed)");
        }

        return result;
    }

    private String readProcessOutput(Process process) throws IOException {
        StringBuilder output = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                output.append(line).append("\n");
            }
        }
        return output.toString();
    }

    private void deleteDirectory(File directory) {
        if (directory.exists()) {
            File[] files = directory.listFiles();
            if (files != null) {
                for (File file : files) {
                    if (file.isDirectory()) {
                        deleteDirectory(file);
                    } else {
                        file.delete();
                    }
                }
            }
            directory.delete();
        }
    }
}
