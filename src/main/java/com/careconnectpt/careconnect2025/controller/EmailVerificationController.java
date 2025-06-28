package com.careconnectpt.careconnect2025.controller;

import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.careconnectpt.careconnect2025.service.EmailVerificationService;


@RestController
@RequestMapping("/api/auth")
// @RequiredArgsConstructor
@Slf4j
public class EmailVerificationController {

    private final EmailVerificationService verificationService;
    
    public EmailVerificationController(EmailVerificationService verificationService) {
    	this.verificationService = verificationService;
    }

    @Value("${app.frontend.verified-redirect:/login?verified=true}")
    private String redirectUrl;   // where the SPA should land after success

    /** Option 1 – redirect to the front-end */
    @GetMapping("/verify-email")
    public void verifyEmail(@RequestParam String token,
                            HttpServletResponse response) throws Exception {

        Long userId = verificationService.confirmToken(token);
//        log.info("E-mail verified for user {}", userId);

        response.sendRedirect(redirectUrl);   // 302 ⇒ /login?verified=true
    }

    /** Option 2 – JSON reply (uncomment if you prefer API response) */
    /*
    @GetMapping("/verify-email")
    public ResponseEntity<ApiSuccess> verifyEmail(@RequestParam String token) {
        Long userId = verificationService.confirmToken(token);
        log.info("E-mail verified for user {}", userId);
        return ResponseEntity.ok(new ApiSuccess("E-mail confirmed.."));
    }
    */
}