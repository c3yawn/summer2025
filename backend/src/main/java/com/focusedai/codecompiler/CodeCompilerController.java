package com.focusedai.codecompiler;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Arrays;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/code")
@CrossOrigin(origins = {"http://localhost:3000", "https://your-frontend-domain.com"})
public class CodeCompilerController {

    private final EcsCodeCompilerService compilerService;

    @Autowired
    public CodeCompilerController(EcsCodeCompilerService compilerService) {
        this.compilerService = compilerService;
    }

    @PostMapping("/execute")
    public ResponseEntity<CompilationResult> executeCode(
            @RequestParam("language") String language,
            @RequestParam(value = "mainClassName", required = false) String mainClassName,
            @RequestParam("javaFiles") MultipartFile[] files) {

        try {
            // Validate language
            List<String> supportedLanguages = Arrays.asList("java", "javascript", "python", "cpp");
            if (!supportedLanguages.contains(language.toLowerCase())) {
                CompilationResult errorResult = CompilationResult.builder()
                        .success(false)
                        .output("")
                        .error("Unsupported language: " + language + ". Supported languages: " + supportedLanguages)
                        .build();
                return ResponseEntity.badRequest().body(errorResult);
            }

            // Validate files
            if (files == null || files.length == 0) {
                CompilationResult errorResult = CompilationResult.builder()
                        .success(false)
                        .output("")
                        .error("No source files provided")
                        .build();
                return ResponseEntity.badRequest().body(errorResult);
            }

            // Check for empty files
            for (MultipartFile file : files) {
                if (file.isEmpty()) {
                    CompilationResult errorResult = CompilationResult.builder()
                            .success(false)
                            .output("")
                            .error("Empty file detected: " + file.getOriginalFilename())
                            .build();
                    return ResponseEntity.badRequest().body(errorResult);
                }
            }

            // Execute compilation
            List<MultipartFile> fileList = Arrays.asList(files);
            CompilationResult result = compilerService.executeCode(language, mainClassName, fileList);

            return ResponseEntity.ok(result);

        } catch (Exception e) {
            CompilationResult errorResult = CompilationResult.builder()
                    .success(false)
                    .output("")
                    .error("Internal server error: " + e.getMessage())
                    .build();
            return ResponseEntity.internalServerError().body(errorResult);
        }
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> healthCheck() {
        try {
            Map<String, Object> health = compilerService.getHealthStatus();
            return ResponseEntity.ok(health);
        } catch (Exception e) {
            Map<String, Object> errorHealth = Map.of(
                    "status", "unhealthy",
                    "service", "ECS Code Compiler",
                    "error", e.getMessage()
            );
            return ResponseEntity.internalServerError().body(errorHealth);
        }
    }

    @GetMapping("/supported-languages")
    public ResponseEntity<List<String>> getSupportedLanguages() {
        List<String> languages = Arrays.asList("java", "javascript", "python", "cpp");
        return ResponseEntity.ok(languages);
    }
}
