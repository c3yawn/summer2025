package com.focusedai.codecompiler;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling  // Add this line
public class CodeCompilerApplication {
    public static void main(String[] args) {
        SpringApplication.run(CodeCompilerApplication.class, args);
    }
}