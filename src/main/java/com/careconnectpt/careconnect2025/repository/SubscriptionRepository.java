package com.careconnectpt.careconnect2025.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.careconnectpt.careconnect2025.model.Subscription;

import java.util.Optional;

public interface SubscriptionRepository extends JpaRepository<Subscription, Long> {
    Optional<Subscription> findByStripeSubscriptionId(String stripeId);
}
