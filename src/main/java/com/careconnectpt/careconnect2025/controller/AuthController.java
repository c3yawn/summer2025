package com.careconnectpt.careconnect2025.controller;

import com.careconnectpt.careconnect2025.dto.CaregiverRegistration;
import com.careconnectpt.careconnect2025.dto.LoginRequest;
import com.careconnectpt.careconnect2025.dto.LoginResponse;
import com.careconnectpt.careconnect2025.dto.PatientRegistration;
import com.careconnectpt.careconnect2025.model.Caregiver;
import com.careconnectpt.careconnect2025.model.Patient;
import com.careconnectpt.careconnect2025.service.AuthService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/v1/api")
public class AuthController {


    private final AuthService auth;
    public AuthController(AuthService auth) { this.auth = auth; }


    // @PostMapping("/register")
    // public ResponseEntity<LoginResponse> register(@RequestBody PatientRegistration reg) {
    //     auth.registerPatient(reg);
	// 	return null;
    // }
    
    @PostMapping("/caregivers/{caregiverId}/patients")
    public ResponseEntity<Patient> registerPatient(
            @PathVariable Long caregiverId,
            @RequestBody PatientRegistration reg) {
        reg.setCaregiverId(caregiverId); 
        Patient patient = auth.registerPatient(reg);
        return ResponseEntity.ok(patient);
    }

    @PostMapping("/caregivers")
    public ResponseEntity<Caregiver> registerCaregiver(@RequestBody CaregiverRegistration reg) {
        Caregiver caregiver = auth.registerCaregiver(reg);
        return ResponseEntity.status(HttpStatus.CREATED).body(caregiver);
    }

    @PostMapping("/auth/login")
    public ResponseEntity<LoginResponse> login(@RequestBody LoginRequest req) {
        return ResponseEntity.ok(auth.login(req));
    }
    
    @PostMapping("/auth/logout")
    public ResponseEntity<String> logout() { return ResponseEntity.ok("User logged out"); }
    
    @PostMapping("/password-reset")
    public ResponseEntity<String> resetPassword() { return ResponseEntity.ok("Password reset"); }
    
    @PostMapping("/recover-account")
    public ResponseEntity<String> recoverAccount() { return ResponseEntity.ok("Account recovered"); }
    
    @PostMapping("/verify-otp")
    public ResponseEntity<String> verifyOtp() { return ResponseEntity.ok("OTP verified"); }
    
    @GetMapping("/sso/redirect")
    public ResponseEntity<String> googleSigninRedirect() { return ResponseEntity.ok("Redirecting to google"); }
    
    @PostMapping("/sso/callback")
    public ResponseEntity<String> googleSigninCallback() { return ResponseEntity.ok("SSO callback received"); }
}