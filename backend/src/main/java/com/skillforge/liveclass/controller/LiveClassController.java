package com.skillforge.liveclass.controller;

import com.skillforge.auth.entity.UserEntity;
import com.skillforge.common.api.ApiResponse;
import com.skillforge.course.service.CourseService;
import com.skillforge.liveclass.dto.*;
import com.skillforge.liveclass.service.LiveClassService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.UUID;

@RestController
public class LiveClassController {
    private final LiveClassService liveClassService;
    private final CourseService courseService;

    public LiveClassController(LiveClassService liveClassService, CourseService courseService) {
        this.liveClassService = liveClassService;
        this.courseService = courseService;
    }

    @PostMapping("/api/v1/courses/{courseId}/live-sessions")
    public ResponseEntity<ApiResponse<LiveSessionResponse>> scheduleLiveSession(@PathVariable String courseId,
                                                                                @Valid @RequestBody ScheduleSessionRequest request,
                                                                                HttpServletRequest servletRequest,
                                                                                Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        LiveSessionResponse response = liveClassService.scheduleLiveSession(UUID.fromString(courseId), request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Live session scheduled successfully", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/courses/{courseId}/live-sessions")
    public ResponseEntity<ApiResponse<List<LiveSessionResponse>>> getLiveSessions(@PathVariable String courseId,
                                                                                  HttpServletRequest servletRequest) {
        List<LiveSessionResponse> response = liveClassService.getLiveSessions(UUID.fromString(courseId));
        return ResponseEntity.ok(ApiResponse.success("Live sessions loaded", response, servletRequest.getRequestURI()));
    }

    // Global live-sessions endpoint for instructor dashboard and student app
    // Returns all sessions accessible to the current user (their enrolled/created courses)
    @GetMapping("/api/v1/live-sessions")
    public ResponseEntity<ApiResponse<List<LiveSessionResponse>>> getAllLiveSessions(HttpServletRequest servletRequest,
                                                                                     Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        List<LiveSessionResponse> response = liveClassService.getAllLiveSessionsForUser(currentUser);
        return ResponseEntity.ok(ApiResponse.success("All live sessions loaded", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/live-sessions/{sessionId}/join")
    public ResponseEntity<ApiResponse<AttendanceResponse>> joinSession(@PathVariable String sessionId,
                                                                       HttpServletRequest servletRequest,
                                                                       Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        AttendanceResponse response = liveClassService.joinSession(UUID.fromString(sessionId), currentUser);
        return ResponseEntity.ok(ApiResponse.success("Joined session", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/live-sessions/{sessionId}/leave")
    public ResponseEntity<ApiResponse<AttendanceResponse>> leaveSession(@PathVariable String sessionId,
                                                                        HttpServletRequest servletRequest,
                                                                        Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        AttendanceResponse response = liveClassService.leaveSession(UUID.fromString(sessionId), currentUser);
        return ResponseEntity.ok(ApiResponse.success("Left session", response, servletRequest.getRequestURI()));
    }

    @PutMapping("/api/v1/live-sessions/{sessionId}/recording")
    public ResponseEntity<ApiResponse<LiveSessionResponse>> updateRecording(@PathVariable String sessionId,
                                                                            @RequestParam String recordingUrl,
                                                                            HttpServletRequest servletRequest,
                                                                            Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        LiveSessionResponse response = liveClassService.updateRecordingUrl(UUID.fromString(sessionId), recordingUrl, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Recording updated", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/mentoring/book")
    public ResponseEntity<ApiResponse<MentoringResponse>> bookMentoring(@Valid @RequestBody BookMentoringRequest request,
                                                                        HttpServletRequest servletRequest,
                                                                        Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        MentoringResponse response = liveClassService.bookMentoring(request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Mentoring booking request submitted", response, servletRequest.getRequestURI()));
    }

    @PutMapping("/api/v1/mentoring/{sessionId}/status")
    public ResponseEntity<ApiResponse<MentoringResponse>> updateMentoringStatus(@PathVariable String sessionId,
                                                                               @RequestParam String status,
                                                                               HttpServletRequest servletRequest,
                                                                               Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        MentoringResponse response = liveClassService.updateMentoringStatus(UUID.fromString(sessionId), status, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Mentoring status updated", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/mentoring")
    public ResponseEntity<ApiResponse<List<MentoringResponse>>> getMentoring(HttpServletRequest servletRequest,
                                                                             Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        List<MentoringResponse> response = liveClassService.getMentoringSessions(currentUser);
        return ResponseEntity.ok(ApiResponse.success("Mentoring sessions loaded", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/live-sessions/{sessionId}/chat")
    public ResponseEntity<ApiResponse<ChatMessageResponse>> postChatMessage(@PathVariable String sessionId,
                                                                            @Valid @RequestBody PostChatMessageRequest request,
                                                                            HttpServletRequest servletRequest,
                                                                            Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        ChatMessageResponse response = liveClassService.postChatMessage(UUID.fromString(sessionId), request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Message posted", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/live-sessions/{sessionId}/chat")
    public ResponseEntity<ApiResponse<List<ChatMessageResponse>>> getChatHistory(@PathVariable String sessionId,
                                                                                 HttpServletRequest servletRequest,
                                                                                 Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        List<ChatMessageResponse> response = liveClassService.getChatHistory(UUID.fromString(sessionId), currentUser);
        return ResponseEntity.ok(ApiResponse.success("Chat history loaded", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/calendar/export")
    public ResponseEntity<String> exportCalendar(Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        String iCalString = liveClassService.generateICalendarExport(currentUser);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"schedule.ics\"")
                .contentType(MediaType.parseMediaType("text/calendar; charset=UTF-8"))
                .body(iCalString);
    }
}
