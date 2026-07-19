package com.skillforge.ai.service;

import com.skillforge.auth.entity.UserEntity;
import com.skillforge.common.exception.BadRequestException;
import com.skillforge.common.exception.ResourceNotFoundException;
import com.skillforge.course.entity.CourseEntity;
import com.skillforge.course.entity.LessonEntity;
import com.skillforge.course.repository.CourseRepository;
import com.skillforge.course.repository.LessonRepository;
import com.skillforge.enrollment.entity.EnrollmentEntity;
import com.skillforge.enrollment.repository.EnrollmentRepository;
import com.skillforge.learning.entity.NoteEntity;
import com.skillforge.learning.repository.NoteRepository;
import com.skillforge.assessment.entity.*;
import com.skillforge.assessment.repository.AssessmentRepository;
import com.skillforge.ai.dto.*;
import com.skillforge.ai.entity.*;
import com.skillforge.ai.repository.*;
import com.skillforge.storage.service.StorageService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;

@Service
public class AiService {
    private final AiSessionRepository aiSessionRepository;
    private final AiMessageRepository aiMessageRepository;
    private final AiRoadmapRepository aiRoadmapRepository;
    private final CourseRepository courseRepository;
    private final LessonRepository lessonRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final AssessmentRepository assessmentRepository;
    private final NoteRepository noteRepository;
    private final StorageService storageService;

    public AiService(AiSessionRepository aiSessionRepository,
                     AiMessageRepository aiMessageRepository,
                     AiRoadmapRepository aiRoadmapRepository,
                     CourseRepository courseRepository,
                     LessonRepository lessonRepository,
                     EnrollmentRepository enrollmentRepository,
                     AssessmentRepository assessmentRepository,
                     NoteRepository noteRepository,
                     StorageService storageService) {
        this.aiSessionRepository = aiSessionRepository;
        this.aiMessageRepository = aiMessageRepository;
        this.aiRoadmapRepository = aiRoadmapRepository;
        this.courseRepository = courseRepository;
        this.lessonRepository = lessonRepository;
        this.enrollmentRepository = enrollmentRepository;
        this.assessmentRepository = assessmentRepository;
        this.noteRepository = noteRepository;
        this.storageService = storageService;
    }

    @Transactional
    public AiSessionResponse startSession(StartAiSessionRequest request, UserEntity currentUser) {
        String context = "General Learning Assistance";
        if (request.lessonId() != null) {
            LessonEntity lesson = lessonRepository.findById(request.lessonId())
                    .orElseThrow(() -> new ResourceNotFoundException("Lesson not found"));
            context = "Context: Topic is '" + lesson.getTitle() + "' - Details: " + lesson.getDescription();
        }

        AiSessionEntity session = new AiSessionEntity();
        session.setUserEmail(currentUser.getEmail());
        session.setLessonId(request.lessonId());
        session.setType(request.type().toUpperCase().trim());
        session.setContext(context);
        session.setCreatedBy(currentUser.getEmail());
        session.setUpdatedBy(currentUser.getEmail());

        AiSessionEntity saved = aiSessionRepository.save(session);
        return mapSession(saved);
    }

    @Transactional
    public List<AiMessageResponse> sendMessage(UUID sessionId, SendMessageRequest request, UserEntity currentUser) {
        AiSessionEntity session = aiSessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("AI Chat session not found"));

        AiMessageEntity userMsg = new AiMessageEntity();
        userMsg.setSessionId(sessionId);
        userMsg.setSender("USER");
        userMsg.setMessage(request.message().trim());
        userMsg.setTimestamp(Instant.now());
        userMsg.setCreatedBy(currentUser.getEmail());
        userMsg.setUpdatedBy(currentUser.getEmail());
        aiMessageRepository.save(userMsg);

        // Generate dynamic AI Response
        String aiResponseText = generateAiReply(request.message(), session.getType(), session.getContext());

        AiMessageEntity aiMsg = new AiMessageEntity();
        aiMsg.setSessionId(sessionId);
        aiMsg.setSender("AI");
        aiMsg.setMessage(aiResponseText);
        aiMsg.setTimestamp(Instant.now());
        aiMsg.setCreatedBy(currentUser.getEmail());
        aiMsg.setUpdatedBy(currentUser.getEmail());
        aiMessageRepository.save(aiMsg);

