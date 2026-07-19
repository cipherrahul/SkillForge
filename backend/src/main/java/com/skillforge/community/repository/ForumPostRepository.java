package com.skillforge.community.repository;

import com.skillforge.community.entity.ForumPostEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ForumPostRepository extends JpaRepository<ForumPostEntity, UUID> {
    List<ForumPostEntity> findByCourseId(UUID courseId);
    List<ForumPostEntity> findByCourseIdIsNull();
}
