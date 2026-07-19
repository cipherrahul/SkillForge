package com.skillforge.community.service;

import com.skillforge.auth.entity.UserEntity;
import com.skillforge.auth.repository.UserRepository;
import com.skillforge.common.exception.BadRequestException;
import com.skillforge.common.exception.ResourceNotFoundException;
import com.skillforge.common.exception.UnauthorizedException;
import com.skillforge.course.entity.CourseEntity;
import com.skillforge.course.repository.CourseRepository;
import com.skillforge.community.dto.*;
import com.skillforge.community.entity.*;
import com.skillforge.community.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;

@Service
public class CommunityService {
    private final ForumPostRepository forumPostRepository;
    private final ForumCommentRepository forumCommentRepository;
    private final AnnouncementRepository announcementRepository;
    private final StudentGroupRepository studentGroupRepository;
    private final GroupMemberRepository groupMemberRepository;
    private final UserStatsRepository userStatsRepository;
    private final AchievementRepository achievementRepository;
    private final CourseRepository courseRepository;
    private final UserRepository userRepository;

    public CommunityService(ForumPostRepository forumPostRepository,
                            ForumCommentRepository forumCommentRepository,
                            AnnouncementRepository announcementRepository,
                            StudentGroupRepository studentGroupRepository,
                            GroupMemberRepository groupMemberRepository,
                            UserStatsRepository userStatsRepository,
                            AchievementRepository achievementRepository,
                            CourseRepository courseRepository,
                            UserRepository userRepository) {
        this.forumPostRepository = forumPostRepository;
        this.forumCommentRepository = forumCommentRepository;
        this.announcementRepository = announcementRepository;
        this.studentGroupRepository = studentGroupRepository;
        this.groupMemberRepository = groupMemberRepository;
        this.userStatsRepository = userStatsRepository;
        this.achievementRepository = achievementRepository;
        this.courseRepository = courseRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public ForumPostResponse createPost(CreatePostRequest request, UserEntity currentUser) {
        if (request.courseId() != null) {
            courseRepository.findById(request.courseId())
                    .orElseThrow(() -> new ResourceNotFoundException("Course not found"));
        }

        ForumPostEntity post = new ForumPostEntity();
        post.setCourseId(request.courseId());
        post.setUserEmail(currentUser.getEmail());
        post.setUserFullName(currentUser.getFullName());
        post.setTitle(request.title().trim());
        post.setContent(request.content().trim());
        post.setQuestion(request.isQuestion());
        post.setCategory(request.category() != null ? request.category().toUpperCase().trim() : "GENERAL");
        post.setCreatedBy(currentUser.getEmail());
        post.setUpdatedBy(currentUser.getEmail());

        ForumPostEntity saved = forumPostRepository.save(post);

        // Gamification
        addXpPoints(currentUser.getEmail(), 15, currentUser);
        unlockAchievement(currentUser.getEmail(), "First Discussion", "Created your first discussion post on the forum", "BRONZE", currentUser);

        return mapPost(saved);
    }

    @Transactional
    public ForumCommentResponse addComment(UUID postId, CreateCommentRequest request, UserEntity currentUser) {
        ForumPostEntity post = forumPostRepository.findById(postId)
                .orElseThrow(() -> new ResourceNotFoundException("Post not found"));

        ForumCommentEntity comment = new ForumCommentEntity();
        comment.setPostId(postId);
        comment.setUserEmail(currentUser.getEmail());
        comment.setUserFullName(currentUser.getFullName());
        comment.setContent(request.content().trim());
        comment.setCreatedBy(currentUser.getEmail());
        comment.setUpdatedBy(currentUser.getEmail());

        ForumCommentEntity saved = forumCommentRepository.save(comment);

        // Gamification
        addXpPoints(currentUser.getEmail(), 5, currentUser);

        return mapComment(saved);
    }

    @Transactional
    public ForumCommentResponse markAcceptedAnswer(UUID commentId, UserEntity currentUser) {
        ForumCommentEntity comment = forumCommentRepository.findById(commentId)
                .orElseThrow(() -> new ResourceNotFoundException("Comment not found"));

        ForumPostEntity post = forumPostRepository.findById(comment.getPostId())
                .orElseThrow(() -> new ResourceNotFoundException("Associated post not found"));

        if (!post.isQuestion()) {
            throw new BadRequestException("This forum post is not a question");
        }

        // Must be the creator of the post or course instructor/admin to mark the answer
        boolean isOwner = post.getUserEmail().equalsIgnoreCase(currentUser.getEmail());
        boolean isInstructor = false;
        if (post.getCourseId() != null) {
            CourseEntity course = courseRepository.findById(post.getCourseId()).orElse(null);
            if (course != null && course.getInstructorEmail().equalsIgnoreCase(currentUser.getEmail())) {
                isInstructor = true;
            }
        }

        if (!isOwner && !isInstructor) {
            throw new UnauthorizedException("Only the post creator or course instructor can mark the correct answer");
        }

        comment.setAnswer(true);
        comment.setUpdatedAt(Instant.now());
        comment.setUpdatedBy(currentUser.getEmail());
        forumCommentRepository.save(comment);

        post.setResolved(true);
        post.setUpdatedAt(Instant.now());
        post.setUpdatedBy(currentUser.getEmail());
        forumPostRepository.save(post);

        // Gamification: Reward the answer helper
        UserEntity helper = userRepository.findByEmail(comment.getUserEmail()).orElse(null);
        if (helper != null) {
            addXpPoints(helper.getEmail(), 30, helper);
            unlockAchievement(helper.getEmail(), "Solution Expert", "Helped resolve a student Q&A thread", "SILVER", helper);
        }

        return mapComment(comment);
    }

    public List<ForumPostResponse> getPosts(UUID courseId) {
        List<ForumPostEntity> posts = (courseId != null)
                ? forumPostRepository.findByCourseId(courseId)
                : forumPostRepository.findByCourseIdIsNull();

        return posts.stream()
                .filter(p -> !p.isDeleted())
                .map(this::mapPost)
                .toList();
    }

    public ForumPostResponse getPostDetails(UUID postId) {
        ForumPostEntity post = forumPostRepository.findById(postId)
                .orElseThrow(() -> new ResourceNotFoundException("Post not found"));

        return mapPost(post);
    }

    @Transactional
    public AnnouncementResponse createAnnouncement(CreateAnnouncementRequest request, UserEntity currentUser) {
        if (request.courseId() != null) {
            CourseEntity course = courseRepository.findById(request.courseId())
                    .orElseThrow(() -> new ResourceNotFoundException("Course not found"));

            if (!course.getInstructorEmail().equalsIgnoreCase(currentUser.getEmail())) {
                throw new UnauthorizedException("Only the course instructor can create course announcements");
            }
        }

        AnnouncementEntity announcement = new AnnouncementEntity();
        announcement.setCourseId(request.courseId());
        announcement.setInstructorEmail(currentUser.getEmail());
        announcement.setTitle(request.title().trim());
        announcement.setContent(request.content().trim());
        announcement.setCreatedBy(currentUser.getEmail());
        announcement.setUpdatedBy(currentUser.getEmail());

        AnnouncementEntity saved = announcementRepository.save(announcement);
        return mapAnnouncement(saved);
    }

    public List<AnnouncementResponse> getAnnouncements(UUID courseId) {
        List<AnnouncementEntity> announcements = (courseId != null)
                ? announcementRepository.findByCourseId(courseId)
                : announcementRepository.findByCourseIdIsNull();

        return announcements.stream()
                .filter(a -> !a.isDeleted())
                .map(this::mapAnnouncement)
                .toList();
    }

    @Transactional
    public StudentGroupResponse createGroup(CreateGroupRequest request, UserEntity currentUser) {
        if (studentGroupRepository.findByNameIgnoreCase(request.name().trim()).isPresent()) {
            throw new BadRequestException("Group with this name already exists");
        }

        StudentGroupEntity group = new StudentGroupEntity();
        group.setName(request.name().trim());
        group.setDescription(request.description());
        group.setMemberCount(0);
        group.setCreatedBy(currentUser.getEmail());
        group.setUpdatedBy(currentUser.getEmail());

        StudentGroupEntity saved = studentGroupRepository.save(group);
        return mapGroup(saved);
    }

    public List<StudentGroupResponse> getGroups() {
        return studentGroupRepository.findAll().stream()
                .filter(g -> !g.isDeleted())
                .map(this::mapGroup)
                .toList();
    }

    @Transactional
    public void joinGroup(UUID groupId, UserEntity currentUser) {
        StudentGroupEntity group = studentGroupRepository.findById(groupId)
                .orElseThrow(() -> new ResourceNotFoundException("Group not found"));

        if (groupMemberRepository.findByGroupIdAndUserEmail(groupId, currentUser.getEmail()).isPresent()) {
            return; // Already in group
        }

        GroupMemberEntity member = new GroupMemberEntity();
        member.setGroupId(groupId);
        member.setUserEmail(currentUser.getEmail());
        member.setCreatedBy(currentUser.getEmail());
        member.setUpdatedBy(currentUser.getEmail());
        groupMemberRepository.save(member);

        group.setMemberCount(group.getMemberCount() + 1);
        group.setUpdatedAt(Instant.now());
        studentGroupRepository.save(group);
    }

    @Transactional
    public void leaveGroup(UUID groupId, UserEntity currentUser) {
        StudentGroupEntity group = studentGroupRepository.findById(groupId)
                .orElseThrow(() -> new ResourceNotFoundException("Group not found"));

        GroupMemberEntity member = groupMemberRepository.findByGroupIdAndUserEmail(groupId, currentUser.getEmail())
                .orElseThrow(() -> new BadRequestException("You are not a member of this group"));

        groupMemberRepository.delete(member);

        group.setMemberCount(Math.max(0, group.getMemberCount() - 1));
        group.setUpdatedAt(Instant.now());
        studentGroupRepository.save(group);
    }

    @Transactional
    public void addXpPoints(String email, int points, UserEntity currentUser) {
        UserStatsEntity stats = userStatsRepository.findByUserEmail(email)
                .orElseGet(() -> {
                    UserStatsEntity s = new UserStatsEntity();
                    s.setUserEmail(email);
                    s.setCreatedBy(email);
                    return s;
                });

        stats.setXpPoints(stats.getXpPoints() + points);
        stats.setUpdatedAt(Instant.now());
        stats.setUpdatedBy(email);
        userStatsRepository.save(stats);

        // Milestones
        if (stats.getXpPoints() >= 50) {
            unlockAchievement(email, "XP Beginner", "Accumulated over 50 XP points", "BRONZE", currentUser);
        }
        if (stats.getXpPoints() >= 100) {
            unlockAchievement(email, "XP Achiever", "Accumulated over 100 XP points", "SILVER", currentUser);
        }
        if (stats.getXpPoints() >= 500) {
            unlockAchievement(email, "XP Master", "Accumulated over 500 XP points", "GOLD", currentUser);
        }
    }

    @Transactional
    public void unlockAchievement(String email, String title, String description, String badgeType, UserEntity currentUser) {
        if (achievementRepository.existsByUserEmailAndTitle(email, title)) {
            return;
        }

        AchievementEntity achievement = new AchievementEntity();
        achievement.setUserEmail(email);
        achievement.setTitle(title);
        achievement.setDescription(description);
        achievement.setBadgeType(badgeType);
        achievement.setCreatedBy(email);
        achievement.setUpdatedBy(email);
        achievementRepository.save(achievement);
    }

    public List<LeaderboardResponse> getLeaderboard() {
        List<UserStatsEntity> statsList = userStatsRepository.findAllByOrderByXpPointsDesc();
        List<LeaderboardResponse> responses = new ArrayList<>();
        int currentRank = 1;
        for (UserStatsEntity s : statsList) {
            if (s.isDeleted()) continue;
            UserEntity user = userRepository.findByEmail(s.getUserEmail()).orElse(null);
            String name = user != null ? user.getFullName() : "Anonymous Student";
            responses.add(new LeaderboardResponse(
                    s.getId(),
                    s.getUserEmail(),
                    name,
                    s.getXpPoints(),
                    currentRank++
            ));
        }
        return responses;
    }

    public List<AchievementResponse> getAchievements(UserEntity currentUser) {
        return achievementRepository.findByUserEmail(currentUser.getEmail()).stream()
                .filter(a -> !a.isDeleted())
                .map(a -> new AchievementResponse(
                        a.getId(),
                        a.getUserEmail(),
                        a.getTitle(),
                        a.getDescription(),
                        a.getBadgeType(),
                        a.getCreatedAt()
                ))
                .toList();
    }

    private ForumPostResponse mapPost(ForumPostEntity post) {
        List<ForumCommentResponse> comments = forumCommentRepository.findByPostIdOrderByCreatedAtAsc(post.getId()).stream()
                .filter(c -> !c.isDeleted())
                .map(this::mapComment)
                .toList();

        return new ForumPostResponse(
                post.getId(),
                post.getCourseId(),
                post.getUserEmail(),
                post.getUserFullName(),
                post.getTitle(),
                post.getContent(),
                post.isQuestion(),
                post.isResolved(),
                post.getCategory(),
                post.getCreatedAt(),
                comments
        );
    }

    private ForumCommentResponse mapComment(ForumCommentEntity comment) {
        return new ForumCommentResponse(
                comment.getId(),
                comment.getPostId(),
                comment.getUserEmail(),
                comment.getUserFullName(),
                comment.getContent(),
                comment.isAnswer(),
                comment.getCreatedAt()
        );
    }

    private AnnouncementResponse mapAnnouncement(AnnouncementEntity a) {
        return new AnnouncementResponse(
                a.getId(),
                a.getCourseId(),
                a.getInstructorEmail(),
                a.getTitle(),
                a.getContent(),
                a.getCreatedAt()
        );
    }

    private StudentGroupResponse mapGroup(StudentGroupEntity g) {
        return new StudentGroupResponse(
                g.getId(),
                g.getName(),
                g.getDescription(),
                g.getMemberCount(),
                g.getCreatedAt()
        );
    }
}
