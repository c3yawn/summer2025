package com.focusedai.codecompiler;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.services.ecs.EcsClient;
import software.amazon.awssdk.services.s3.S3Client;

@Configuration
public class AwsConfiguration {

    @Bean
    public EcsClient ecsClient() {
        return EcsClient.builder().build();
    }

    @Bean
    public S3Client s3Client() {
        return S3Client.builder().build();
    }
}