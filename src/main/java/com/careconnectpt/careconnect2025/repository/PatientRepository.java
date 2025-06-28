package com.careconnectpt.careconnect2025.repository;


import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import com.careconnectpt.careconnect2025.model.Patient;

public interface PatientRepository extends JpaRepository<Patient, Long> {
    List<Patient> findByCaregiverId(Long caregiverId);
}