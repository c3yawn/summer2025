package com.focusedai.caila_service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;

import java.util.*;

@Service
public class CailaService {

    private static final Logger logger = LoggerFactory.getLogger(CailaService.class);

    @Value("sk-f4ab0b9470de49b58ddd0470294e8240")
    private String apiKey;

    @Value("https://api.deepseek.com/chat/completions")
    private String apiUrl;

    @Value("deepseek-chat")
    private String model;

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    public CailaService(RestTemplate restTemplate, ObjectMapper objectMapper) {
        this.restTemplate = restTemplate;
        this.objectMapper = objectMapper;
    }

   public ApiResponse<Map<String, String>> chatWithCaila(CailaRequest request) {
        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("model", model);
        requestBody.put("messages", List.of(
                Map.of("role", "user", "content", request.getPrompt())
        ));
        requestBody.put("temperature", 0.7);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(apiKey);

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

        try {
            ResponseEntity<String> response = restTemplate.postForEntity(apiUrl, entity, String.class);

            JsonNode root = objectMapper.readTree(response.getBody());
            String reply = root.path("choices").path(0).path("message").path("content").asText();

            Map<String, String> responseData = new HashMap<>();
            responseData.put("response", reply);

            return ApiResponse.success("Success", responseData);
        } catch (Exception e) {
            e.printStackTrace();
            return ApiResponse.error("Failed to process AI request");
        }
    }

    public ApiResponse<Map<String, String>> generateRubric(PromptRequest promptRequest) {
        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("model", model);
        requestBody.put("messages", List.of(
                Map.of("role", "user", "content", promptRequest.getPrompt())
        ));
        requestBody.put("temperature", 0.7);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(apiKey);

        HttpEntity<Map<String, Object>> request = new HttpEntity<>(requestBody, headers);

        try {
            ResponseEntity<String> response = restTemplate.postForEntity(apiUrl, request, String.class);

            System.out.println("AI response: " + response.getBody());

            JsonNode root = objectMapper.readTree(response.getBody());
            String aiReply = root.path("choices").path(0).path("message").path("content").asText();

            Map<String, String> responseData = new HashMap<>();
            responseData.put("response", aiReply);

            return ApiResponse.success("Rubric generated", responseData);

        } catch (HttpClientErrorException | HttpServerErrorException e) {
            System.err.println("HTTP error: " + e.getStatusCode());
            System.err.println("Error response: " + e.getResponseBodyAsString());
            throw new RuntimeException("Rubric generation failed: " + e.getStatusCode());
        } catch (Exception e) {
            e.printStackTrace();
            throw new RuntimeException("Unexpected error during rubric generation");
        }
    }



    private String stylePromptByRole(String role, String prompt) {
        return "teacher".equals(role)
                ? "As an educator, " + prompt
                : "Explain to a student: " + prompt;
    }
}

