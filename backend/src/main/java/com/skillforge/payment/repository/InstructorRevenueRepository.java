package com.skillforge.payment.repository;

import com.skillforge.payment.entity.InstructorRevenueEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface InstructorRevenueRepository extends JpaRepository<InstructorRevenueEntity, UUID> {
    List<InstructorRevenueEntity> findByInstructorEmail(String instructorEmail);
}
