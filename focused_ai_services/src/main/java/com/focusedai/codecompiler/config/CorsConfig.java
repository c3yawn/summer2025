package com.focusedai.codecompiler.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class CorsConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**") // Apply CORS to all endpoints
                .allowedOrigins(
                    "http://localhost:3000",
                    "http://localhost:5000",
                    "http://127.0.0.1:3000",
                    "http://127.0.0.1:5000"
                )
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS") // Allow all HTTP methods
                .allowedHeaders("*") // Allow all request headers
                .allowCredentials(true) // Allow sending credentials like cookies/auth headers
                .maxAge(3600);
    }
}