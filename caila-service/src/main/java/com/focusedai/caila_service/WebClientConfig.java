package com.focusedai.caila_service;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.client.RestTemplate;

@Configuration
public class WebClientConfig {
     @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }
    @Bean
    public WebClient.Builder webClientBuilder() {
        return WebClient.builder();
    }
}
