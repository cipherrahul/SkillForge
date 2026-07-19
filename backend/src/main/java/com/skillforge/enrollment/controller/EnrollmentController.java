package com.skillforge.enrollment.controller;

import com.skillforge.auth.entity.UserEntity;
import com.skillforge.common.api.ApiResponse;
import com.skillforge.course.service.CourseService;
import com.skillforge.enrollment.dto.EnrollRequest;
import com.skillforge.enrollment.dto.EnrollmentResponse;
import com.skillforge.enrollment.dto.UpdateProgressRequest;
import com.skillforge.enrollment.service.EnrollmentService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.UUID;

@RestController
public class EnrollmentController {
    private final EnrollmentService enrollmentService;
    private final CourseService courseService;

    public EnrollmentController(EnrollmentService enrollmentService, CourseService courseService) {
        this.enrollmentService = enrollmentService;
        this.courseService = courseService;
    }

    @PostMapping("/api/v1/enrollments")
    public ResponseEntity<ApiResponse<EnrollmentResponse>> enroll(@Valid @RequestBody EnrollRequest request,
                                                                  HttpServletRequest servletRequest,
                                                                  Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        EnrollmentResponse response = enrollmentService.enroll(request.courseId(), currentUser);
        return ResponseEntity.ok(ApiResponse.success("Enrolled in course successfully", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/enrollments")
    public ResponseEntity<ApiResponse<List<EnrollmentResponse>>> listEnrollments(HttpServletRequest servletRequest,
                                                                                 Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        List<EnrollmentResponse> response = enrollmentService.getEnrollments(currentUser);
        return ResponseEntity.ok(ApiResponse.success("Enrollments loaded", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/enrollments/{enrollmentId}/lessons/{lessonId}/progress")
    public ResponseEntity<ApiResponse<Void>> updateProgress(@PathVariable String enrollmentId,
                                                            @PathVariable String lessonId,
                                                            @Valid @RequestBody UpdateProgressRequest request,
                                                            HttpServletRequest servletRequest,
                                                            Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        enrollmentService.updateLessonProgress(
                UUID.fromString(enrollmentId),
                UUID.fromString(lessonId),
                request,
                currentUser
        );
        return ResponseEntity.ok(ApiResponse.success("Lesson progress updated successfully", null, servletRequest.getRequestURI()));
    }
}
