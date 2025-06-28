package com.careconnectpt.careconnect2025.service;


import java.util.UUID;

public class TokenProvider {
    public String generateToken() {
        return UUID.randomUUID().toString();  
    }
}
