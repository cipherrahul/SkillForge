package com.skillforge.learning.repository;

import com.skillforge.learning.entity.NoteEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface NoteRepository extends JpaRepository<NoteEntity, UUID> {
    List<NoteEntity> findByUserEmail(String userEmail);
    List<NoteEntity> findByUserEmailAndLessonId(String userEmail, UUID lessonId);
}
