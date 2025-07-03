package com.focusedai.caila_service;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;

@SpringBootApplication(exclude = {DataSourceAutoConfiguration.class})
public class CailaApplication {
    public static void main(String[] args) {
        SpringApplication.run(CailaApplication.class, args);
    }
}
