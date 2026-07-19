package com.skillforge.course.controller;

import com.skillforge.auth.entity.UserEntity;
import com.skillforge.auth.service.AuthorizationService;
import com.skillforge.common.api.ApiResponse;
import com.skillforge.course.dto.*;
import com.skillforge.course.service.CourseService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;

@RestController
public class CourseController {
    private final CourseService courseService;
    private final AuthorizationService authorizationService;

    public CourseController(CourseService courseService, AuthorizationService authorizationService) {
        this.courseService = courseService;
        this.authorizationService = authorizationService;
    }

    @PostMapping("/api/v1/categories")
    public ResponseEntity<ApiResponse<CategoryResponse>> createCategory(@Valid @RequestBody CreateCategoryRequest request,
                                                                        HttpServletRequest servletRequest,
                                                                        Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        authorizationService.assertPermission(currentUser, com.skillforge.auth.entity.Permission.MANAGE_COURSES);
        CategoryResponse response = courseService.createCategory(request);
        return ResponseEntity.ok(ApiResponse.success("Category created successfully", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/categories")
    public ResponseEntity<ApiResponse<List<CategoryResponse>>> listCategories(HttpServletRequest servletRequest) {
        List<CategoryResponse> response = courseService.listCategories();
        return ResponseEntity.ok(ApiResponse.success("Categories loaded", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/courses")
    public ResponseEntity<ApiResponse<CourseResponse>> createCourse(@Valid @RequestBody CreateCourseRequest request,
                                                                    HttpServletRequest servletRequest,
                                                                    Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        authorizationService.assertPermission(currentUser, com.skillforge.auth.entity.Permission.MANAGE_COURSES);
        CourseResponse response = courseService.createCourse(request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Course created successfully", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/courses/{courseId}")
    public ResponseEntity<ApiResponse<CourseResponse>> getCourseDetails(@PathVariable String courseId,
                                                                        HttpServletRequest servletRequest,
                                                                        Principal principal) {
        UserEntity currentUser = courseService.getOptionalUser(principal).orElse(null);
        CourseResponse response = courseService.getCourseDetails(courseId, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Course details loaded", response, servletRequest.getRequestURI()));
    }

    @PutMapping("/api/v1/courses/{courseId}")
    public ResponseEntity<ApiResponse<CourseResponse>> updateCourse(@PathVariable String courseId,
                                                                    @Valid @RequestBody CreateCourseRequest request,
                                                                    HttpServletRequest servletRequest,
                                                                    Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        authorizationService.assertPermission(currentUser, com.skillforge.auth.entity.Permission.MANAGE_COURSES);
        CourseResponse response = courseService.updateCourse(courseId, request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Course updated successfully", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/courses/{courseId}/sections")
    public ResponseEntity<ApiResponse<SectionResponse>> createSection(@PathVariable String courseId,
                                                                      @Valid @RequestBody CreateSectionRequest request,
                                                                      HttpServletRequest servletRequest,
                                                                      Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        authorizationService.assertPermission(currentUser, com.skillforge.auth.entity.Permission.MANAGE_COURSES);
        SectionResponse response = courseService.createSection(courseId, request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Section created successfully", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/courses/{courseId}/sections/{sectionId}/lessons")
    public ResponseEntity<ApiResponse<LessonResponse>> createLesson(@PathVariable String courseId,
                                                                    @PathVariable String sectionId,
                                                                    @Valid @RequestBody CreateLessonRequest request,
                                                                    HttpServletRequest servletRequest,
                                                                    Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        authorizationService.assertPermission(currentUser, com.skillforge.auth.entity.Permission.MANAGE_COURSES);
        LessonResponse response = courseService.createLesson(courseId, sectionId, request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Lesson created successfully", response, servletRequest.getRequestURI()));
    }

    @PutMapping("/api/v1/courses/{courseId}/sections/{sectionId}/lessons/{lessonId}")
    public ResponseEntity<ApiResponse<LessonResponse>> updateLesson(@PathVariable String courseId,
                                                                    @PathVariable String sectionId,
                                                                    @PathVariable String lessonId,
                                                                    @Valid @RequestBody CreateLessonRequest request,
                                                                    HttpServletRequest servletRequest,
                                                                    Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        authorizationService.assertPermission(currentUser, com.skillforge.auth.entity.Permission.MANAGE_COURSES);
        LessonResponse response = courseService.updateLesson(courseId, sectionId, lessonId, request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Lesson updated successfully", response, servletRequest.getRequestURI()));
    }

    @DeleteMapping("/api/v1/courses/{courseId}/sections/{sectionId}/lessons/{lessonId}")
    public ResponseEntity<ApiResponse<Void>> deleteLesson(@PathVariable String courseId,
                                                          @PathVariable String sectionId,
                                                          @PathVariable String lessonId,
                                                          HttpServletRequest servletRequest,
                                                          Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        authorizationService.assertPermission(currentUser, com.skillforge.auth.entity.Permission.MANAGE_COURSES);
        courseService.deleteLesson(courseId, sectionId, lessonId, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Lesson deleted successfully", null, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/courses/{courseId}/reviews")
    public ResponseEntity<ApiResponse<ReviewResponse>> addReview(@PathVariable String courseId,
                                                                 @Valid @RequestBody CreateReviewRequest request,
                                                                 HttpServletRequest servletRequest,
                                                                 Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        ReviewResponse response = courseService.addReview(courseId, request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Review submitted successfully", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/courses/{courseId}/reviews")
    public ResponseEntity<ApiResponse<List<ReviewResponse>>> getReviews(@PathVariable String courseId,
                                                                        HttpServletRequest servletRequest) {
        List<ReviewResponse> response = courseService.getReviews(courseId);
        return ResponseEntity.ok(ApiResponse.success("Reviews loaded", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/wishlist")
    public ResponseEntity<ApiResponse<Void>> addToWishlist(@Valid @RequestBody WishlistRequest request,
                                                           HttpServletRequest servletRequest,
                                                           Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        courseService.addToWishlist(request.courseId().toString(), currentUser);
        return ResponseEntity.ok(ApiResponse.success("Course added to wishlist", null, servletRequest.getRequestURI()));
    }

    @DeleteMapping("/api/v1/wishlist/{courseId}")
    public ResponseEntity<ApiResponse<Void>> removeFromWishlist(@PathVariable String courseId,
                                                                HttpServletRequest servletRequest,
                                                                Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        courseService.removeFromWishlist(courseId, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Course removed from wishlist", null, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/wishlist")
    public ResponseEntity<ApiResponse<List<CourseResponse>>> getWishlist(HttpServletRequest servletRequest,
                                                                         Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        List<CourseResponse> response = courseService.getWishlist(currentUser);
        return ResponseEntity.ok(ApiResponse.success("Wishlist loaded", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/courses")
    public ResponseEntity<ApiResponse<List<CourseResponse>>> listCourses(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String categorySlug,
            @RequestParam(required = false) String difficulty,
            @RequestParam(required = false) Double priceMin,
            @RequestParam(required = false) Double priceMax,
            @RequestParam(required = false) Double ratingMin,
            @RequestParam(required = false) String sortBy,
            HttpServletRequest servletRequest,
            Principal principal) {
        UserEntity currentUser = courseService.getOptionalUser(principal).orElse(null);
        CourseSearchRequest searchRequest = new CourseSearchRequest(keyword, categorySlug, difficulty, priceMin, priceMax, ratingMin, sortBy);
        List<CourseResponse> response = courseService.searchCourses(searchRequest, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Courses loaded", response, servletRequest.getRequestURI()));
    }
}
