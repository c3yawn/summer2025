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

    @GetMapping("/cache/stats")
    public ResponseEntity<Map<String, Object>> getCacheStats() {
        try {
            Map<String, Object> stats = compilerService.getCacheStats();
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(
                Map.of("error", "Failed to get cache stats: " + e.getMessage())
            );
        }
    }

    @PostMapping("/cache/clear")
    public ResponseEntity<Map<String, String>> clearCache() {
        try {
            compilerService.clearCache();
            return ResponseEntity.ok(Map.of(
                "message", "Cache cleared successfully",
                "timestamp", java.time.Instant.now().toString()
            ));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(
                Map.of("error", "Failed to clear cache: " + e.getMessage())
            );
        }
    }

    @GetMapping("/fast/stats")
    public ResponseEntity<Map<String, Object>> getFastExecutionStats() {
        try {
            Map<String, Object> stats = compilerService.getFastExecutionStats();
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(
                Map.of("error", "Failed to get fast execution stats: " + e.getMessage())
            );
        }
    }

@PostMapping("/fast/test")
public ResponseEntity<Map<String, Object>> testFastExecution(
        @RequestParam("language") String language,
        @RequestParam("javaFiles") MultipartFile[] files) {
    try {
        List<MultipartFile> fileList = Arrays.asList(files);
        boolean canExecuteFast = compilerService.canExecuteFast(language, fileList);
        
        return ResponseEntity.ok(Map.of(
            "language", language,
            "file_count", files.length,
            "file_size", files[0].getSize(),
            "can_execute_fast", canExecuteFast,
            "reason", canExecuteFast ? "Eligible for fast execution" : "Must use ECS execution"
        ));
    } catch (Exception e) {
        return ResponseEntity.internalServerError().body(
            Map.of("error", "Failed to test fast execution: " + e.getMessage())
        );
    }
}

    @GetMapping("/warm-pool/status")
    public ResponseEntity<Map<String, Object>> getWarmPoolStatus() {
        try {
            Map<String, Object> status = compilerService.getWarmPoolStatus();
            return ResponseEntity.ok(status);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(
                Map.of("error", "Failed to get warm pool status: " + e.getMessage())
            );
        }
    }

    @GetMapping("/warm-pool/count")
    public ResponseEntity<Map<String, Object>> getWarmTaskCount() {
        try {
            int count = compilerService.getWarmTaskCount();
            return ResponseEntity.ok(Map.of(
                "warm_task_count", count,
                "timestamp", java.time.Instant.now().toString()
            ));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(
                Map.of("error", "Failed to get warm task count: " + e.getMessage())
            );
        }
    }

}
