package com.careconnectpt.careconnect2025.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.careconnectpt.careconnect2025.model.User;

import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);
}
