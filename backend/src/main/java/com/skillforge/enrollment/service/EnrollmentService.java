package com.skillforge.enrollment.service;

import com.skillforge.auth.entity.UserEntity;
import com.skillforge.common.exception.BadRequestException;
import com.skillforge.common.exception.ResourceNotFoundException;
import com.skillforge.course.entity.CourseEntity;
import com.skillforge.course.repository.CourseRepository;
import com.skillforge.certificate.service.CertificateService;
import com.skillforge.enrollment.dto.EnrollmentResponse;
import com.skillforge.enrollment.dto.UpdateProgressRequest;
import com.skillforge.enrollment.entity.EnrollmentEntity;
import com.skillforge.enrollment.entity.LessonProgressEntity;
import com.skillforge.enrollment.repository.EnrollmentRepository;
import com.skillforge.enrollment.repository.LessonProgressRepository;
import com.skillforge.payment.entity.SubscriptionStatus;
import com.skillforge.payment.repository.UserSubscriptionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class EnrollmentService {
    private final EnrollmentRepository enrollmentRepository;
    private final LessonProgressRepository lessonProgressRepository;
    private final CourseRepository courseRepository;
    private final CertificateService certificateService;
    private final UserSubscriptionRepository userSubscriptionRepository;

    public EnrollmentService(EnrollmentRepository enrollmentRepository,
                             LessonProgressRepository lessonProgressRepository,
                             CourseRepository courseRepository,
                             CertificateService certificateService,
                             UserSubscriptionRepository userSubscriptionRepository) {
        this.enrollmentRepository = enrollmentRepository;
        this.lessonProgressRepository = lessonProgressRepository;
        this.courseRepository = courseRepository;
        this.certificateService = certificateService;
        this.userSubscriptionRepository = userSubscriptionRepository;
    }

    @Transactional
    public EnrollmentResponse enroll(UUID courseId, UserEntity user) {
        CourseEntity course = courseRepository.findById(courseId)
                .orElseThrow(() -> new ResourceNotFoundException("Course not found"));

        if (enrollmentRepository.existsByUserEmailAndCourseId(user.getEmail(), courseId)) {
            throw new BadRequestException("You are already enrolled in this course");
        }

        EnrollmentEntity enrollment = new EnrollmentEntity();
        enrollment.setUserEmail(user.getEmail());
        enrollment.setCourseId(courseId);
        EnrollmentEntity saved = enrollmentRepository.save(enrollment);

        // Update Course Enrolled Count
        course.setEnrolledCount(course.getEnrolledCount() + 1);
        courseRepository.save(course);

        return mapToResponse(saved, course.getTitle());
    }

    @Transactional
    public void updateLessonProgress(UUID enrollmentId, UUID lessonId, UpdateProgressRequest request, UserEntity user) {
        EnrollmentEntity enrollment = enrollmentRepository.findById(enrollmentId)
                .orElseThrow(() -> new ResourceNotFoundException("Enrollment not found"));

        if (!enrollment.getUserEmail().equalsIgnoreCase(user.getEmail())) {
            throw new BadRequestException("Access denied");
        }

        CourseEntity course = courseRepository.findById(enrollment.getCourseId())
                .orElseThrow(() -> new ResourceNotFoundException("Course not found"));

        LessonProgressEntity progress = lessonProgressRepository
                .findByEnrollmentIdAndLessonId(enrollmentId, lessonId)
                .orElseGet(() -> {
                    LessonProgressEntity newProgress = new LessonProgressEntity();
                    newProgress.setLessonId(lessonId);
                    enrollment.addLessonProgress(newProgress);
                    return newProgress;
                });

        progress.setPlaybackPositionSeconds(request.playbackPositionSeconds());
        if (request.completed() && !progress.isCompleted()) {
            progress.setCompleted(true);
            progress.setCompletedAt(Instant.now());
        }

        lessonProgressRepository.save(progress);

        // Recalculate progress percent
        int totalLessons = course.getSections().stream()
                .mapToInt(section -> section.getLessons().size())
                .sum();

        if (totalLessons > 0) {
            long completedLessons = enrollment.getLessonProgresses().stream()
                    .filter(LessonProgressEntity::isCompleted)
                    .count();

            double percent = ((double) completedLessons / totalLessons) * 100.0;
            enrollment.setProgressPercent(Math.min(100.0, percent));

            if (completedLessons == totalLessons && !enrollment.isCompleted()) {
                enrollment.setCompleted(true);
                enrollment.setCompletedAt(Instant.now());
                certificateService.generateCertificate(enrollment);
            }
        } else {
            enrollment.setProgressPercent(0.0);
        }

        enrollmentRepository.save(enrollment);
    }

    public List<EnrollmentResponse> getEnrollments(UserEntity user) {
        return enrollmentRepository.findByUserEmail(user.getEmail()).stream()
                .map(e -> {
                    String title = courseRepository.findById(e.getCourseId())
                            .map(CourseEntity::getTitle)
                            .orElse("Deleted Course");
                    return mapToResponse(e, title);
                })
                .toList();
    }

    public boolean isEnrolled(String email, UUID courseId) {
        if (email == null) return false;
        if (enrollmentRepository.existsByUserEmailAndCourseId(email, courseId)) {
            return true;
        }
        // Or user has an active membership subscription
        return userSubscriptionRepository.findFirstByUserEmailAndStatusOrderByEndDateDesc(email, SubscriptionStatus.ACTIVE)
                .filter(s -> s.getEndDate().isAfter(Instant.now()))
                .isPresent();
    }

    private EnrollmentResponse mapToResponse(EnrollmentEntity e, String courseTitle) {
        return new EnrollmentResponse(
                e.getId(),
                e.getCourseId(),
                courseTitle,
                e.getProgressPercent(),
                e.isCompleted(),
                e.getEnrolledAt(),
                e.getCompletedAt()
        );
    }
}
