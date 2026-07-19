package com.skillforge.career.repository;

import com.skillforge.career.entity.JobListingEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface JobListingRepository extends JpaRepository<JobListingEntity, UUID> {
    List<JobListingEntity> findByType(String type);
}
