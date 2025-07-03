package com.focusedai.codecompiler.controller;

import com.focusedai.codecompiler.model.CompilationResult;
import com.focusedai.codecompiler.model.CodeFile;
import com.focusedai.codecompiler.service.LambdaCodeCompilerService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;
import java.util.ArrayList;
import java.io.IOException;
import java.nio.charset.StandardCharsets;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class LambdaIntegratedController {

    @Autowired
    private LambdaCodeCompilerService lambdaService;

    // NEW: Lambda-style JSON endpoints that your Flutter app expects
    @PostMapping("/compile/{language}")
    public ResponseEntity<CompilationResult> compileCode(
            @PathVariable String language,
            @RequestBody Map<String, Object> request) {
        
        try {
            // Extract files from JSON request
            @SuppressWarnings("unchecked")
            List<Map<String, String>> filesData = (List<Map<String, String>>) request.get("files");
            String mainClassName = (String) request.get("mainClassName");
            
            // Convert to CodeFile objects
            List<CodeFile> files = new ArrayList<>();
            for (Map<String, String> fileData : filesData) {
                CodeFile codeFile = new CodeFile();
                codeFile.setFilename(fileData.get("filename"));
                codeFile.setContent(fileData.get("content"));
                files.add(codeFile);
            }
            
            // Use Lambda service to compile and run
            CompilationResult result = lambdaService.compileAndRun(language, files, mainClassName);
            
            return ResponseEntity.ok(result);
            
        } catch (Exception e) {
            CompilationResult errorResult = new CompilationResult();
            errorResult.setSuccess(false);
            errorResult.setOutput("");
            errorResult.setError("Request processing error: " + e.getMessage());
            return ResponseEntity.ok(errorResult);
        }
    }

    // LEGACY: Keep old multipart endpoint for backward compatibility
    @PostMapping("/code/execute")
    public ResponseEntity<CompilationResult> executeCodeLegacy(
            @RequestParam("language") String language,
            @RequestParam("mainClassName") String mainClassName,
            @RequestParam("javaFiles") List<MultipartFile> javaFiles) {
        
        try {
            // Convert MultipartFile to CodeFile objects
            List<CodeFile> files = new ArrayList<>();
            for (MultipartFile file : javaFiles) {
                CodeFile codeFile = new CodeFile();
                codeFile.setFilename(file.getOriginalFilename());
                codeFile.setContent(new String(file.getBytes(), StandardCharsets.UTF_8));
                files.add(codeFile);
            }
            
            // Use Lambda service
            CompilationResult result = lambdaService.compileAndRun(language, files, mainClassName);
            
            return ResponseEntity.ok(result);
            
        } catch (IOException e) {
            CompilationResult errorResult = new CompilationResult();
            errorResult.setSuccess(false);
            errorResult.setOutput("");
            errorResult.setError("File processing error: " + e.getMessage());
            return ResponseEntity.ok(errorResult);
        }
    }

    // NEW: Health check endpoints for testing
    @GetMapping("/test/lambda-health")
    public ResponseEntity<String> testLambdaHealth() {
        try {
            // Test a simple Python execution to verify Lambda is working
            List<CodeFile> testFiles = new ArrayList<>();
            CodeFile testFile = new CodeFile();
            testFile.setFilename("test.py");
            testFile.setContent("print('✅ Lambda connection test successful!')");
            testFiles.add(testFile);
            
            CompilationResult result = lambdaService.compileAndRun("python", testFiles, "test");
            
            if (result.isSuccess()) {
                return ResponseEntity.ok("✅ Lambda connection: SUCCESS\nOutput: " + result.getOutput());
            } else {
                return ResponseEntity.ok("⚠️ Lambda connection: PARTIAL\nError: " + result.getError());
            }
        } catch (Exception e) {
            return ResponseEntity.ok("❌ Lambda connection: FAILED\nError: " + e.getMessage());
        }
    }

    @GetMapping("/test/lambda-all")
    public ResponseEntity<String> testAllLanguages() {
        StringBuilder output = new StringBuilder();
        output.append("🧪 Testing all Lambda languages:\n\n");
        
        String[] languages = {"python", "javascript", "java", "cpp"};
        String[] icons = {"🐍", "🟨", "☕", "⚡"};
        
        for (int i = 0; i < languages.length; i++) {
            String language = languages[i];
            String icon = icons[i];
            
            try {
                List<CodeFile> testFiles = new ArrayList<>();
                CodeFile testFile = new CodeFile();
                
                switch (language) {
                    case "python":
                        testFile.setFilename("test.py");
                        testFile.setContent("print('SUCCESS')");
                        break;
                    case "javascript":
                        testFile.setFilename("test.js");
                        testFile.setContent("console.log('SUCCESS');");
                        break;
                    case "java":
                        testFile.setFilename("Test.java");
                        testFile.setContent("public class Test { public static void main(String[] args) { System.out.println(\"SUCCESS\"); } }");
                        break;
                    case "cpp":
                        testFile.setFilename("test.cpp");
                        testFile.setContent("#include <iostream>\nusing namespace std;\nint main() { cout << \"SUCCESS\" << endl; return 0; }");
                        break;
                }
                
                testFiles.add(testFile);
                CompilationResult result = lambdaService.compileAndRun(language, testFiles, "Test");
                
                if (result.isSuccess()) {
                    output.append(icon).append(" ").append(language.substring(0, 1).toUpperCase())
                          .append(language.substring(1)).append(": ✅ SUCCESS\n");
                } else {
                    output.append(icon).append(" ").append(language.substring(0, 1).toUpperCase())
                          .append(language.substring(1)).append(": ❌ FAILED\n");
                }
                
            } catch (Exception e) {
                output.append(icon).append(" ").append(language.substring(0, 1).toUpperCase())
                      .append(language.substring(1)).append(": ❌ ERROR\n");
            }
        }
        
        return ResponseEntity.ok(output.toString());
    }

    // NEW: Individual language test endpoints
    @GetMapping("/test/lambda-{language}")
    public ResponseEntity<String> testSpecificLanguage(@PathVariable String language) {
        try {
            List<CodeFile> testFiles = new ArrayList<>();
            CodeFile testFile = new CodeFile();
            
            switch (language.toLowerCase()) {
                case "python":
                    testFile.setFilename("test.py");
                    testFile.setContent("print('Python test: SUCCESS')");
                    break;
                case "javascript":
                    testFile.setFilename("test.js");
                    testFile.setContent("console.log('JavaScript test: SUCCESS');");
                    break;
                case "java":
                    testFile.setFilename("Test.java");
                    testFile.setContent("public class Test { public static void main(String[] args) { System.out.println(\"Java test: SUCCESS\"); } }");
                    break;
                case "cpp":
                    testFile.setFilename("test.cpp");
                    testFile.setContent("#include <iostream>\nusing namespace std;\nint main() { cout << \"C++ test: SUCCESS\" << endl; return 0; }");
                    break;
                default:
                    return ResponseEntity.ok(language + " test: FAILED\nOutput:\nUnsupported language");
            }
            
            testFiles.add(testFile);
            CompilationResult result = lambdaService.compileAndRun(language.toLowerCase(), testFiles, "Test");
            
            if (result.isSuccess()) {
                return ResponseEntity.ok(language + " test: SUCCESS\nOutput:\n" + result.getOutput());
            } else {
                return ResponseEntity.ok(language + " test: FAILED\nOutput:\n" + result.getError());
            }
            
        } catch (Exception e) {
            return ResponseEntity.ok(language + " test: FAILED\nOutput:\nError: " + e.getMessage());
        }
    }
}
