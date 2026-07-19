package com.skillforge.liveclass;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.skillforge.course.dto.CreateCategoryRequest;
import com.skillforge.course.dto.CreateCourseRequest;
import com.skillforge.enrollment.dto.EnrollRequest;
import com.skillforge.liveclass.dto.BookMentoringRequest;
import com.skillforge.liveclass.dto.PostChatMessageRequest;
import com.skillforge.liveclass.dto.ScheduleSessionRequest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.time.Instant;
import java.util.UUID;

import static org.hamcrest.Matchers.containsString;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class LiveLearningIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void testLiveLearningAndMentoringFlow() throws Exception {
        String instEmail = "inst-p4-" + UUID.randomUUID() + "@example.com";
        String studEmail = "stud-p4-" + UUID.randomUUID() + "@example.com";

        String instToken = authenticateAsUser(instEmail, "INSTRUCTOR");
        String studToken = authenticateAsUser(studEmail, "STUDENT");

        // 1. Setup course
        CreateCategoryRequest categoryReq = new CreateCategoryRequest("Cloud Architecture", "Scale and design");
        mockMvc.perform(post("/api/v1/categories")
                        .header("Authorization", instToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(categoryReq)))
                .andExpect(status().isOk());

        String courseId = createCourse(instToken, "AWS Masterclass", 149.99, "cloud-architecture");

        // Enroll Student
        EnrollRequest enrollRequest = new EnrollRequest(UUID.fromString(courseId));
        mockMvc.perform(post("/api/v1/enrollments")
                        .header("Authorization", studToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(enrollRequest)))
                .andExpect(status().isOk());

        // 2. Schedule Live Session
        Instant startTime = Instant.now().plusSeconds(3600); // 1 hour later
        Instant endTime = startTime.plusSeconds(3600); // 2 hours later
        ScheduleSessionRequest scheduleRequest = new ScheduleSessionRequest(
                "Kubernetes scaling live class",
                "Deep dive into HPA",
                startTime,
                endTime,
                "LIVE_CLASS"
        );

        MvcResult sessionResult = mockMvc.perform(post("/api/v1/courses/{courseId}/live-sessions", courseId)
                        .header("Authorization", instToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(scheduleRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.title").value("Kubernetes scaling live class"))
                .andExpect(jsonPath("$.data.meetingUrl").exists())
                .andReturn();

        String sessionId = objectMapper.readTree(sessionResult.getResponse().getContentAsString()).path("data").path("id").asText();

        // 3. Join / Leave live session (Attendance tracking)
        mockMvc.perform(post("/api/v1/live-sessions/{sessionId}/join", sessionId)
                        .header("Authorization", studToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.joinedAt").exists());

        mockMvc.perform(post("/api/v1/live-sessions/{sessionId}/leave", sessionId)
                        .header("Authorization", studToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.leftAt").exists())
                .andExpect(jsonPath("$.data.durationMinutes").exists());

        // 4. Live Chat message log
        PostChatMessageRequest chatReq = new PostChatMessageRequest("How to configure CPU triggers?");
        mockMvc.perform(post("/api/v1/live-sessions/{sessionId}/chat", sessionId)
                        .header("Authorization", studToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(chatReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.message").value("How to configure CPU triggers?"));

        mockMvc.perform(get("/api/v1/live-sessions/{sessionId}/chat", sessionId)
                        .header("Authorization", studToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].message").value("How to configure CPU triggers?"))
                .andExpect(jsonPath("$.data[0].senderName").value("Test User"));

        // 5. Book mentoring slot (Student booking with instructor)
        BookMentoringRequest bookingReq = new BookMentoringRequest(
                instEmail,
                "AWS Resume review",
                "Review resume formatting for DevOps roles",
                Instant.now().plusSeconds(7200),
                Instant.now().plusSeconds(9000)
        );

        MvcResult mentoringResult = mockMvc.perform(post("/api/v1/mentoring/book")
                        .header("Authorization", studToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(bookingReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.title").value("AWS Resume review"))
                .andExpect(jsonPath("$.data.status").value("REQUESTED"))
                .andReturn();

        String mentoringSessionId = objectMapper.readTree(mentoringResult.getResponse().getContentAsString()).path("data").path("id").asText();

        // Instructor accepts mentoring booking
        mockMvc.perform(put("/api/v1/mentoring/{sessionId}/status", mentoringSessionId)
                        .header("Authorization", instToken)
                        .param("status", "CONFIRMED"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("CONFIRMED"));

        // 6. Export Calendar (iCal format verification)
        MvcResult calendarResult = mockMvc.perform(get("/api/v1/calendar/export")
                        .header("Authorization", studToken))
                .andExpect(status().isOk())
                .andExpect(content().contentType("text/calendar;charset=UTF-8"))
                .andExpect(content().string(containsString("BEGIN:VCALENDAR")))
                .andExpect(content().string(containsString("SUMMARY:Kubernetes scaling live class")))
                .andExpect(content().string(containsString("SUMMARY:Mentoring: AWS Resume review")))
                .andExpect(content().string(containsString("END:VCALENDAR")))
                .andReturn();

        String icalText = calendarResult.getResponse().getContentAsString();
        assertNotNull(icalText);
        assertTrue(icalText.contains("BEGIN:VEVENT"));
    }

    private String authenticateAsUser(String email, String role) throws Exception {
        String registerPayload = "{\"fullName\":\"Test User\",\"email\":\"" + email + "\",\"password\":\"Password123!\",\"role\":\"" + role + "\"}";
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
}
