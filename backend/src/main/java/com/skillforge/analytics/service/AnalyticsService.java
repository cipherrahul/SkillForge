package com.skillforge.analytics.service;

import com.skillforge.auth.entity.UserEntity;
import com.skillforge.auth.repository.UserRepository;
import com.skillforge.common.exception.ResourceNotFoundException;
import com.skillforge.course.entity.CourseEntity;
import com.skillforge.course.repository.CourseRepository;
import com.skillforge.enrollment.entity.EnrollmentEntity;
import com.skillforge.enrollment.repository.EnrollmentRepository;
import com.skillforge.payment.entity.OrderEntity;
import com.skillforge.payment.entity.OrderStatus;
import com.skillforge.payment.repository.OrderRepository;
import com.skillforge.analytics.dto.*;
import com.skillforge.analytics.entity.UserActivityLogEntity;
import com.skillforge.analytics.repository.UserActivityLogRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

@Service
public class AnalyticsService {
    private final UserActivityLogRepository userActivityLogRepository;
    private final UserRepository userRepository;
    private final OrderRepository orderRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final CourseRepository courseRepository;

    public AnalyticsService(UserActivityLogRepository userActivityLogRepository,
                            UserRepository userRepository,
                            OrderRepository orderRepository,
                            EnrollmentRepository enrollmentRepository,
                            CourseRepository courseRepository) {
        this.userActivityLogRepository = userActivityLogRepository;
        this.userRepository = userRepository;
        this.orderRepository = orderRepository;
        this.enrollmentRepository = enrollmentRepository;
        this.courseRepository = courseRepository;
    }

    @Transactional
    public void logActivity(LogActivityRequest request, UserEntity currentUser) {
        UserActivityLogEntity log = new UserActivityLogEntity();
        log.setUserEmail(currentUser.getEmail());
        log.setAction(request.action().toUpperCase().trim());
        log.setDurationMinutes(request.durationMinutes());
        log.setTimestamp(Instant.now());
        log.setCreatedBy(currentUser.getEmail());
        log.setUpdatedBy(currentUser.getEmail());
        userActivityLogRepository.save(log);
    }

    public RevenueAnalyticsResponse getRevenueAnalytics() {
        List<OrderEntity> orders = orderRepository.findAll().stream()
                .filter(o -> !o.isDeleted() && o.getStatus() == OrderStatus.COMPLETED)
                .toList();

        double gross = orders.stream().mapToDouble(OrderEntity::getAmount).sum();
        double discounts = orders.stream().mapToDouble(OrderEntity::getDiscountAmount).sum();
        long count = orders.size();
        double avgVal = count > 0 ? gross / count : 0.0;

        return new RevenueAnalyticsResponse(gross, discounts, count, avgVal);
    }

    public StudentAnalyticsResponse getStudentAnalytics() {
        long totalStudents = userRepository.findAll().stream()
                .filter(u -> !u.isDeleted() && u.getRole().name().equalsIgnoreCase("STUDENT"))
                .count();

        Instant thirtyDaysAgo = Instant.now().minus(30, ChronoUnit.DAYS);
        long activeStudents = userActivityLogRepository.findByTimestampAfter(thirtyDaysAgo).stream()
                .filter(l -> !l.isDeleted())
                .map(UserActivityLogEntity::getUserEmail)
                .distinct()
                .count();

        List<EnrollmentEntity> enrolls = enrollmentRepository.findAll().stream()
                .filter(e -> !e.isDeleted())
                .toList();

        double avgProgress = enrolls.stream()
                .mapToDouble(EnrollmentEntity::getProgressPercent)
                .average()
                .orElse(0.0);

        long completed = enrolls.stream()
                .filter(EnrollmentEntity::isCompleted)
                .count();

        return new StudentAnalyticsResponse(totalStudents, activeStudents, avgProgress, completed);
    }

    public CoursePerformanceResponse getCoursePerformance(UUID courseId) {
        CourseEntity course = courseRepository.findById(courseId)
                .orElseThrow(() -> new ResourceNotFoundException("Course not found"));

        List<EnrollmentEntity> enrolls = enrollmentRepository.findByCourseId(courseId).stream()
                .filter(e -> !e.isDeleted())
                .toList();

        long enrolledCount = enrolls.size();
        long completedCount = enrolls.stream().filter(EnrollmentEntity::isCompleted).count();
        double completionRate = enrolledCount > 0 ? ((double) completedCount / enrolledCount) * 100.0 : 0.0;

        double totalRevenue = orderRepository.findAll().stream()
                .filter(o -> !o.isDeleted() && o.getStatus() == OrderStatus.COMPLETED && courseId.equals(o.getCourseId()))
                .mapToDouble(OrderEntity::getAmount)
                .sum();

        // Calculate average rating
        double averageRating = course.getAverageRating();

        return new CoursePerformanceResponse(
                courseId,
                course.getTitle(),
                enrolledCount,
                averageRating,
                completionRate,
                totalRevenue
        );
    }

    public PlatformKpisResponse getPlatformKpis() {
        long totalUsers = userRepository.findAll().stream().filter(u -> !u.isDeleted()).count();

        Instant thirtyDaysAgo = Instant.now().minus(30, ChronoUnit.DAYS);
        long mau = userActivityLogRepository.findByTimestampAfter(thirtyDaysAgo).stream()
                .filter(l -> !l.isDeleted())
                .map(UserActivityLogEntity::getUserEmail)
                .distinct()
                .count();

        double totalDuration = userActivityLogRepository.findAll().stream()
                .filter(l -> !l.isDeleted())
                .mapToDouble(UserActivityLogEntity::getDurationMinutes)
                .sum() / 60.0;

        double satisfaction = courseRepository.findAll().stream()
                .filter(c -> !c.isDeleted())
                .mapToDouble(CourseEntity::getAverageRating)
                .average()
                .orElse(0.0);

        return new PlatformKpisResponse(totalUsers, mau, totalDuration, satisfaction);
    }

    public String exportSummaryCsv() {
        StringBuilder csv = new StringBuilder();
        csv.append("Course ID,Course Title,Enrolled Count,Average Rating,Completion Rate %,Revenue Generated\n");

        List<CourseEntity> courses = courseRepository.findAll().stream()
                .filter(c -> !c.isDeleted())
                .toList();

        for (CourseEntity c : courses) {
            CoursePerformanceResponse perf = getCoursePerformance(c.getId());
            csv.append("%s,%s,%d,%.2f,%.2f,%.2f\n".formatted(
                    c.getId(),
                    c.getTitle().replace(",", " "),
                    perf.enrolledCount(),
                    perf.averageRating(),
                    perf.completionRatePercent(),
                    perf.revenueGenerated()
            ));
        }

        return csv.toString();
    }
}
