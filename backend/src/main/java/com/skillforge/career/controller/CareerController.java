package com.skillforge.career.controller;

import com.skillforge.auth.entity.UserEntity;
import com.skillforge.common.api.ApiResponse;
import com.skillforge.course.service.CourseService;
import com.skillforge.career.dto.*;
import com.skillforge.career.service.CareerService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.UUID;

@RestController
public class CareerController {
    private final CareerService careerService;
    private final CourseService courseService;

    public CareerController(CareerService careerService, CourseService courseService) {
        this.careerService = careerService;
        this.courseService = courseService;
    }

    @PostMapping("/api/v1/jobs")
    public ResponseEntity<ApiResponse<JobResponse>> createJob(@Valid @RequestBody CreateJobRequest request,
                                                              HttpServletRequest servletRequest,
                                                              Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        JobResponse response = careerService.createJob(request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Job listing created successfully", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/jobs")
    public ResponseEntity<ApiResponse<List<JobResponse>>> getJobs(@RequestParam(required = false) String type,
                                                                  HttpServletRequest servletRequest) {
        List<JobResponse> response = careerService.getJobs(type);
        return ResponseEntity.ok(ApiResponse.success("Job listings loaded", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/jobs/{jobId}")
    public ResponseEntity<ApiResponse<JobResponse>> getJobDetails(@PathVariable String jobId,
                                                                  HttpServletRequest servletRequest) {
        JobResponse response = careerService.getJobDetails(UUID.fromString(jobId));
        return ResponseEntity.ok(ApiResponse.success("Job details loaded", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/jobs/{jobId}/apply")
    public ResponseEntity<ApiResponse<ApplicationResponse>> applyJob(@PathVariable String jobId,
                                                                     @RequestBody ApplyJobRequest request,
                                                                     HttpServletRequest servletRequest,
                                                                     Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        ApplicationResponse response = careerService.applyJob(UUID.fromString(jobId), request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Job application submitted", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/jobs/applications")
    public ResponseEntity<ApiResponse<List<ApplicationResponse>>> getApplications(@RequestParam(required = false) String studentEmail,
                                                                                  @RequestParam(required = false) String jobId,
                                                                                  HttpServletRequest servletRequest) {
        UUID jid = (jobId != null && !jobId.isBlank()) ? UUID.fromString(jobId) : null;
        List<ApplicationResponse> response = careerService.getApplications(studentEmail, jid);
        return ResponseEntity.ok(ApiResponse.success("Applications loaded", response, servletRequest.getRequestURI()));
    }

    @PutMapping("/api/v1/jobs/applications/{applicationId}/status")
    public ResponseEntity<ApiResponse<ApplicationResponse>> updateApplicationStatus(@PathVariable String applicationId,
                                                                                    @RequestParam String status,
                                                                                    HttpServletRequest servletRequest,
                                                                                    Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        ApplicationResponse response = careerService.updateApplicationStatus(UUID.fromString(applicationId), status, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Application status updated", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/resumes")
    public ResponseEntity<ApiResponse<String>> buildResume(@Valid @RequestBody BuildResumeRequest request,
                                                           HttpServletRequest servletRequest,
                                                           Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        String pdfUrl = careerService.buildResume(request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Resume built successfully", pdfUrl, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/mock-interviews")
    public ResponseEntity<ApiResponse<MockInterviewResponse>> bookMockInterview(@Valid @RequestBody BookInterviewRequest request,
                                                                                HttpServletRequest servletRequest,
                                                                                Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        MockInterviewResponse response = careerService.bookMockInterview(request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Mock interview scheduled successfully", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/mock-interviews/{interviewId}/feedback")
    public ResponseEntity<ApiResponse<MockInterviewResponse>> submitInterviewFeedback(@PathVariable String interviewId,
                                                                                      @Valid @RequestBody SubmitFeedbackRequest request,
                                                                                      HttpServletRequest servletRequest,
                                                                                      Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        MockInterviewResponse response = careerService.submitInterviewFeedback(UUID.fromString(interviewId), request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Interview graded successfully", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/career/analytics")
    public ResponseEntity<ApiResponse<PlacementAnalyticsResponse>> getAnalytics(HttpServletRequest servletRequest) {
        PlacementAnalyticsResponse response = careerService.getAnalytics();
        return ResponseEntity.ok(ApiResponse.success("Placement analytics loaded", response, servletRequest.getRequestURI()));
    }
}