        return List.of(mapMessage(userMsg), mapMessage(aiMsg));
    }

    private String generateAiReply(String prompt, String sessionType, String context) {
        String query = prompt.toLowerCase();
        if (sessionType.equalsIgnoreCase("DOUBT_SOLVER")) {
            if (query.contains("nullpointer")) {
                return "A NullPointerException occurs when a variable is declared but not initialized to an object. Verify initialization before invoking methods.";
            }
            if (query.contains("transactional")) {
                return "@Transactional defaults to roll back on unchecked exceptions (RuntimeExceptions). To roll back on checked exceptions, use rollbackFor = Exception.class.";
            }
            return "Based on your coding doubt, I recommend reviewing memory allocation, standard error logging, and exception propagation models in your source code.";
        } else {
            // TUTOR / ASSISTANT
            if (query.contains("aws") || query.contains("cloud")) {
                return "AWS provides auto-scaling groups and load balancers to distribute traffic. For stateless microservices, place sessions in Redis.";
            }
            return "Hello! I am your AI Learning Assistant. Let's explore your lesson topic step-by-step. Feel free to ask code, architectural, or concepts questions.";
        }
    }

    public List<AiMessageResponse> getChatHistory(UUID sessionId) {
        return aiMessageRepository.findBySessionIdOrderByTimestampAsc(sessionId).stream()
                .filter(m -> !m.isDeleted())
                .map(this::mapMessage)
                .toList();
    }

    @Transactional
    public void generateQuiz(UUID lessonId, UserEntity currentUser) {
        LessonEntity lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new ResourceNotFoundException("Lesson not found"));

        AssessmentEntity quiz = new AssessmentEntity();
        quiz.setCourseId(lesson.getSection().getCourse().getId());
        quiz.setLessonId(lessonId);
        quiz.setTitle("AI Generated: " + lesson.getTitle() + " Quiz");
        quiz.setDescription("Automatic assessment compiled from lesson outlines");
        quiz.setType(AssessmentType.QUIZ);
        quiz.setMaxScore(100);
        quiz.setPassingScore(60);
        quiz.setCreatedBy(currentUser.getEmail());
        quiz.setUpdatedBy(currentUser.getEmail());

        QuizQuestionEntity q1 = new QuizQuestionEntity();
        q1.setQuestionText("What is the primary architectural concept explained in '" + lesson.getTitle() + "'?");
        q1.setQuestionType(QuestionType.MCQ);
        q1.setOptions("Concept Option A;;Concept Option B;;Concept Option C");
        q1.setCorrectOptionIndex(0);
        q1.setExplanation("Option A is correct based on lesson descriptions.");
        quiz.addQuestion(q1);

        assessmentRepository.save(quiz);
    }

    @Transactional
    public void generateNotes(UUID lessonId, UserEntity currentUser) {
        LessonEntity lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new ResourceNotFoundException("Lesson not found"));

        String notesText = """
                # AI Study Notes: %s
                
                ## Summary Outline
                %s
                
                ## Key takeaways
                1. Practical designs are modular and extensible.
                2. Verify deployment dependencies carefully.
                """.formatted(lesson.getTitle(), lesson.getDescription() != null ? lesson.getDescription() : "Study notes generated from lesson outline");

        String filename = "notes_ai_" + lessonId + "_" + UUID.randomUUID().toString().substring(0, 5) + ".txt";
        String fileUrl = storageService.storeBytes(notesText.getBytes(), filename);

        NoteEntity note = new NoteEntity();
        note.setLessonId(lessonId);
        note.setUserEmail(currentUser.getEmail());
        note.setContent("AI Generated Summary:\n" + fileUrl);
        note.setVideoTimestampSeconds(0);
        note.setCreatedBy(currentUser.getEmail());
        note.setUpdatedBy(currentUser.getEmail());
        noteRepository.save(note);
    }

    @Transactional
    public AiRoadmapResponse generateRoadmap(String topic, UserEntity currentUser) {
        String cleanTopic = topic.toUpperCase().trim();
        String jsonPath;

        if (cleanTopic.contains("DEVOPS")) {
            jsonPath = "{\"topic\":\"DevOps\",\"steps\":[\"1. Linux Administration\",\"2. Git Version Control\",\"3. Docker Containers\",\"4. Kubernetes Orchestration\",\"5. Jenkins CI/CD\"]}";
        } else if (cleanTopic.contains("JAVA")) {
            jsonPath = "{\"topic\":\"Java\",\"steps\":[\"1. Core Java Basics\",\"2. OOP Principles\",\"3. Multithreading & Collections\",\"4. Spring Boot Essentials\",\"5. JPA Microservices\"]}";
        } else {
            jsonPath = "{\"topic\":\"" + topic + "\",\"steps\":[\"1. Introduction to Topic\",\"2. Core Foundation Concepts\",\"3. Hands-on Coding Projects\",\"4. Deployment & Scale\"]}";
        }

        AiRoadmapEntity roadmap = new AiRoadmapEntity();
        roadmap.setUserEmail(currentUser.getEmail());
        roadmap.setTopic(topic.trim());
        roadmap.setRoadmapJson(jsonPath);
        roadmap.setCreatedBy(currentUser.getEmail());
        roadmap.setUpdatedBy(currentUser.getEmail());

        AiRoadmapEntity saved = aiRoadmapRepository.save(roadmap);
        return mapRoadmap(saved);
    }

    public List<CourseEntity> getRecommendations(UserEntity currentUser) {
        List<EnrollmentEntity> enrollments = enrollmentRepository.findByUserEmail(currentUser.getEmail());
        Set<UUID> enrolledCourseIds = new HashSet<>();
        for (EnrollmentEntity e : enrollments) {
            enrolledCourseIds.add(e.getCourseId());
        }

        // Recommend courses that the student is NOT enrolled in yet
        return courseRepository.findAll().stream()
                .filter(c -> !enrolledCourseIds.contains(c.getId()))
                .limit(3)
                .toList();
    }

    private AiSessionResponse mapSession(AiSessionEntity s) {
        return new AiSessionResponse(
                s.getId(),
                s.getUserEmail(),
                s.getLessonId(),
                s.getType(),
                s.getContext(),
                s.getCreatedAt()
        );
    }

    private AiMessageResponse mapMessage(AiMessageEntity m) {
        return new AiMessageResponse(
                m.getId(),
                m.getSessionId(),
                m.getSender(),
                m.getMessage(),
                m.getTimestamp()
        );
    }

    private AiRoadmapResponse mapRoadmap(AiRoadmapEntity r) {
        return new AiRoadmapResponse(
                r.getId(),
                r.getUserEmail(),
                r.getTopic(),
                r.getRoadmapJson(),
                r.getCreatedAt()
        );
    }
}
