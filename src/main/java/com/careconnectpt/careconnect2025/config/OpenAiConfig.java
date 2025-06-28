package com.careconnectpt.careconnect2025.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import com.theokanning.openai.service.OpenAiService;

@Configuration
public class OpenAiConfig {

    @Bean
    public OpenAiService openAiService(OpenAiProperties props) {
        return new OpenAiService(props.getApiKey());
    }
}
