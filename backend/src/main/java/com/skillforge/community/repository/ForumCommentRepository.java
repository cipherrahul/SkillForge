package com.skillforge.community.repository;

import com.skillforge.community.entity.ForumCommentEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ForumCommentRepository extends JpaRepository<ForumCommentEntity, UUID> {
    List<ForumCommentEntity> findByPostIdOrderByCreatedAtAsc(UUID postId);
}
