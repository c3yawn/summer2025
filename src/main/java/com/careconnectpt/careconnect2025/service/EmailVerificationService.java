package com.careconnectpt.careconnect2025.service;

import java.time.Instant;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.careconnectpt.careconnect2025.model.User;
import com.careconnectpt.careconnect2025.exception.RegistrationException;
import com.careconnectpt.careconnect2025.model.EmailVerificationToken;
import com.careconnectpt.careconnect2025.repository.EmailVerificationTokenRepo;
import com.careconnectpt.careconnect2025.repository.UserRepository;

@Service
// @RequiredArgsConstructor
public class EmailVerificationService {

    private final EmailVerificationTokenRepo tokens;
    private final UserRepository users;

 
    public EmailVerificationService(EmailVerificationTokenRepo tokens, UserRepository users) {
        this.tokens = tokens;
        this.users = users;
    }
    /**
     * Verifies the token and activates the user.
     * @param token the verification token
     * @return the user id (for logging / audit)
     * @throws RegistrationException if token is invalid or expired
     */
    @Transactional
    public Long confirmToken(String token) {
        EmailVerificationToken vt = tokens.findByToken(token)
                .orElseThrow(() ->
                        new RegistrationException("Invalid verification link"));

        if (Instant.now().isAfter(vt.getExpiresAt())) {
            throw new RegistrationException("Verification link has expired");
        }

        User user = vt.getUser();
        user.setEmailVerified(true);
        users.save(user);
        tokens.delete(vt);

        return user.getId();
    }

       // Optional: Add stubs for controller compatibility
    public void sendVerificationEmail(String email) {
        // TODO: Implement email sending logic
        // This is a stub for controller compatibility
    }

    public boolean verifyToken(String token) {
        try {
            confirmToken(token);
            return true;
        } catch (RegistrationException e) {
            return false;
        }
    }
}