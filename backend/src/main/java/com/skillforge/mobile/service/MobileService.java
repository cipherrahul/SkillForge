package com.skillforge.mobile.service;

import com.skillforge.auth.entity.UserEntity;
import com.skillforge.common.exception.BadRequestException;
import com.skillforge.common.exception.ResourceNotFoundException;
import com.skillforge.course.entity.CourseEntity;
import com.skillforge.course.entity.LessonEntity;
import com.skillforge.course.repository.CourseRepository;
import com.skillforge.enrollment.entity.EnrollmentEntity;
import com.skillforge.enrollment.repository.EnrollmentRepository;
import com.skillforge.liveclass.entity.LiveSessionEntity;
import com.skillforge.liveclass.repository.LiveSessionRepository;
import com.skillforge.assessment.entity.AssessmentEntity;
import com.skillforge.assessment.entity.SubmissionEntity;
import com.skillforge.assessment.repository.AssessmentRepository;
import com.skillforge.assessment.repository.SubmissionRepository;
import com.skillforge.community.entity.UserStatsEntity;
import com.skillforge.community.repository.UserStatsRepository;
import com.skillforge.payment.entity.InstructorRevenueEntity;
import com.skillforge.payment.repository.InstructorRevenueRepository;
import com.skillforge.mobile.dto.*;
import com.skillforge.mobile.entity.*;
import com.skillforge.mobile.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;

@Service
public class MobileService {
    private final MobileDeviceRepository mobileDeviceRepository;
    private final MobileNotificationRepository mobileNotificationRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final CourseRepository courseRepository;
    private final LiveSessionRepository liveSessionRepository;
    private final UserStatsRepository userStatsRepository;
    private final AssessmentRepository assessmentRepository;
    private final SubmissionRepository submissionRepository;
    private final InstructorRevenueRepository instructorRevenueRepository;

    public MobileService(MobileDeviceRepository mobileDeviceRepository,
                         MobileNotificationRepository mobileNotificationRepository,
                         EnrollmentRepository enrollmentRepository,
                         CourseRepository courseRepository,
                         LiveSessionRepository liveSessionRepository,
                         UserStatsRepository userStatsRepository,
                         AssessmentRepository assessmentRepository,
                         SubmissionRepository submissionRepository,
                         InstructorRevenueRepository instructorRevenueRepository) {
        this.mobileDeviceRepository = mobileDeviceRepository;
        this.mobileNotificationRepository = mobileNotificationRepository;
        this.enrollmentRepository = enrollmentRepository;
        this.courseRepository = courseRepository;
        this.liveSessionRepository = liveSessionRepository;
        this.userStatsRepository = userStatsRepository;
        this.assessmentRepository = assessmentRepository;
        this.submissionRepository = submissionRepository;
        this.instructorRevenueRepository = instructorRevenueRepository;
    }

    @Transactional
    public void registerDevice(RegisterDeviceRequest request, UserEntity currentUser) {
        Optional<MobileDeviceEntity> existing = mobileDeviceRepository.findByDeviceToken(request.deviceToken().trim());
        if (existing.isPresent()) {
            MobileDeviceEntity device = existing.get();
            device.setActive(true);
            device.setUserEmail(currentUser.getEmail());
            device.setUpdatedAt(Instant.now());
            mobileDeviceRepository.save(device);
        } else {
            MobileDeviceEntity device = new MobileDeviceEntity();
            device.setUserEmail(currentUser.getEmail());
            device.setDeviceToken(request.deviceToken().trim());
            device.setOsPlatform(request.osPlatform().toUpperCase().trim());
            device.setActive(true);
            device.setCreatedBy(currentUser.getEmail());
            device.setUpdatedBy(currentUser.getEmail());
            mobileDeviceRepository.save(device);
        }
    }

    @Transactional
    public void deregisterDevice(String deviceToken, UserEntity currentUser) {
        MobileDeviceEntity device = mobileDeviceRepository.findByDeviceToken(deviceToken.trim())
                .orElseThrow(() -> new ResourceNotFoundException("Device token not found"));

        if (!device.getUserEmail().equalsIgnoreCase(currentUser.getEmail())) {
            throw new BadRequestException("Access denied");
        }

        device.setActive(false);
        device.setUpdatedAt(Instant.now());
        mobileDeviceRepository.save(device);
    }

