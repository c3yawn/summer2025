package com.focusedai.codecompiler.service;

import com.focusedai.codecompiler.CompilationResult;
import com.focusedai.codecompiler.model.CodeFile;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.BodyInserters;

import java.util.List;
import java.util.ArrayList;

@Service
public class LambdaCodeCompilerService {

    @Value("${lambda.python.url}")
    private String pythonLambdaUrl;

    @Value("${lambda.javascript.url}")
    private String javascriptLambdaUrl;

    @Value("${lambda.java.url}")
    private String javaLambdaUrl;

    @Value("${lambda.cpp.url}")
    private String cppLambdaUrl;

    private final WebClient webClient;

    public LambdaCodeCompilerService(WebClient.Builder webClientBuilder) {
        this.webClient = webClientBuilder
                .codecs(configurer -> configurer.defaultCodecs().maxInMemorySize(10 * 1024 * 1024))
                .build();
    }

    public CompilationResult compileAndRun(String language, List<CodeFile> files, String mainClassName) {
        try {
            // Create request payload
            LambdaRequest request = new LambdaRequest();
            
            // Convert CodeFile objects to LambdaFile objects
            List<LambdaFile> lambdaFiles = new ArrayList<>();
            for (CodeFile file : files) {
                LambdaFile lambdaFile = new LambdaFile();
                lambdaFile.setFilename(file.getFilename());
                lambdaFile.setContent(file.getContent());
                lambdaFiles.add(lambdaFile);
            }
            request.setFiles(lambdaFiles);
            
            if (mainClassName != null && !mainClassName.isEmpty()) {
                request.setMainClassName(mainClassName);
            }

            // Get the correct Lambda Function URL based on language
            String lambdaUrl = getLambdaUrl(language);
            
            // Make HTTP request directly to Lambda Function URL
            LambdaResponse response = webClient
                    .post()
                    .uri(lambdaUrl)
                    .header("Content-Type", "application/json")
                    .body(BodyInserters.fromValue(request))
                    .retrieve()
                    .bodyToMono(LambdaResponse.class)
                    .timeout(java.time.Duration.ofSeconds(45))
                    .block();

            // Convert Lambda response to your existing format
            return convertToCompilationResult(response, language);

        } catch (Exception e) {
            return createErrorResult("Lambda execution failed: " + e.getMessage(), language);
        }
    }

    private String getLambdaUrl(String language) {
        return switch (language.toLowerCase()) {
            case "python" -> pythonLambdaUrl;
            case "javascript", "js" -> javascriptLambdaUrl;
            case "java" -> javaLambdaUrl;
            case "cpp", "c++" -> cppLambdaUrl;
            default -> throw new IllegalArgumentException("Unsupported language: " + language);
        };
    }
    private CompilationResult convertToCompilationResult(LambdaResponse response, String language) {
        CompilationResult result = new CompilationResult();
        result.setSuccess(response.isSuccess());
        result.setOutput(response.getOutput());
        result.setError(response.getError());
        // Note: Not setting language since setLanguage may not exist in your CompilationResult
        
        return result;
    }

    private CompilationResult createErrorResult(String errorMessage, String language) {
        CompilationResult result = new CompilationResult();
        result.setSuccess(false);
        result.setOutput("");
        result.setError(errorMessage);
        // Note: Not setting language since setLanguage may not exist in your CompilationResult
        return result;
    }

    // Inner classes for Lambda API communication
    public static class LambdaRequest {
        private List<LambdaFile> files;
        private String mainClassName;

        public List<LambdaFile> getFiles() { return files; }
        public void setFiles(List<LambdaFile> files) { this.files = files; }
        public String getMainClassName() { return mainClassName; }
        public void setMainClassName(String mainClassName) { this.mainClassName = mainClassName; }
    }

    public static class LambdaFile {
        private String filename;
        private String content;

        public String getFilename() { return filename; }
        public void setFilename(String filename) { this.filename = filename; }
        public String getContent() { return content; }
        public void setContent(String content) { this.content = content; }
    }

    public static class LambdaResponse {
        private boolean success;
        private String output;
        private String error;

        public boolean isSuccess() { return success; }
        public void setSuccess(boolean success) { this.success = success; }
        public String getOutput() { return output; }
        public void setOutput(String output) { this.output = output; }
        public String getError() { return error; }
        public void setError(String error) { this.error = error; }
    }
}
