package com.careconnectpt.careconnect2025.controller;


import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/dashboard")
public class DashboardController {

    @GetMapping("/caregiver")
    @PreAuthorize("hasRole('CAREGIVER')")
    public String caregiverDashboard() {
        return "Caregiver Dashboard - Confidential Content";
    }

    @GetMapping("/patient")
    @PreAuthorize("hasRole('PATIENT')")
    public String patientDashboard() {
        return "Patient Dashboard - Personal Health Info";
    }
}
