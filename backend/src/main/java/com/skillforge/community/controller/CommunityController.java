package com.skillforge.community.controller;

import com.skillforge.auth.entity.UserEntity;
import com.skillforge.common.api.ApiResponse;
import com.skillforge.course.service.CourseService;
import com.skillforge.community.dto.*;
import com.skillforge.community.service.CommunityService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.UUID;

@RestController
public class CommunityController {
    private final CommunityService communityService;
    private final CourseService courseService;

    public CommunityController(CommunityService communityService, CourseService courseService) {
        this.communityService = communityService;
        this.courseService = courseService;
    }

    @PostMapping("/api/v1/forum/posts")
    public ResponseEntity<ApiResponse<ForumPostResponse>> createPost(@Valid @RequestBody CreatePostRequest request,
                                                                     HttpServletRequest servletRequest,
                                                                     Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        ForumPostResponse response = communityService.createPost(request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Forum post created successfully", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/forum/posts")
    public ResponseEntity<ApiResponse<List<ForumPostResponse>>> getPosts(@RequestParam(required = false) String courseId,
                                                                         HttpServletRequest servletRequest) {
        UUID cid = (courseId != null && !courseId.isBlank()) ? UUID.fromString(courseId) : null;
        List<ForumPostResponse> response = communityService.getPosts(cid);
        return ResponseEntity.ok(ApiResponse.success("Forum posts loaded", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/forum/posts/{postId}")
    public ResponseEntity<ApiResponse<ForumPostResponse>> getPostDetails(@PathVariable String postId,
                                                                         HttpServletRequest servletRequest) {
        ForumPostResponse response = communityService.getPostDetails(UUID.fromString(postId));
        return ResponseEntity.ok(ApiResponse.success("Forum post details loaded", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/forum/posts/{postId}/comments")
    public ResponseEntity<ApiResponse<ForumCommentResponse>> addComment(@PathVariable String postId,
                                                                        @Valid @RequestBody CreateCommentRequest request,
                                                                        HttpServletRequest servletRequest,
                                                                        Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        ForumCommentResponse response = communityService.addComment(UUID.fromString(postId), request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Comment added successfully", response, servletRequest.getRequestURI()));
    }

    @PutMapping("/api/v1/forum/comments/{commentId}/accept")
    public ResponseEntity<ApiResponse<ForumCommentResponse>> markAcceptedAnswer(@PathVariable String commentId,
                                                                                HttpServletRequest servletRequest,
                                                                                Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        ForumCommentResponse response = communityService.markAcceptedAnswer(UUID.fromString(commentId), currentUser);
        return ResponseEntity.ok(ApiResponse.success("Accepted answer marked successfully", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/announcements")
    public ResponseEntity<ApiResponse<AnnouncementResponse>> createAnnouncement(@Valid @RequestBody CreateAnnouncementRequest request,
                                                                                HttpServletRequest servletRequest,
                                                                                Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        AnnouncementResponse response = communityService.createAnnouncement(request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Announcement posted successfully", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/announcements")
    public ResponseEntity<ApiResponse<List<AnnouncementResponse>>> getAnnouncements(@RequestParam(required = false) String courseId,
                                                                                    HttpServletRequest servletRequest) {
        UUID cid = (courseId != null && !courseId.isBlank()) ? UUID.fromString(courseId) : null;
        List<AnnouncementResponse> response = communityService.getAnnouncements(cid);
        return ResponseEntity.ok(ApiResponse.success("Announcements loaded", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/groups")
    public ResponseEntity<ApiResponse<StudentGroupResponse>> createGroup(@Valid @RequestBody CreateGroupRequest request,
                                                                         HttpServletRequest servletRequest,
                                                                         Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        StudentGroupResponse response = communityService.createGroup(request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Student group created successfully", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/groups")
    public ResponseEntity<ApiResponse<List<StudentGroupResponse>>> getGroups(HttpServletRequest servletRequest) {
        List<StudentGroupResponse> response = communityService.getGroups();
        return ResponseEntity.ok(ApiResponse.success("Student groups loaded", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/groups/{groupId}/join")
    public ResponseEntity<ApiResponse<Void>> joinGroup(@PathVariable String groupId,
                                                       HttpServletRequest servletRequest,
                                                       Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        communityService.joinGroup(UUID.fromString(groupId), currentUser);
        return ResponseEntity.ok(ApiResponse.success("Joined group successfully", null, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/groups/{groupId}/leave")
    public ResponseEntity<ApiResponse<Void>> leaveGroup(@PathVariable String groupId,
                                                        HttpServletRequest servletRequest,
                                                        Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        communityService.leaveGroup(UUID.fromString(groupId), currentUser);
        return ResponseEntity.ok(ApiResponse.success("Left group successfully", null, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/leaderboard")
    public ResponseEntity<ApiResponse<List<LeaderboardResponse>>> getLeaderboard(HttpServletRequest servletRequest) {
        List<LeaderboardResponse> response = communityService.getLeaderboard();
        return ResponseEntity.ok(ApiResponse.success("XP Leaderboard loaded", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/achievements")
    public ResponseEntity<ApiResponse<List<AchievementResponse>>> getAchievements(HttpServletRequest servletRequest,
                                                                                  Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        List<AchievementResponse> response = communityService.getAchievements(currentUser);
        return ResponseEntity.ok(ApiResponse.success("User achievements loaded", response, servletRequest.getRequestURI()));
    }
}
