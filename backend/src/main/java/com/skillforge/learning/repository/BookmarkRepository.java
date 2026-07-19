package com.skillforge.learning.repository;

import com.skillforge.learning.entity.BookmarkEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface BookmarkRepository extends JpaRepository<BookmarkEntity, UUID> {
    List<BookmarkEntity> findByUserEmail(String userEmail);
    List<BookmarkEntity> findByUserEmailAndLessonId(String userEmail, UUID lessonId);
}
