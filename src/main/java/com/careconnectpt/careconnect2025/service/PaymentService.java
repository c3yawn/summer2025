package com.careconnectpt.careconnect2025.service;


import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import com.careconnectpt.careconnect2025.repository.PaymentRepository;
import com.careconnectpt.careconnect2025.model.Payment;

@Service
@RequiredArgsConstructor
public class PaymentService {
    private final PaymentRepository paymentRepository;

    public void savePayment(Payment payment) {
        paymentRepository.save(payment);
    }

    public Payment getByStripeSessionId(String sessionId) {
        return paymentRepository.findByStripeSessionId(sessionId);
    }
}