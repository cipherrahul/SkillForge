package com.skillforge.community.repository;

import com.skillforge.community.entity.StudentGroupEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface StudentGroupRepository extends JpaRepository<StudentGroupEntity, UUID> {
    Optional<StudentGroupEntity> findByNameIgnoreCase(String name);
}
