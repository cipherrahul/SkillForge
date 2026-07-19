package com.skillforge.community.repository;

import com.skillforge.community.entity.AnnouncementEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AnnouncementRepository extends JpaRepository<AnnouncementEntity, UUID> {
    List<AnnouncementEntity> findByCourseId(UUID courseId);
    List<AnnouncementEntity> findByCourseIdIsNull();
}
