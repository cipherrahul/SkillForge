package com.skillforge.ai.controller;

import com.skillforge.auth.entity.UserEntity;
import com.skillforge.common.api.ApiResponse;
import com.skillforge.course.dto.CourseResponse;
import com.skillforge.course.service.CourseService;
import com.skillforge.ai.dto.*;
import com.skillforge.ai.service.AiService;
import com.skillforge.ai.service.AiAdvancedService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
public class AiController {
    private final AiService aiService;
    private final CourseService courseService;
    private final AiAdvancedService aiAdvancedService;

    public AiController(AiService aiService, CourseService courseService, AiAdvancedService aiAdvancedService) {
        this.aiService = aiService;
        this.courseService = courseService;
        this.aiAdvancedService = aiAdvancedService;
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

    @PostMapping("/api/v1/ai/ats-resume-match")
    public ResponseEntity<ApiResponse<Object>> matchAtsResume(@RequestBody Map<String, String> body,
                                                              HttpServletRequest servletRequest) {
        String resume = body.getOrDefault("resumeText", "");
        String role = body.getOrDefault("targetRole", "Software Engineer");
        Object result = aiAdvancedService.matchAtsResume(resume, role);
        return ResponseEntity.ok(ApiResponse.success("ATS Resume analysis completed", result, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/ai/code-review")
    public ResponseEntity<ApiResponse<Object>> reviewCode(@RequestBody Map<String, String> body,
                                                          HttpServletRequest servletRequest) {
        String code = body.getOrDefault("code", "");
        String lang = body.getOrDefault("language", "javascript");
        Object result = aiAdvancedService.reviewCode(code, lang);
        return ResponseEntity.ok(ApiResponse.success("AI Code review generated", result, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/ai/generate-flashcards")
    public ResponseEntity<ApiResponse<Object>> generateFlashcards(@RequestBody Map<String, String> body,
                                                                  HttpServletRequest servletRequest) {
        String content = body.getOrDefault("content", "");
        Object result = aiAdvancedService.generateFlashcards(content);
        return ResponseEntity.ok(ApiResponse.success("AI Flashcards generated", result, servletRequest.getRequestURI()));
    }
}
