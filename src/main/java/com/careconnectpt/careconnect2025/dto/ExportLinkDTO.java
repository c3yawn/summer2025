package com.careconnectpt.careconnect2025.dto;

import lombok.Builder;

import java.time.Instant;
import java.util.List;

/** Signed export link */
@Builder
public record ExportLinkDTO(
    String url,          // presigned URL (valid 1h)
    Instant expiresAt
) {}