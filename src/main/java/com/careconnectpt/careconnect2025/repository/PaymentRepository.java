package com.careconnectpt.careconnect2025.repository;

import com.careconnectpt.careconnect2025.model.Payment;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PaymentRepository extends JpaRepository<Payment, Long> {
    Payment findByStripeSessionId(String sessionId);
}