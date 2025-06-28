package com.careconnectpt.careconnect2025.model;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;

@Entity
public class ResetToken {
    @Id
    private Long id;
    private String token;
}