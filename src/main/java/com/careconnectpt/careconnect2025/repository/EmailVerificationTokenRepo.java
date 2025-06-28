package com.careconnectpt.careconnect2025.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import com.careconnectpt.careconnect2025.model.EmailVerificationToken;

public interface EmailVerificationTokenRepo extends JpaRepository<EmailVerificationToken, Long> {
    Optional<EmailVerificationToken> findByToken(String token);
}
