package com.skillforge.enterprise.controller;

import com.skillforge.auth.entity.UserEntity;
import com.skillforge.common.api.ApiResponse;
import com.skillforge.course.service.CourseService;
import com.skillforge.enterprise.dto.*;
import com.skillforge.enterprise.entity.SystemAuditLogEntity;
import com.skillforge.enterprise.service.EnterpriseService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;

@RestController
public class EnterpriseController {
    private final EnterpriseService enterpriseService;
    private final CourseService courseService;

    public EnterpriseController(EnterpriseService enterpriseService, CourseService courseService) {
        this.enterpriseService = enterpriseService;
        this.courseService = courseService;
    }

    @PostMapping("/api/v1/enterprise/audit-logs")
    public ResponseEntity<ApiResponse<Void>> logEvent(@Valid @RequestBody LogSystemEventRequest request,
                                                      HttpServletRequest servletRequest,
                                                      Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        String ip = servletRequest.getRemoteAddr();
        enterpriseService.logEvent(request, currentUser, ip);
        return ResponseEntity.ok(ApiResponse.success("System event logged", null, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/enterprise/audit-logs")
    public ResponseEntity<ApiResponse<List<SystemAuditLogEntity>>> getAuditLogs(@RequestParam(required = false) String severity,
                                                                                HttpServletRequest servletRequest) {
        List<SystemAuditLogEntity> response = enterpriseService.getAuditLogs(severity);
        return ResponseEntity.ok(ApiResponse.success("System audit logs loaded", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/enterprise/health")
    public ResponseEntity<ApiResponse<HealthCheckResponse>> performHealthCheck(HttpServletRequest servletRequest) {
        HealthCheckResponse response = enterpriseService.performHealthCheck();
        return ResponseEntity.ok(ApiResponse.success("Platform health check completed", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/enterprise/metrics")
    public ResponseEntity<ApiResponse<SystemMetricsResponse>> getSystemMetrics(HttpServletRequest servletRequest) {
        SystemMetricsResponse response = enterpriseService.getSystemMetrics();
        return ResponseEntity.ok(ApiResponse.success("JVM metrics loaded", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/enterprise/cdn/resolve")
    public ResponseEntity<ApiResponse<CdnResolveResponse>> resolveCdnUrl(@Valid @RequestBody CdnResolveRequest request,
                                                                         HttpServletRequest servletRequest,
                                                                         Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        CdnResolveResponse response = enterpriseService.resolveCdnUrl(request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("CDN resource URL resolved", response, servletRequest.getRequestURI()));
    }
}
