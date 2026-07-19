package com.skillforge.learning.service;

import com.skillforge.auth.entity.UserEntity;
import com.skillforge.common.exception.BadRequestException;
import com.skillforge.common.exception.ResourceNotFoundException;
import com.skillforge.learning.dto.BookmarkRequest;
import com.skillforge.learning.dto.BookmarkResponse;
import com.skillforge.learning.dto.NoteRequest;
import com.skillforge.learning.dto.NoteResponse;
import com.skillforge.learning.entity.BookmarkEntity;
import com.skillforge.learning.entity.NoteEntity;
import com.skillforge.learning.repository.BookmarkRepository;
import com.skillforge.learning.repository.NoteRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
public class LearningService {
    private final NoteRepository noteRepository;
    private final BookmarkRepository bookmarkRepository;

    public LearningService(NoteRepository noteRepository, BookmarkRepository bookmarkRepository) {
        this.noteRepository = noteRepository;
        this.bookmarkRepository = bookmarkRepository;
    }

    @Transactional
    public NoteResponse createNote(NoteRequest request, UserEntity user) {
        NoteEntity note = new NoteEntity();
        note.setUserEmail(user.getEmail());
        note.setLessonId(request.lessonId());
        note.setContent(request.content().trim());
        note.setVideoTimestampSeconds(request.videoTimestampSeconds());
        NoteEntity saved = noteRepository.save(note);
        return mapNote(saved);
    }

    @Transactional
    public NoteResponse updateNote(UUID noteId, String content, UserEntity user) {
        NoteEntity note = noteRepository.findById(noteId)
                .orElseThrow(() -> new ResourceNotFoundException("Note not found"));

        if (!note.getUserEmail().equalsIgnoreCase(user.getEmail())) {
            throw new BadRequestException("Access denied");
        }

        note.setContent(content.trim());
        note.setUpdatedAt(Instant.now());
        NoteEntity saved = noteRepository.save(note);
        return mapNote(saved);
    }

    @Transactional
    public void deleteNote(UUID noteId, UserEntity user) {
        NoteEntity note = noteRepository.findById(noteId)
                .orElseThrow(() -> new ResourceNotFoundException("Note not found"));

        if (!note.getUserEmail().equalsIgnoreCase(user.getEmail())) {
            throw new BadRequestException("Access denied");
        }

        noteRepository.delete(note);
    }

    public List<NoteResponse> getNotes(UUID lessonId, UserEntity user) {
        List<NoteEntity> notes;
        if (lessonId != null) {
            notes = noteRepository.findByUserEmailAndLessonId(user.getEmail(), lessonId);
        } else {
            notes = noteRepository.findByUserEmail(user.getEmail());
        }
        return notes.stream().map(this::mapNote).toList();
    }

    @Transactional
    public BookmarkResponse createBookmark(BookmarkRequest request, UserEntity user) {
        BookmarkEntity bookmark = new BookmarkEntity();
        bookmark.setUserEmail(user.getEmail());
        bookmark.setLessonId(request.lessonId());
        bookmark.setTitle(request.title().trim());
        bookmark.setVideoTimestampSeconds(request.videoTimestampSeconds());
        BookmarkEntity saved = bookmarkRepository.save(bookmark);
        return mapBookmark(saved);
    }

    @Transactional
    public void deleteBookmark(UUID bookmarkId, UserEntity user) {
        BookmarkEntity bookmark = bookmarkRepository.findById(bookmarkId)
                .orElseThrow(() -> new ResourceNotFoundException("Bookmark not found"));

        if (!bookmark.getUserEmail().equalsIgnoreCase(user.getEmail())) {
            throw new BadRequestException("Access denied");
        }

        bookmarkRepository.delete(bookmark);
    }

    public List<BookmarkResponse> getBookmarks(UUID lessonId, UserEntity user) {
        List<BookmarkEntity> bookmarks;
        if (lessonId != null) {
            bookmarks = bookmarkRepository.findByUserEmailAndLessonId(user.getEmail(), lessonId);
        } else {
            bookmarks = bookmarkRepository.findByUserEmail(user.getEmail());
        }
        return bookmarks.stream().map(this::mapBookmark).toList();
    }

    private NoteResponse mapNote(NoteEntity note) {
        return new NoteResponse(
                note.getId(),
                note.getLessonId(),
                note.getContent(),
                note.getVideoTimestampSeconds(),
                note.getCreatedAt(),
                note.getUpdatedAt()
        );
    }

    private BookmarkResponse mapBookmark(BookmarkEntity bookmark) {
        return new BookmarkResponse(
                bookmark.getId(),
                bookmark.getLessonId(),
                bookmark.getTitle(),
                bookmark.getVideoTimestampSeconds(),
                bookmark.getCreatedAt()
        );
    }
}
