package com.careconnectpt.careconnect2025.controller;


import lombok.RequiredArgsConstructor;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

import com.careconnectpt.careconnect2025.dto.Metrics;
import com.careconnectpt.careconnect2025.service.FitbitService;


@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class MetricsApiController {

    private final FitbitService fitbitService = null;
    

    @GetMapping("/metrics/today")
    public Metrics today() {
        return fitbitService.getTodayMetrics();
    }
    
    @GetMapping("/metrics")
    public String metrics() {
        return "metrics";         
    }
}
