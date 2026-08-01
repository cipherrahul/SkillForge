package com.skillforge.assessment.controller;

import com.skillforge.auth.entity.UserEntity;
import com.skillforge.common.api.ApiResponse;
import com.skillforge.course.service.CourseService;
import com.skillforge.assessment.dto.*;
import com.skillforge.assessment.service.AssessmentService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.UUID;

@RestController
public class AssessmentController {
    private final AssessmentService assessmentService;
    private final CourseService courseService;

    public AssessmentController(AssessmentService assessmentService, CourseService courseService) {
        this.assessmentService = assessmentService;
        this.courseService = courseService;
    }

    @PostMapping("/api/v1/courses/{courseId}/assessments")
    public ResponseEntity<ApiResponse<AssessmentResponse>> createAssessment(@PathVariable String courseId,
                                                                            @Valid @RequestBody CreateAssessmentRequest request,
                                                                            HttpServletRequest servletRequest,
                                                                            Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        AssessmentResponse response = assessmentService.createAssessment(UUID.fromString(courseId), request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Assessment created successfully", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/courses/{courseId}/assessments")
    public ResponseEntity<ApiResponse<List<AssessmentResponse>>> getAssessments(@PathVariable String courseId,
                                                                                HttpServletRequest servletRequest) {
        List<AssessmentResponse> response = assessmentService.getAssessments(UUID.fromString(courseId));
        return ResponseEntity.ok(ApiResponse.success("Assessments loaded", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/assessments/{assessmentId}/submissions")
    public ResponseEntity<ApiResponse<SubmissionResponse>> submitAssessment(@PathVariable String assessmentId,
                                                                            @Valid @RequestBody SubmissionRequest request,
                                                                            HttpServletRequest servletRequest,
                                                                            Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        SubmissionResponse response = assessmentService.submit(UUID.fromString(assessmentId), request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Assessment submitted successfully", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/assessments/{assessmentId}/submissions")
    public ResponseEntity<ApiResponse<List<SubmissionResponse>>> getSubmissions(@PathVariable String assessmentId,
                                                                                HttpServletRequest servletRequest,
                                                                                Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        List<SubmissionResponse> response = assessmentService.getSubmissions(UUID.fromString(assessmentId), currentUser);
        return ResponseEntity.ok(ApiResponse.success("Submissions loaded", response, servletRequest.getRequestURI()));
    }

    @PutMapping({"/api/v1/submissions/{submissionId}/grade", "/api/v1/assessments/{assessmentId}/submissions/{submissionId}/grade"})
    public ResponseEntity<ApiResponse<SubmissionResponse>> gradeSubmission(@PathVariable String submissionId,
                                                                           @Valid @RequestBody GradeSubmissionRequest request,
                                                                           HttpServletRequest servletRequest,
                                                                           Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        SubmissionResponse response = assessmentService.grade(UUID.fromString(submissionId), request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Submission graded successfully", response, servletRequest.getRequestURI()));
    }
}

