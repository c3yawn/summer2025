package com.careconnectpt.careconnect2025.repository;

import com.careconnectpt.careconnect2025.model.Achievement;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;


@Repository
public interface AchievementRepository extends JpaRepository<Achievement, Long> {

}