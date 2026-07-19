package com.skillforge.assessment.service;

import com.skillforge.auth.entity.UserEntity;
import com.skillforge.assessment.dto.*;
import com.skillforge.assessment.entity.*;
import com.skillforge.assessment.repository.*;
import com.skillforge.common.exception.BadRequestException;
import com.skillforge.common.exception.ResourceNotFoundException;
import com.skillforge.common.exception.UnauthorizedException;
import com.skillforge.course.entity.CourseEntity;
import com.skillforge.course.repository.CourseRepository;
import com.skillforge.enrollment.service.EnrollmentService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class AssessmentService {
    private final AssessmentRepository assessmentRepository;
    private final SubmissionRepository submissionRepository;
    private final CourseRepository courseRepository;
    private final EnrollmentService enrollmentService;

    public AssessmentService(AssessmentRepository assessmentRepository,
                             SubmissionRepository submissionRepository,
                             CourseRepository courseRepository,
                             EnrollmentService enrollmentService) {
        this.assessmentRepository = assessmentRepository;
        this.submissionRepository = submissionRepository;
        this.courseRepository = courseRepository;
        this.enrollmentService = enrollmentService;
    }

    @Transactional
    public AssessmentResponse createAssessment(UUID courseId, CreateAssessmentRequest request, UserEntity currentUser) {
        CourseEntity course = courseRepository.findById(courseId)
                .orElseThrow(() -> new ResourceNotFoundException("Course not found"));

        if (!course.getInstructorEmail().equalsIgnoreCase(currentUser.getEmail())) {
            throw new UnauthorizedException("You can only edit assessments for your own courses");
        }

        AssessmentEntity assessment = new AssessmentEntity();
        assessment.setCourseId(courseId);
        assessment.setLessonId(request.lessonId());
        assessment.setTitle(request.title().trim());
        assessment.setDescription(request.description());
        assessment.setType(request.type());
        assessment.setMaxScore(request.maxScore());
        assessment.setPassingScore(request.passingScore());

        if (request.type() == AssessmentType.QUIZ && request.questions() != null) {
            for (QuizQuestionDto qDto : request.questions()) {
                QuizQuestionEntity question = new QuizQuestionEntity();
                question.setQuestionText(qDto.questionText().trim());
                question.setQuestionType(qDto.questionType());
                question.setOptions(String.join(";;", qDto.options()));
                question.setCorrectOptionIndex(qDto.correctOptionIndex());
                question.setExplanation(qDto.explanation());
                assessment.addQuestion(question);
            }
        }

        AssessmentEntity saved = assessmentRepository.save(assessment);
        return mapAssessment(saved);
    }

    public List<AssessmentResponse> getAssessments(UUID courseId) {
        return assessmentRepository.findByCourseId(courseId).stream()
                .map(this::mapAssessment)
                .toList();
    }

    @Transactional
    public SubmissionResponse submit(UUID assessmentId, SubmissionRequest request, UserEntity currentUser) {
        AssessmentEntity assessment = assessmentRepository.findById(assessmentId)
                .orElseThrow(() -> new ResourceNotFoundException("Assessment not found"));

        if (!enrollmentService.isEnrolled(currentUser.getEmail(), assessment.getCourseId())) {
            throw new BadRequestException("You must be enrolled in the course to submit assessments");
        }

        Optional<SubmissionEntity> existing = submissionRepository.findByAssessmentIdAndUserEmail(assessmentId, currentUser.getEmail());
        SubmissionEntity submission = existing.orElseGet(() -> {
            SubmissionEntity sub = new SubmissionEntity();
            sub.setAssessment(assessment);
            sub.setUserEmail(currentUser.getEmail());
            return sub;
        });

        submission.setSubmittedAt(Instant.now());

        if (assessment.getType() == AssessmentType.QUIZ) {
            List<QuizQuestionEntity> questions = assessment.getQuestions();
            List<Integer> selectedAnswers = request.selectedAnswers();
            if (selectedAnswers == null || selectedAnswers.size() != questions.size()) {
                throw new BadRequestException("You must answer all quiz questions");
            }

            int correctCount = 0;
            for (int i = 0; i < questions.size(); i++) {
                if (questions.get(i).getCorrectOptionIndex() == selectedAnswers.get(i)) {
                    correctCount++;
                }
            }

            int score = (int) (((double) correctCount / questions.size()) * assessment.getMaxScore());
            boolean passed = score >= assessment.getPassingScore();

            submission.setScore(score);
            submission.setPassed(passed);
            submission.setGraded(true);
            submission.setAnswersJson(selectedAnswers.stream()
                    .map(Object::toString)
                    .reduce((a, b) -> a + "," + b)
                    .orElse(""));
            submission.setFeedback("Auto-graded quiz: " + correctCount + "/" + questions.size() + " correct.");
        } else {
            // Assignment
            if (request.fileUrl() == null || request.fileUrl().isBlank()) {
                throw new BadRequestException("Assignment submission requires a file/work URL");
            }
            submission.setFileUrl(request.fileUrl());
            submission.setGraded(false);
            submission.setScore(0);
            submission.setPassed(false);
            submission.setFeedback("Awaiting instructor review");
        }

        SubmissionEntity saved = submissionRepository.save(submission);
        return mapSubmission(saved);
    }

    @Transactional
    public SubmissionResponse grade(UUID submissionId, GradeSubmissionRequest request, UserEntity currentUser) {
        SubmissionEntity submission = submissionRepository.findById(submissionId)
                .orElseThrow(() -> new ResourceNotFoundException("Submission not found"));

        CourseEntity course = courseRepository.findById(submission.getAssessment().getCourseId())
                .orElseThrow(() -> new ResourceNotFoundException("Course not found"));

        if (!course.getInstructorEmail().equalsIgnoreCase(currentUser.getEmail())) {
            throw new UnauthorizedException("Only the course instructor can grade submissions");
        }

        if (submission.getAssessment().getType() == AssessmentType.QUIZ) {
            throw new BadRequestException("Quizzes are auto-graded and cannot be modified by instructor");
        }

        submission.setScore(request.score());
        submission.setPassed(request.score() >= submission.getAssessment().getPassingScore());
        submission.setFeedback(request.feedback());
        submission.setGraded(true);

        SubmissionEntity saved = submissionRepository.save(submission);
        return mapSubmission(saved);
    }

    public List<SubmissionResponse> getSubmissions(UUID assessmentId, UserEntity currentUser) {
        AssessmentEntity assessment = assessmentRepository.findById(assessmentId)
                .orElseThrow(() -> new ResourceNotFoundException("Assessment not found"));

        CourseEntity course = courseRepository.findById(assessment.getCourseId())
                .orElseThrow(() -> new ResourceNotFoundException("Course not found"));

        // Instructors can see all submissions, students can only see their own
        if (course.getInstructorEmail().equalsIgnoreCase(currentUser.getEmail())) {
            return submissionRepository.findByAssessmentId(assessmentId).stream()
                    .map(this::mapSubmission)
                    .toList();
        } else {
            return submissionRepository.findByAssessmentIdAndUserEmail(assessmentId, currentUser.getEmail()).stream()
                    .map(this::mapSubmission)
                    .toList();
        }
    }

    private AssessmentResponse mapAssessment(AssessmentEntity assessment) {
        List<QuizQuestionDto> qDtos = assessment.getQuestions().stream()
                .map(q -> new QuizQuestionDto(
                        q.getQuestionText(),
                        q.getQuestionType(),
                        Arrays.asList(q.getOptions().split(";;")),
                        q.getCorrectOptionIndex(),
                        q.getExplanation()
                ))
                .toList();

        return new AssessmentResponse(
                assessment.getId(),
                assessment.getCourseId(),
                assessment.getLessonId(),
                assessment.getTitle(),
                assessment.getDescription(),
                assessment.getType(),
                assessment.getMaxScore(),
                assessment.getPassingScore(),
                qDtos,
                assessment.getCreatedAt()
        );
    }

    private SubmissionResponse mapSubmission(SubmissionEntity sub) {
        return new SubmissionResponse(
                sub.getId(),
                sub.getAssessment().getId(),
                sub.getUserEmail(),
                sub.getScore(),
                sub.isPassed(),
                sub.getFeedback(),
                sub.isGraded(),
                sub.getSubmittedAt(),
                sub.getFileUrl()
        );
    }
}
