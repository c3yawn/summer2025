package com.careconnectpt.careconnect2025.dto;

import lombok.Builder;

import java.time.Instant;
import java.util.List;

@Builder
public record DashboardDTO(
        Instant periodStart,
        Instant periodEnd,
        double adherenceRate,
        double avgHeartRate,
        Double avgSpo2,            // nullable
        Double avgSystolic,
        Double avgDiastolic,
        Double avgWeight
) {}