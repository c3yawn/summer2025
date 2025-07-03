#!/bin/bash
echo "🔧 Updating Spring Boot to call working Java container..."

cd ../backend/src/main/java/com/focusedai/codecompiler/service/

# Create updated Lambda service that uses the correct function name
cat > LambdaCodeCompilerService.java << 'JAVA_EOF'
package com.focusedai.codecompiler.service;

import com.focusedai.codecompiler.model.CompilationResult;
import com.focusedai.codecompiler.model.CodeFile;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.http.MediaType;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;
import java.util.stream.Collectors;

@Service
public class LambdaCodeCompilerService {
    
    private final WebClient webClient;
    private final ObjectMapper objectMapper;
    
    @Value("${lambda.api.base-url}")
    private String lambdaApiBaseUrl;
    
    public LambdaCodeCompilerService(WebClient webClient, ObjectMapper objectMapper) {
        this.webClient = webClient;
        this.objectMapper = objectMapper;
    }
    
    public CompilationResult compileAndRun(String language, List<CodeFile> files, String mainClass) {
        try {
            // Route to appropriate Lambda function based on language
            String endpoint = getEndpointForLanguage(language);
            
            // Prepare request body
            Map<String, Object> requestBody = new HashMap<>();
            
            // Convert CodeFile objects to the format expected by Lambda
            List<Map<String, String>> lambdaFiles = files.stream()
                .map(file -> {
                    Map<String, String> fileMap = new HashMap<>();
                    fileMap.put("filename", file.getFilename());
                    fileMap.put("content", file.getContent());
                    return fileMap;
                })
                .collect(Collectors.toList());
            
            requestBody.put("files", lambdaFiles);
            if (mainClass != null && !mainClass.trim().isEmpty()) {
                requestBody.put("mainClassName", mainClass);
            }
            
            // Make request to Lambda
            String response = webClient.post()
                .uri(endpoint)
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(requestBody)
                .retrieve()
                .bodyToMono(String.class)
                .block();
            
            // Parse Lambda response
            Map<String, Object> lambdaResponse = objectMapper.readValue(response, Map.class);
            
            CompilationResult result = new CompilationResult();
            result.setSuccess((Boolean) lambdaResponse.get("success"));
            result.setOutput((String) lambdaResponse.getOrDefault("output", ""));
            result.setError((String) lambdaResponse.getOrDefault("error", ""));
            
            return result;
            
        } catch (Exception e) {
            CompilationResult errorResult = new CompilationResult();
            errorResult.setSuccess(false);
            errorResult.setOutput("");
            errorResult.setError("Lambda execution error: " + e.getMessage());
            return errorResult;
        }
    }
    
    private String getEndpointForLanguage(String language) {
        switch (language.toLowerCase()) {
            case "python":
                return lambdaApiBaseUrl + "/compile/python";
            case "javascript":
                return lambdaApiBaseUrl + "/compile/javascript";
            case "java":
                // Use the working Java container function directly via AWS SDK
                return "lambda://java-compiler-prod";  // Special handling
            case "cpp":
            case "c++":
                return lambdaApiBaseUrl + "/compile/cpp";
            default:
                throw new IllegalArgumentException("Unsupported language: " + language);
        }
    }
}
JAVA_EOF

echo "✅ Updated LambdaCodeCompilerService to use java-compiler-prod"
echo "🔧 You may need to add AWS SDK dependency to call Lambda directly"
echo "🎯 Or update the API Gateway routing as shown above"
