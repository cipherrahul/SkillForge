package com.skillforge.mobile.controller;

import com.skillforge.auth.entity.UserEntity;
import com.skillforge.common.api.ApiResponse;
import com.skillforge.course.service.CourseService;
import com.skillforge.mobile.dto.*;
import com.skillforge.mobile.entity.MobileNotificationEntity;
import com.skillforge.mobile.service.MobileService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.UUID;

@RestController
public class MobileController {
    private final MobileService mobileService;
    private final CourseService courseService;

    public MobileController(MobileService mobileService, CourseService courseService) {
        this.mobileService = mobileService;
        this.courseService = courseService;
    }

    @PostMapping("/api/v1/mobile/devices")
    public ResponseEntity<ApiResponse<Void>> registerDevice(@Valid @RequestBody RegisterDeviceRequest request,
                                                            HttpServletRequest servletRequest,
                                                            Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        mobileService.registerDevice(request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Device registered successfully", null, servletRequest.getRequestURI()));
    }

    @DeleteMapping("/api/v1/mobile/devices/{deviceToken}")
    public ResponseEntity<ApiResponse<Void>> deregisterDevice(@PathVariable String deviceToken,
                                                              HttpServletRequest servletRequest,
                                                              Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        mobileService.deregisterDevice(deviceToken, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Device deregistered successfully", null, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/mobile/student/dashboard")
    public ResponseEntity<ApiResponse<StudentMobileDashboard>> getStudentDashboard(HttpServletRequest servletRequest,
                                                                                   Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        StudentMobileDashboard response = mobileService.getStudentDashboard(currentUser);
        return ResponseEntity.ok(ApiResponse.success("Student mobile dashboard loaded", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/mobile/instructor/dashboard")
    public ResponseEntity<ApiResponse<InstructorMobileDashboard>> getInstructorDashboard(HttpServletRequest servletRequest,
                                                                                         Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        InstructorMobileDashboard response = mobileService.getInstructorDashboard(currentUser);
        return ResponseEntity.ok(ApiResponse.success("Instructor mobile dashboard loaded", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/mobile/courses/{courseId}/offline-manifest")
    public ResponseEntity<ApiResponse<OfflineManifestResponse>> getOfflineManifest(@PathVariable String courseId,
                                                                                   HttpServletRequest servletRequest) {
        OfflineManifestResponse response = mobileService.getOfflineManifest(UUID.fromString(courseId));
        return ResponseEntity.ok(ApiResponse.success("Offline package manifest loaded", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/mobile/notifications/test")
    public ResponseEntity<ApiResponse<Void>> sendPushNotification(@Valid @RequestBody SendTestPushRequest request,
                                                                  HttpServletRequest servletRequest,
                                                                  Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        mobileService.sendPushNotification(request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Mock notification dispatched successfully", null, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/mobile/notifications")
    public ResponseEntity<ApiResponse<List<MobileNotificationEntity>>> getNotificationsHistory(HttpServletRequest servletRequest,
                                                                                               Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        List<MobileNotificationEntity> response = mobileService.getNotificationsHistory(currentUser.getEmail());
        return ResponseEntity.ok(ApiResponse.success("Notifications logs history loaded", response, servletRequest.getRequestURI()));
    }
}
