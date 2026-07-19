package com.skillforge.learning.controller;

import com.skillforge.auth.entity.UserEntity;
import com.skillforge.common.api.ApiResponse;
import com.skillforge.course.service.CourseService;
import com.skillforge.learning.dto.BookmarkRequest;
import com.skillforge.learning.dto.BookmarkResponse;
import com.skillforge.learning.dto.NoteRequest;
import com.skillforge.learning.dto.NoteResponse;
import com.skillforge.learning.dto.UpdateNoteRequest;
import com.skillforge.learning.service.LearningService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.UUID;

@RestController
public class LearningController {
    private final LearningService learningService;
    private final CourseService courseService;

    public LearningController(LearningService learningService, CourseService courseService) {
        this.learningService = learningService;
        this.courseService = courseService;
    }

    @PostMapping("/api/v1/notes")
    public ResponseEntity<ApiResponse<NoteResponse>> createNote(@Valid @RequestBody NoteRequest request,
                                                                HttpServletRequest servletRequest,
                                                                Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        NoteResponse response = learningService.createNote(request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Note created successfully", response, servletRequest.getRequestURI()));
    }

    @PutMapping("/api/v1/notes/{noteId}")
    public ResponseEntity<ApiResponse<NoteResponse>> updateNote(@PathVariable String noteId,
                                                                @Valid @RequestBody UpdateNoteRequest request,
                                                                HttpServletRequest servletRequest,
                                                                Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        NoteResponse response = learningService.updateNote(UUID.fromString(noteId), request.content(), currentUser);
        return ResponseEntity.ok(ApiResponse.success("Note updated successfully", response, servletRequest.getRequestURI()));
    }

    @DeleteMapping("/api/v1/notes/{noteId}")
    public ResponseEntity<ApiResponse<Void>> deleteNote(@PathVariable String noteId,
                                                        HttpServletRequest servletRequest,
                                                        Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        learningService.deleteNote(UUID.fromString(noteId), currentUser);
        return ResponseEntity.ok(ApiResponse.success("Note deleted successfully", null, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/notes")
    public ResponseEntity<ApiResponse<List<NoteResponse>>> getNotes(@RequestParam(required = false) String lessonId,
                                                                    HttpServletRequest servletRequest,
                                                                    Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        UUID lessonUuid = lessonId == null ? null : UUID.fromString(lessonId);
        List<NoteResponse> response = learningService.getNotes(lessonUuid, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Notes loaded", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/bookmarks")
    public ResponseEntity<ApiResponse<BookmarkResponse>> createBookmark(@Valid @RequestBody BookmarkRequest request,
                                                                        HttpServletRequest servletRequest,
                                                                        Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        BookmarkResponse response = learningService.createBookmark(request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Bookmark created successfully", response, servletRequest.getRequestURI()));
    }

    @DeleteMapping("/api/v1/bookmarks/{bookmarkId}")
    public ResponseEntity<ApiResponse<Void>> deleteBookmark(@PathVariable String bookmarkId,
                                                            HttpServletRequest servletRequest,
                                                            Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        learningService.deleteBookmark(UUID.fromString(bookmarkId), currentUser);
        return ResponseEntity.ok(ApiResponse.success("Bookmark deleted successfully", null, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/bookmarks")
    public ResponseEntity<ApiResponse<List<BookmarkResponse>>> getBookmarks(@RequestParam(required = false) String lessonId,
                                                                            HttpServletRequest servletRequest,
                                                                            Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        UUID lessonUuid = lessonId == null ? null : UUID.fromString(lessonId);
        List<BookmarkResponse> response = learningService.getBookmarks(lessonUuid, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Bookmarks loaded", response, servletRequest.getRequestURI()));
    }
}