    public StudentMobileDashboard getStudentDashboard(UserEntity currentUser) {
        List<EnrollmentEntity> enrollments = enrollmentRepository.findByUserEmail(currentUser.getEmail()).stream()
                .filter(e -> !e.isDeleted())
                .toList();

        List<String> enrolledTitles = new ArrayList<>();
        List<UUID> courseIds = new ArrayList<>();
        for (EnrollmentEntity e : enrollments) {
            courseRepository.findById(e.getCourseId()).ifPresent(c -> {
                enrolledTitles.add(c.getTitle());
                courseIds.add(c.getId());
            });
        }

        // Upcoming Live class from enrolled courses
        LiveSessionEntity nextLive = null;
        if (!courseIds.isEmpty()) {
            nextLive = liveSessionRepository.findByCourseIdIn(courseIds).stream()
                    .filter(s -> !s.isDeleted() && s.getStartTime().isAfter(Instant.now()))
                    .min(Comparator.comparing(LiveSessionEntity::getStartTime))
                    .orElse(null);
        }

        long unreadNotifications = mobileNotificationRepository.findByUserEmail(currentUser.getEmail()).stream()
                .filter(n -> !n.isDeleted())
                .count();

        int xp = userStatsRepository.findByUserEmail(currentUser.getEmail())
                .map(UserStatsEntity::getXpPoints)
                .orElse(0);

        return new StudentMobileDashboard(
                enrolledTitles,
                nextLive != null ? nextLive.getTitle() : null,
                nextLive != null ? nextLive.getStartTime() : null,
                unreadNotifications,
                xp
        );
    }

    public InstructorMobileDashboard getInstructorDashboard(UserEntity currentUser) {
        List<CourseEntity> courses = courseRepository.findByInstructorEmail(currentUser.getEmail()).stream()
                .filter(c -> !c.isDeleted())
                .toList();

        long totalCourses = courses.size();
        List<UUID> courseIds = courses.stream().map(CourseEntity::getId).toList();

        long activeStudents = 0;
        long pendingAssessments = 0;

        if (!courseIds.isEmpty()) {
            activeStudents = enrollmentRepository.findAll().stream()
                    .filter(e -> !e.isDeleted() && courseIds.contains(e.getCourseId()))
                    .count();

            List<AssessmentEntity> assessments = assessmentRepository.findAll().stream()
                    .filter(a -> !a.isDeleted() && courseIds.contains(a.getCourseId()))
                    .toList();

            for (AssessmentEntity a : assessments) {
                pendingAssessments += submissionRepository.findByAssessmentId(a.getId()).stream()
                        .filter(s -> !s.isDeleted() && !s.isGraded()) // Un-graded submissions
                        .count();
            }
        }

        double totalEarned = instructorRevenueRepository.findByInstructorEmail(currentUser.getEmail()).stream()
                .filter(r -> !r.isDeleted())
                .mapToDouble(InstructorRevenueEntity::getInstructorShare)
                .sum();

        return new InstructorMobileDashboard(
                totalCourses,
                activeStudents,
                pendingAssessments,
                totalEarned
        );
    }

    public OfflineManifestResponse getOfflineManifest(UUID courseId) {
        CourseEntity course = courseRepository.findById(courseId)
                .orElseThrow(() -> new ResourceNotFoundException("Course not found"));

        List<OfflineManifestResponse.OfflineLessonItem> downloads = new ArrayList<>();

        course.getSections().stream()
                .flatMap(s -> s.getLessons().stream())
                .filter(l -> !l.isDeleted())
                .forEach(l -> {
                    String url = l.getVideoUrl() != null ? l.getVideoUrl() : "https://storage.skillforge.com/downloads/lesson_" + l.getId();
                    downloads.add(new OfflineManifestResponse.OfflineLessonItem(
                            l.getId(),
                            l.getTitle(),
                            "VIDEO",
                            url,
                            l.getDurationMinutes() * 60
                    ));
                });

        return new OfflineManifestResponse(courseId, course.getTitle(), downloads);
    }

    @Transactional
    public void sendPushNotification(SendTestPushRequest request, UserEntity sender) {
        String email = request.userEmail() != null ? request.userEmail() : sender.getEmail();

        MobileNotificationEntity note = new MobileNotificationEntity();
        note.setUserEmail(email);
        note.setTitle(request.title().trim());
        note.setBody(request.body().trim());
        note.setSentStatus("SENT");
        note.setSentAt(Instant.now());
        note.setCreatedBy(sender.getEmail());
        note.setUpdatedBy(sender.getEmail());
        mobileNotificationRepository.save(note);

        // Print push logs for simulation
        List<MobileDeviceEntity> devices = mobileDeviceRepository.findByUserEmail(email).stream()
                .filter(MobileDeviceEntity::isActive)
                .toList();

        for (MobileDeviceEntity dev : devices) {
            System.out.println("FCM/APNS Push Dispatched: Title='" + request.title() + "' to token='" + dev.getDeviceToken() + "' (" + dev.getOsPlatform() + ")");
        }
    }

    public List<MobileNotificationEntity> getNotificationsHistory(String email) {
        return mobileNotificationRepository.findByUserEmail(email);
    }
}
