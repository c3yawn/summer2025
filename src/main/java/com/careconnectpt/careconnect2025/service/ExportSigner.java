package com.careconnectpt.careconnect2025.service;

import java.time.Duration;
import java.time.Instant;

import org.springframework.stereotype.Service;

import com.careconnectpt.careconnect2025.dto.ExportLinkDTO;

import lombok.RequiredArgsConstructor;

/** Responsible for 1-hour signed URLs (could wrap AWS S3, CloudFront, MinIO, etc.) */
@Service
@RequiredArgsConstructor
public class ExportSigner {

    private static final Duration TTL = Duration.ofHours(1);

    public ExportLinkDTO sign(String relativePath) {
        String url = "https://files.careconnect.ai" + relativePath + "?sig=mock123"; // TODO real signer
        return ExportLinkDTO.builder()
                .url(url)
                .expiresAt(Instant.now().plus(TTL))
                .build();
    }
}