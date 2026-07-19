package com.skillforge.enrollment;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.skillforge.assessment.dto.CreateAssessmentRequest;
import com.skillforge.assessment.dto.QuizQuestionDto;
import com.skillforge.assessment.dto.SubmissionRequest;
import com.skillforge.assessment.entity.AssessmentType;
import com.skillforge.assessment.entity.QuestionType;
import com.skillforge.course.dto.CreateCategoryRequest;
import com.skillforge.course.dto.CreateCourseRequest;
import com.skillforge.course.dto.CreateLessonRequest;
import com.skillforge.enrollment.dto.EnrollRequest;
import com.skillforge.enrollment.dto.UpdateProgressRequest;
import com.skillforge.learning.dto.BookmarkRequest;
import com.skillforge.learning.dto.NoteRequest;
import com.skillforge.playground.dto.PlaygroundRequest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.List;
import java.util.UUID;

import static org.hamcrest.Matchers.hasSize;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class LearningExperienceFlowsTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void testEndToEndLearningExperience() throws Exception {
        String instToken = authenticateAsUser("inst-p3-" + UUID.randomUUID(), "INSTRUCTOR");
        String studToken = authenticateAsUser("stud-p3-" + UUID.randomUUID(), "STUDENT");

        // 1. Setup Course Structure
        CreateCategoryRequest categoryReq = new CreateCategoryRequest("Software Design", "Design patterns and architectures");
        mockMvc.perform(post("/api/v1/categories")
                        .header("Authorization", instToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(categoryReq)))
                .andExpect(status().isOk());

        String courseId = createCourse(instToken, "System Design Basics", 99.99, "software-design");
        String sectionId = createSection(instToken, courseId, "Intro");

        CreateLessonRequest previewLesson = new CreateLessonRequest("What is System Design", "Overview of large scale systems", "http://videos.com/preview.mp4", null, 10, true, 1);
        CreateLessonRequest premiumLesson = new CreateLessonRequest("Load Balancing", "Gating details of load balancers", "http://videos.com/premium.mp4", "http://pdfs.com/notes.pdf", 30, false, 2);

        String lesson1Id = createLesson(instToken, courseId, sectionId, previewLesson);
        String lesson2Id = createLesson(instToken, courseId, sectionId, premiumLesson);

        // 2. Test course enrollment
        EnrollRequest enrollRequest = new EnrollRequest(UUID.fromString(courseId));
        MvcResult enrollResult = mockMvc.perform(post("/api/v1/enrollments")
                        .header("Authorization", studToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(enrollRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.progressPercent").value(0.0))
                .andExpect(jsonPath("$.data.completed").value(false))
                .andReturn();

        JsonNode enrollData = objectMapper.readTree(enrollResult.getResponse().getContentAsString()).path("data");
        String enrollmentId = enrollData.path("id").asText();

        // Check Course Enrolled Count Incremented
        mockMvc.perform(get("/api/v1/courses/{courseId}", courseId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.enrolledCount").value(1));

        // 3. Test Progress Gating Unlocked (Enrolled Student Detail View)
        // Since student is enrolled, they should see all videoUrl/pdfUrl populated (not null).
        MvcResult detailResultStudent = mockMvc.perform(get("/api/v1/courses/{courseId}", courseId)
                        .header("Authorization", studToken))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode studentData = objectMapper.readTree(detailResultStudent.getResponse().getContentAsString()).path("data");
        JsonNode studentLessons = studentData.path("sections").get(0).path("lessons");

        assertEquals(2, studentLessons.size());
        assertEquals("http://videos.com/preview.mp4", studentLessons.get(0).path("videoUrl").asText());
        assertEquals("http://videos.com/premium.mp4", studentLessons.get(1).path("videoUrl").asText());
        assertEquals("http://pdfs.com/notes.pdf", studentLessons.get(1).path("pdfUrl").asText());

        // 4. Update Lesson 1 Progress (50% Completion)
        UpdateProgressRequest progressReq1 = new UpdateProgressRequest(true, 600);
        mockMvc.perform(post("/api/v1/enrollments/{enrollmentId}/lessons/{lessonId}/progress", enrollmentId, lesson1Id)
                        .header("Authorization", studToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(progressReq1)))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/v1/enrollments")
                        .header("Authorization", studToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].progressPercent").value(50.0))
                .andExpect(jsonPath("$.data[0].completed").value(false));

        // 5. Update Lesson 2 Progress (100% Completion & Auto-Certificate Trigger)
        UpdateProgressRequest progressReq2 = new UpdateProgressRequest(true, 1800);
        mockMvc.perform(post("/api/v1/enrollments/{enrollmentId}/lessons/{lessonId}/progress", enrollmentId, lesson2Id)
                        .header("Authorization", studToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(progressReq2)))
                .andExpect(status().isOk());

        // Check Completion
        MvcResult enrollmentsCheck = mockMvc.perform(get("/api/v1/enrollments")
                        .header("Authorization", studToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].progressPercent").value(100.0))
                .andExpect(jsonPath("$.data[0].completed").value(true))
                .andReturn();

        // 6. Certificate Verification
        MvcResult certResult = mockMvc.perform(get("/api/v1/certificates/enrollments/{enrollmentId}", enrollmentId)
                        .header("Authorization", studToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.courseTitle").value("System Design Basics"))
                .andExpect(jsonPath("$.data.recipientName").value("Test User"))
                .andReturn();

        JsonNode certData = objectMapper.readTree(certResult.getResponse().getContentAsString()).path("data");
        String verificationCode = certData.path("verificationCode").asText();

        // Public Verify endpoint
        mockMvc.perform(get("/api/v1/certificates/verify/{verificationCode}", verificationCode))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.recipientName").value("Test User"));

        // 7. Notes and Bookmarks
        NoteRequest noteRequest = new NoteRequest(UUID.fromString(lesson1Id), "Review microservices", 120);
        MvcResult noteResult = mockMvc.perform(post("/api/v1/notes")
                        .header("Authorization", studToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(noteRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content").value("Review microservices"))
                .andReturn();

        String noteId = objectMapper.readTree(noteResult.getResponse().getContentAsString()).path("data").path("id").asText();

        // Update Note
        mockMvc.perform(put("/api/v1/notes/{noteId}", noteId)
                        .header("Authorization", studToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"content\":\"Updated note content\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content").value("Updated note content"));

        // Bookmarks
        BookmarkRequest bookmarkRequest = new BookmarkRequest(UUID.fromString(lesson1Id), "Important concept", 250);
        mockMvc.perform(post("/api/v1/bookmarks")
                        .header("Authorization", studToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(bookmarkRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.title").value("Important concept"));

        // 8. Assessments: Quiz Auto-grading
        QuizQuestionDto q1 = new QuizQuestionDto("What is a load balancer?", QuestionType.MCQ, List.of("A network device", "A database server", "An IDE"), 0, "Balances load");
        CreateAssessmentRequest quizRequest = new CreateAssessmentRequest(
                "Load Balancing Quiz",
                "Test your scaling knowledge",
                AssessmentType.QUIZ,
                UUID.fromString(lesson2Id),
                100,
                70,
                List.of(q1)
        );

        MvcResult quizCreateResult = mockMvc.perform(post("/api/v1/courses/{courseId}/assessments", courseId)
                        .header("Authorization", instToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(quizRequest)))
                .andExpect(status().isOk())
                .andReturn();

        String quizId = objectMapper.readTree(quizCreateResult.getResponse().getContentAsString()).path("data").path("id").asText();

        // Submit quiz choices (correct choice: 0)
        SubmissionRequest submissionRequest = new SubmissionRequest(List.of(0), null);
        mockMvc.perform(post("/api/v1/assessments/{assessmentId}/submissions", quizId)
                        .header("Authorization", studToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(submissionRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.score").value(100))
                .andExpect(jsonPath("$.data.passed").value(true));

        // 9. Playground execution (Java compilation)
        String playgroundCode = "public class Hello { public static void main(String[] args) { System.out.println(\"Hello Sandbox\"); } }";
        PlaygroundRequest playgroundRequest = new PlaygroundRequest("java", playgroundCode, null);
        mockMvc.perform(post("/api/v1/playground/run")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(playgroundRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.output").value("Hello Sandbox\n"));
    }

    private String authenticateAsUser(String email, String role) throws Exception {
        String cleanEmail = email.replace("-", "") + "@example.com";
        String registerPayload = "{\"fullName\":\"Test User\",\"email\":\"" + cleanEmail + "\",\"password\":\"Password123!\",\"role\":\"" + role + "\"}";
        MvcResult result = mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(registerPayload))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode response = objectMapper.readTree(result.getResponse().getContentAsString());
        return "Bearer " + response.path("data").path("accessToken").asText();
    }

    private String createCourse(String token, String title, double price, String categorySlug) throws Exception {
        CreateCourseRequest request = new CreateCourseRequest(
                title,
                "Description for " + title,
                price,
                15,
                "Advanced",
                categorySlug,
                "https://images.example.com/course.png",
                true
        );
        String payload = objectMapper.writeValueAsString(request);

        MvcResult result = mockMvc.perform(post("/api/v1/courses")
                        .header("Authorization", token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode response = objectMapper.readTree(result.getResponse().getContentAsString());
        return response.path("data").path("id").asText();
    }

    private String createSection(String token, String courseId, String title) throws Exception {
        String payload = "{\"title\":\"" + title + "\",\"description\":\"Section desc\"}";
        MvcResult result = mockMvc.perform(post("/api/v1/courses/{courseId}/sections", courseId)
                        .header("Authorization", token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode response = objectMapper.readTree(result.getResponse().getContentAsString());
        return response.path("data").path("id").asText();
    }

    private String createLesson(String token, String courseId, String sectionId, CreateLessonRequest request) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/v1/courses/{courseId}/sections/{sectionId}/lessons", courseId, sectionId)
                        .header("Authorization", token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode response = objectMapper.readTree(result.getResponse().getContentAsString());
        return response.path("data").path("id").asText();
    }
}
