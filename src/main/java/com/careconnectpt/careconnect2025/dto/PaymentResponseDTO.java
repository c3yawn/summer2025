package com.careconnectpt.careconnect2025.dto;

import lombok.*;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class PaymentResponseDTO {
    private Long paymentId;
    private String status;
    private String stripeSessionId;
    private String stripePaymentIntentId;
}