package com.skillforge.analytics.controller;

import com.skillforge.auth.entity.UserEntity;
import com.skillforge.common.api.ApiResponse;
import com.skillforge.course.service.CourseService;
import com.skillforge.analytics.dto.*;
import com.skillforge.analytics.service.AnalyticsService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.UUID;

@RestController
public class AnalyticsController {
    private final AnalyticsService analyticsService;
    private final CourseService courseService;

    public AnalyticsController(AnalyticsService analyticsService, CourseService courseService) {
        this.analyticsService = analyticsService;
        this.courseService = courseService;
    }

    @PostMapping("/api/v1/analytics/logs")
    public ResponseEntity<ApiResponse<Void>> logActivity(@Valid @RequestBody LogActivityRequest request,
                                                         HttpServletRequest servletRequest,
                                                         Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        analyticsService.logActivity(request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("User activity logged successfully", null, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/analytics/revenue")
    public ResponseEntity<ApiResponse<RevenueAnalyticsResponse>> getRevenueAnalytics(HttpServletRequest servletRequest) {
        RevenueAnalyticsResponse response = analyticsService.getRevenueAnalytics();
        return ResponseEntity.ok(ApiResponse.success("Platform revenue metrics loaded", response, servletRequest.getRequestURI()));
    }

    // Instructor-specific revenue report (used by web instructor dashboard)
    // Returns gross sales, instructor 70% share, platform 30% fee for the authenticated instructor
    @GetMapping("/api/v1/reports/instructor/revenue")
    public ResponseEntity<ApiResponse<InstructorRevenueResponse>> getInstructorRevenue(HttpServletRequest servletRequest,
                                                                                        Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        InstructorRevenueResponse response = analyticsService.getInstructorRevenue(currentUser);
        return ResponseEntity.ok(ApiResponse.success("Instructor revenue report loaded", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/analytics/students")
    public ResponseEntity<ApiResponse<StudentAnalyticsResponse>> getStudentAnalytics(HttpServletRequest servletRequest) {
        StudentAnalyticsResponse response = analyticsService.getStudentAnalytics();
        return ResponseEntity.ok(ApiResponse.success("Student cohort metrics loaded", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/analytics/courses/{courseId}")
    public ResponseEntity<ApiResponse<CoursePerformanceResponse>> getCoursePerformance(@PathVariable String courseId,
                                                                                        HttpServletRequest servletRequest) {
        CoursePerformanceResponse response = analyticsService.getCoursePerformance(UUID.fromString(courseId));
        return ResponseEntity.ok(ApiResponse.success("Course performance statistics loaded", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/analytics/kpis")
    public ResponseEntity<ApiResponse<PlatformKpisResponse>> getPlatformKpis(HttpServletRequest servletRequest) {
        PlatformKpisResponse response = analyticsService.getPlatformKpis();
        return ResponseEntity.ok(ApiResponse.success("Platform KPIs loaded", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/analytics/reports/export")
    public ResponseEntity<byte[]> exportSummaryCsv() {
        String csv = analyticsService.exportSummaryCsv();
        byte[] bytes = csv.getBytes();

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"platform_analytics_report.csv\"")
                .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                .body(bytes);
    }
}
