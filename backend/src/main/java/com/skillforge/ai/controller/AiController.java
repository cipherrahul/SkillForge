package com.skillforge.ai.controller;

import com.skillforge.auth.entity.UserEntity;
import com.skillforge.common.api.ApiResponse;
import com.skillforge.course.dto.CourseResponse;
import com.skillforge.course.service.CourseService;
import com.skillforge.ai.dto.*;
import com.skillforge.ai.service.AiService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.UUID;

@RestController
public class AiController {
    private final AiService aiService;
    private final CourseService courseService;

    public AiController(AiService aiService, CourseService courseService) {
        this.aiService = aiService;
        this.courseService = courseService;
    }

    @PostMapping("/api/v1/ai/sessions")
    public ResponseEntity<ApiResponse<AiSessionResponse>> startSession(@Valid @RequestBody StartAiSessionRequest request,
                                                                       HttpServletRequest servletRequest,
                                                                       Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        AiSessionResponse response = aiService.startSession(request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("AI Chat session initialized", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/ai/sessions/{sessionId}/messages")
    public ResponseEntity<ApiResponse<List<AiMessageResponse>>> sendMessage(@PathVariable String sessionId,
                                                                            @Valid @RequestBody SendMessageRequest request,
                                                                            HttpServletRequest servletRequest,
                                                                            Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        List<AiMessageResponse> response = aiService.sendMessage(UUID.fromString(sessionId), request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Message processed by AI", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/ai/sessions/{sessionId}/history")
    public ResponseEntity<ApiResponse<List<AiMessageResponse>>> getChatHistory(@PathVariable String sessionId,
                                                                               HttpServletRequest servletRequest) {
        List<AiMessageResponse> response = aiService.getChatHistory(UUID.fromString(sessionId));
        return ResponseEntity.ok(ApiResponse.success("Chat history loaded", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/ai/lessons/{lessonId}/generate-quiz")
    public ResponseEntity<ApiResponse<Void>> generateQuiz(@PathVariable String lessonId,
                                                          HttpServletRequest servletRequest,
                                                          Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        aiService.generateQuiz(UUID.fromString(lessonId), currentUser);
        return ResponseEntity.ok(ApiResponse.success("AI quiz generated successfully", null, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/ai/lessons/{lessonId}/generate-notes")
    public ResponseEntity<ApiResponse<Void>> generateNotes(@PathVariable String lessonId,
                                                           HttpServletRequest servletRequest,
                                                           Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        aiService.generateNotes(UUID.fromString(lessonId), currentUser);
        return ResponseEntity.ok(ApiResponse.success("AI notes compiled and saved", null, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/ai/roadmap")
    public ResponseEntity<ApiResponse<AiRoadmapResponse>> generateRoadmap(@Valid @RequestBody GenerateRoadmapRequest request,
                                                                          HttpServletRequest servletRequest,
                                                                          Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        AiRoadmapResponse response = aiService.generateRoadmap(request.topic(), currentUser);
        return ResponseEntity.ok(ApiResponse.success("Custom roadmap built", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/ai/recommendations")
    public ResponseEntity<ApiResponse<List<CourseResponse>>> getRecommendations(HttpServletRequest servletRequest,
                                                                                Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        List<CourseResponse> response = aiService.getRecommendations(currentUser).stream()
                .map(c -> courseService.getCourseDetails(c.getId().toString(), currentUser))
                .toList();
        return ResponseEntity.ok(ApiResponse.success("Recommendations loaded", response, servletRequest.getRequestURI()));
    }
}
