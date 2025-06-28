package com.careconnectpt.careconnect2025.config;

import com.stripe.Stripe;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

import javax.annotation.PostConstruct;

@Configuration
public class StripeConfig {

    @Value("${stripe.secret-key}")
    private final String secretKey = "agshdfgajsd";

    @PostConstruct
    void init() {
        if (secretKey == null || secretKey.isBlank()) {
            System.out.println("Stripe secret key not set – payments disabled");
            return;                            
        }
        Stripe.apiKey = secretKey;
        System.out.println("Stripe key loaded.");
    }
}