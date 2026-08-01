package com.skillforge.liveclass.service;

import com.skillforge.auth.entity.UserEntity;
import com.skillforge.auth.repository.UserRepository;
import com.skillforge.common.exception.BadRequestException;
import com.skillforge.common.exception.ResourceNotFoundException;
import com.skillforge.common.exception.UnauthorizedException;
import com.skillforge.course.entity.CourseEntity;
import com.skillforge.course.repository.CourseRepository;
import com.skillforge.enrollment.entity.EnrollmentEntity;
import com.skillforge.enrollment.repository.EnrollmentRepository;
import com.skillforge.liveclass.dto.*;
import com.skillforge.liveclass.entity.*;
import com.skillforge.liveclass.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
public class LiveClassService {
    private final LiveSessionRepository liveSessionRepository;
    private final MentoringSessionRepository mentoringSessionRepository;
    private final AttendanceRepository attendanceRepository;
    private final LiveChatMessageRepository liveChatMessageRepository;
    private final CourseRepository courseRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final UserRepository userRepository;

    public LiveClassService(LiveSessionRepository liveSessionRepository,
                            MentoringSessionRepository mentoringSessionRepository,
                            AttendanceRepository attendanceRepository,
                            LiveChatMessageRepository liveChatMessageRepository,
                            CourseRepository courseRepository,
                            EnrollmentRepository enrollmentRepository,
                            UserRepository userRepository) {
        this.liveSessionRepository = liveSessionRepository;
        this.mentoringSessionRepository = mentoringSessionRepository;
        this.attendanceRepository = attendanceRepository;
        this.liveChatMessageRepository = liveChatMessageRepository;
        this.courseRepository = courseRepository;
        this.enrollmentRepository = enrollmentRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public LiveSessionResponse scheduleLiveSession(UUID courseId, ScheduleSessionRequest request, UserEntity currentUser) {
        CourseEntity course = courseRepository.findById(courseId)
                .orElseThrow(() -> new ResourceNotFoundException("Course not found"));

        if (!course.getInstructorEmail().equalsIgnoreCase(currentUser.getEmail())) {
            throw new UnauthorizedException("Only the course instructor can schedule live sessions");
        }

        if (request.startTime().isAfter(request.endTime())) {
            throw new BadRequestException("Start time must be before end time");
        }

        LiveSessionEntity session = new LiveSessionEntity();
        session.setCourseId(courseId);
        session.setTitle(request.title().trim());
        session.setDescription(request.description());
        session.setStartTime(request.startTime());
        session.setEndTime(request.endTime());
        session.setInstructorEmail(currentUser.getEmail());
        session.setType(LiveSessionType.valueOf(request.type().toUpperCase()));
        session.setStatus(LiveSessionStatus.SCHEDULED);
        session.setMeetingUrl("https://live.skillforge.com/rooms/" + UUID.randomUUID());
        session.setCreatedBy(currentUser.getEmail());
        session.setUpdatedBy(currentUser.getEmail());

        LiveSessionEntity saved = liveSessionRepository.save(session);
        return mapSession(saved);
    }

    @Transactional
    public LiveSessionResponse updateLiveSession(UUID sessionId, ScheduleSessionRequest request, UserEntity currentUser) {
        LiveSessionEntity session = liveSessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Live session not found"));

        CourseEntity course = courseRepository.findById(session.getCourseId())
                .orElseThrow(() -> new ResourceNotFoundException("Course not found"));

        if (!course.getInstructorEmail().equalsIgnoreCase(currentUser.getEmail())) {
            throw new UnauthorizedException("Only the course instructor can update live sessions");
        }

        if (request.startTime().isAfter(request.endTime())) {
            throw new BadRequestException("Start time must be before end time");
        }

        session.setTitle(request.title().trim());
        session.setDescription(request.description());
        session.setStartTime(request.startTime());
        session.setEndTime(request.endTime());
        session.setType(LiveSessionType.valueOf(request.type().toUpperCase()));
        session.setUpdatedAt(Instant.now());
        session.setUpdatedBy(currentUser.getEmail());

        LiveSessionEntity saved = liveSessionRepository.save(session);
        return mapSession(saved);
    }

    public List<LiveSessionResponse> getLiveSessions(UUID courseId) {
        return liveSessionRepository.findByCourseId(courseId).stream()
                .filter(s -> !s.isDeleted())
                .map(this::mapSession)
                .toList();
    }

    /**
     * Returns live sessions for all courses relevant to the current user.
     * - INSTRUCTOR: all sessions across their created courses
     * - STUDENT: all sessions across their enrolled courses
     */
    public List<LiveSessionResponse> getAllLiveSessionsForUser(UserEntity currentUser) {
        List<UUID> courseIds;
        // Check if instructor: find courses they created
        List<CourseEntity> instructorCourses = courseRepository.findByInstructorEmail(currentUser.getEmail());
        if (!instructorCourses.isEmpty()) {
            courseIds = instructorCourses.stream().map(CourseEntity::getId).toList();
        } else {
            // Student: find enrolled courses
            List<EnrollmentEntity> enrollments = enrollmentRepository.findByUserEmail(currentUser.getEmail());
            courseIds = enrollments.stream().map(EnrollmentEntity::getCourseId).toList();
        }
        if (courseIds.isEmpty()) return List.of();
        return liveSessionRepository.findByCourseIdIn(courseIds).stream()
                .filter(s -> !s.isDeleted())
                .map(this::mapSession)
                .toList();
    }

    @Transactional
    public AttendanceResponse joinSession(UUID sessionId, UserEntity currentUser) {
        LiveSessionEntity session = liveSessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Live session not found"));

        AttendanceEntity attendance = attendanceRepository.findByLiveSessionIdAndUserEmail(sessionId, currentUser.getEmail())
                .orElseGet(() -> {
                    AttendanceEntity att = new AttendanceEntity();
                    att.setLiveSessionId(sessionId);
                    att.setUserEmail(currentUser.getEmail());
                    att.setCreatedBy(currentUser.getEmail());
                    return att;
                });

        attendance.setJoinedAt(Instant.now());
        attendance.setUpdatedAt(Instant.now());
        attendance.setUpdatedBy(currentUser.getEmail());

        AttendanceEntity saved = attendanceRepository.save(attendance);
        return mapAttendance(saved);
    }

    @Transactional
    public AttendanceResponse leaveSession(UUID sessionId, UserEntity currentUser) {
        AttendanceEntity attendance = attendanceRepository.findByLiveSessionIdAndUserEmail(sessionId, currentUser.getEmail())
                .orElseThrow(() -> new ResourceNotFoundException("Attendance record not found for this session"));

        attendance.setLeftAt(Instant.now());
        long diff = Duration.between(attendance.getJoinedAt(), attendance.getLeftAt()).toMinutes();
        attendance.setDurationMinutes((int) diff);
        attendance.setUpdatedAt(Instant.now());
        attendance.setUpdatedBy(currentUser.getEmail());

        AttendanceEntity saved = attendanceRepository.save(attendance);
        return mapAttendance(saved);
    }

    @Transactional
    public LiveSessionResponse updateRecordingUrl(UUID sessionId, String recordingUrl, UserEntity currentUser) {
        LiveSessionEntity session = liveSessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Live session not found"));

        CourseEntity course = courseRepository.findById(session.getCourseId())
                .orElseThrow(() -> new ResourceNotFoundException("Course not found"));

        if (!course.getInstructorEmail().equalsIgnoreCase(currentUser.getEmail())) {
            throw new UnauthorizedException("Only the course instructor can upload session recordings");
        }

        session.setRecordingUrl(recordingUrl);
        session.setStatus(LiveSessionStatus.COMPLETED);
        session.setUpdatedAt(Instant.now());
        session.setUpdatedBy(currentUser.getEmail());

        LiveSessionEntity saved = liveSessionRepository.save(session);
        return mapSession(saved);
    }

    @Transactional
    public MentoringResponse bookMentoring(BookMentoringRequest request, UserEntity currentUser) {
        UserEntity instructor = userRepository.findByEmail(request.instructorEmail())
                .orElseThrow(() -> new ResourceNotFoundException("Instructor not found"));

        if (request.startTime().isAfter(request.endTime())) {
            throw new BadRequestException("Start time must be before end time");
        }

        if (request.startTime().isBefore(Instant.now())) {
            throw new BadRequestException("Start time must be in the future");
        }

        MentoringSessionEntity session = new MentoringSessionEntity();
        session.setInstructorEmail(instructor.getEmail());
        session.setStudentEmail(currentUser.getEmail());
        session.setTitle(request.title().trim());
        session.setDescription(request.description());
        session.setStartTime(request.startTime());
        session.setEndTime(request.endTime());
        session.setStatus(MentoringStatus.REQUESTED);
        session.setMeetingUrl("https://live.skillforge.com/rooms/" + UUID.randomUUID());
        session.setCreatedBy(currentUser.getEmail());
        session.setUpdatedBy(currentUser.getEmail());

        MentoringSessionEntity saved = mentoringSessionRepository.save(session);
        return mapMentoring(saved);
    }

    @Transactional
    public MentoringResponse updateMentoringStatus(UUID sessionId, String status, UserEntity currentUser) {
        MentoringSessionEntity session = mentoringSessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Mentoring session not found"));

        if (!session.getInstructorEmail().equalsIgnoreCase(currentUser.getEmail()) &&
                !session.getStudentEmail().equalsIgnoreCase(currentUser.getEmail())) {
            throw new UnauthorizedException("You are not part of this mentoring session");
        }

        session.setStatus(MentoringStatus.valueOf(status.toUpperCase()));
        session.setUpdatedAt(Instant.now());
        session.setUpdatedBy(currentUser.getEmail());

        MentoringSessionEntity saved = mentoringSessionRepository.save(session);
        return mapMentoring(saved);
    }

    public List<MentoringResponse> getMentoringSessions(UserEntity currentUser) {
        return mentoringSessionRepository.findByStudentEmailOrInstructorEmail(currentUser.getEmail(), currentUser.getEmail()).stream()
                .filter(s -> !s.isDeleted())
                .map(this::mapMentoring)
                .toList();
    }

    @Transactional
    public ChatMessageResponse postChatMessage(UUID sessionId, PostChatMessageRequest request, UserEntity currentUser) {
        // Validate session exists in either live sessions or mentoring sessions
        boolean sessionExists = liveSessionRepository.existsById(sessionId) || mentoringSessionRepository.existsById(sessionId);
        if (!sessionExists) {
            throw new ResourceNotFoundException("Active session not found");
        }

        LiveChatMessageEntity message = new LiveChatMessageEntity();
        message.setSessionId(sessionId);
        message.setSenderEmail(currentUser.getEmail());
        message.setSenderName(currentUser.getFullName());
        message.setMessage(request.message().trim());
        message.setTimestamp(Instant.now());
        message.setCreatedBy(currentUser.getEmail());
        message.setUpdatedBy(currentUser.getEmail());

        LiveChatMessageEntity saved = liveChatMessageRepository.save(message);
        return mapChatMessage(saved);
    }

    public List<ChatMessageResponse> getChatHistory(UUID sessionId, UserEntity currentUser) {
        boolean sessionExists = liveSessionRepository.existsById(sessionId) || mentoringSessionRepository.existsById(sessionId);
        if (!sessionExists) {
            throw new ResourceNotFoundException("Active session not found");
        }

        return liveChatMessageRepository.findBySessionIdOrderByTimestampAsc(sessionId).stream()
                .map(this::mapChatMessage)
                .toList();
    }

    public String generateICalendarExport(UserEntity user) {
        List<EnrollmentEntity> enrollments = enrollmentRepository.findByUserEmail(user.getEmail());
        List<UUID> courseIds = enrollments.stream().map(EnrollmentEntity::getCourseId).toList();

        List<LiveSessionEntity> liveSessions = new ArrayList<>();
        if (!courseIds.isEmpty()) {
            liveSessions = liveSessionRepository.findByCourseIdIn(courseIds);
        }

        List<MentoringSessionEntity> mentoringSessions = mentoringSessionRepository
                .findByStudentEmailOrInstructorEmail(user.getEmail(), user.getEmail());

        StringBuilder ical = new StringBuilder();
        ical.append("BEGIN:VCALENDAR\r\n");
        ical.append("VERSION:2.0\r\n");
        ical.append("PRODID:-//SkillForge//Ecosystem//EN\r\n");

        DateTimeFormatter iCalFormat = DateTimeFormatter.ofPattern("yyyyMMdd'T'HHmmss'Z'").withZone(ZoneOffset.UTC);
        String nowStr = iCalFormat.format(Instant.now());

        // Live sessions
        for (LiveSessionEntity s : liveSessions) {
            if (s.isDeleted()) continue;
            ical.append("BEGIN:VEVENT\r\n");
            ical.append("UID:").append(s.getId().toString()).append("@skillforge.com\r\n");
            ical.append("DTSTAMP:").append(nowStr).append("\r\n");
            ical.append("DTSTART:").append(iCalFormat.format(s.getStartTime())).append("\r\n");
            ical.append("DTEND:").append(iCalFormat.format(s.getEndTime())).append("\r\n");
            ical.append("SUMMARY:").append(s.getTitle()).append("\r\n");
            ical.append("DESCRIPTION:").append(s.getDescription() != null ? s.getDescription() : "").append("\r\n");
            ical.append("LOCATION:").append(s.getMeetingUrl() != null ? s.getMeetingUrl() : "").append("\r\n");
            ical.append("END:VEVENT\r\n");
        }

        // Mentoring sessions
        for (MentoringSessionEntity m : mentoringSessions) {
            if (m.isDeleted()) continue;
            ical.append("BEGIN:VEVENT\r\n");
            ical.append("UID:").append(m.getId().toString()).append("@skillforge.com\r\n");
            ical.append("DTSTAMP:").append(nowStr).append("\r\n");
            ical.append("DTSTART:").append(iCalFormat.format(m.getStartTime())).append("\r\n");
            ical.append("DTEND:").append(iCalFormat.format(m.getEndTime())).append("\r\n");
            ical.append("SUMMARY:Mentoring: ").append(m.getTitle()).append("\r\n");
            ical.append("DESCRIPTION:").append(m.getDescription() != null ? m.getDescription() : "").append("\r\n");
            ical.append("LOCATION:").append(m.getMeetingUrl() != null ? m.getMeetingUrl() : "").append("\r\n");
            ical.append("END:VEVENT\r\n");
        }

        ical.append("END:VCALENDAR\r\n");
        return ical.toString();
    }

    private LiveSessionResponse mapSession(LiveSessionEntity s) {
        return new LiveSessionResponse(
                s.getId(),
                s.getCourseId(),
                s.getTitle(),
                s.getDescription(),
                s.getInstructorEmail(),
                s.getStartTime(),
                s.getEndTime(),
                s.getType(),
                s.getStatus(),
                s.getMeetingUrl(),
                s.getRecordingUrl()
        );
    }

    private MentoringResponse mapMentoring(MentoringSessionEntity m) {
        return new MentoringResponse(
                m.getId(),
                m.getInstructorEmail(),
                m.getStudentEmail(),
                m.getTitle(),
                m.getDescription(),
                m.getStartTime(),
                m.getEndTime(),
                m.getStatus(),
                m.getMeetingUrl(),
                m.getFeedback()
        );
    }

    private AttendanceResponse mapAttendance(AttendanceEntity a) {
        return new AttendanceResponse(
                a.getId(),
                a.getLiveSessionId(),
                a.getUserEmail(),
                a.getJoinedAt(),
                a.getLeftAt(),
                a.getDurationMinutes()
        );
    }

    private ChatMessageResponse mapChatMessage(LiveChatMessageEntity c) {
        return new ChatMessageResponse(
                c.getId(),
                c.getSessionId(),
                c.getSenderEmail(),
                c.getSenderName(),
                c.getMessage(),
                c.getTimestamp()
        );
    }
}
