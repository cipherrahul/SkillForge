package com.skillforge.career.repository;

import com.skillforge.career.entity.MockInterviewEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface MockInterviewRepository extends JpaRepository<MockInterviewEntity, UUID> {
    List<MockInterviewEntity> findByStudentEmail(String studentEmail);
}
