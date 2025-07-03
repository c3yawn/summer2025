package com.focusedai.codecompiler.controller;

import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import org.springframework.beans.factory.annotation.Autowired;
import com.focusedai.codecompiler.service.LambdaExecutionService;
import java.util.Map;
import java.util.HashMap;
import java.util.List;

@RestController
public class ApiController {

    @Autowired
    private LambdaExecutionService lambdaExecutionService;

    @RequestMapping(value = "/**", method = RequestMethod.OPTIONS)
    public ResponseEntity<Void> handlePreflight() {
        return new ResponseEntity<>(HttpStatus.OK);
    }

    @GetMapping("/")
    public ResponseEntity<String> home() {
        return ResponseEntity.ok(
            "🎉 Code Compiler Backend: RUNNING!\n" +
            "🚀 AWS Lambda execution: CONFIGURED\n" +
            "⚡ Real Lambda Function URLs: CONNECTED\n" +
            "🔗 Port 3000 → Port 8080 → AWS Lambda\n" +
            "📱 Flutter Web app → Spring Boot → Your Lambda functions!\n\n" +
            "🌟 Ready for serverless code execution!"
        );
    }

    @GetMapping("/lambda-status")
    public ResponseEntity<Map<String, Object>> getLambdaStatus() {
        Map<String, Object> status = lambdaExecutionService.getLambdaStatus();
        return ResponseEntity.ok(status);
    }

    @GetMapping("/lambda-test")
    public ResponseEntity<Map<String, Object>> testAllEndpoints() {
        Map<String, Object> results = lambdaExecutionService.testAllLambdaFunctions();
        return ResponseEntity.ok(results);
    }

    @PostMapping("/api/compile/{language}")
    public ResponseEntity<Map<String, Object>> compileCode(
            @PathVariable String language,
            @RequestBody Map<String, Object> payload) {
        
        try {
            @SuppressWarnings("unchecked")
            List<Map<String, String>> files = (List<Map<String, String>>) payload.get("files");
            String mainClassName = (String) payload.get("mainClassName");

            if (files == null || files.isEmpty()) {
                Map<String, Object> errorResponse = new HashMap<>();
                errorResponse.put("success", false);
                errorResponse.put("output", "");
                errorResponse.put("error", "No files provided");
                return ResponseEntity.badRequest().body(errorResponse);
            }

            // Execute using AWS Lambda Function URLs
            Map<String, Object> result = lambdaExecutionService.executeCodeWithLambda(language, files, mainClassName);
            
            return ResponseEntity.ok(result);
            
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("output", "");
            errorResponse.put("error", "Server error: " + e.getMessage());
            errorResponse.put("executionType", "Error");
            
            return ResponseEntity.status(500).body(errorResponse);
        }
    }
}
