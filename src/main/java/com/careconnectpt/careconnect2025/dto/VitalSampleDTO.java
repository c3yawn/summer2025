package com.careconnectpt.careconnect2025.dto;

import lombok.Builder;

import java.time.Instant;
import java.util.List;

@Builder
public record VitalSampleDTO(
        Long patientId,
        Instant timestamp,
        Double heartRate,
        Double spo2,
        Integer systolic,
        Integer diastolic,
        Double weight
) {}