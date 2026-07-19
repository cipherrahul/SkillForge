package com.skillforge.ai;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.skillforge.course.dto.*;
import com.skillforge.ai.dto.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.UUID;

import static org.hamcrest.Matchers.greaterThanOrEqualTo;
import static org.hamcrest.Matchers.hasSize;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class AiFeaturesIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void testAiTutorSessionsAndGenerators() throws Exception {
        String instEmail = "inst-p7-" + UUID.randomUUID() + "@example.com";
        String studEmail = "stud-p7-" + UUID.randomUUID() + "@example.com";

        String instToken = authenticateAsUser(instEmail, "INSTRUCTOR");
        String studToken = authenticateAsUser(studEmail, "STUDENT");

        // 1. Setup course & lesson
        CreateCategoryRequest categoryReq = new CreateCategoryRequest("Software Design", "Architecture methodologies");
        mockMvc.perform(post("/api/v1/categories")
                        .header("Authorization", instToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(categoryReq)))
                .andExpect(status().isOk());

        String courseId = createCourse(instToken, "Microservices Fundamentals", 49.99, "software-design");

        // Add section
        CreateSectionRequest sectionReq = new CreateSectionRequest("Spring Cloud Intro", "Introduction to cloud concepts");
        MvcResult sectionResult = mockMvc.perform(post("/api/v1/courses/{courseId}/sections", courseId)
                        .header("Authorization", instToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(sectionReq)))
                .andExpect(status().isOk())
                .andReturn();

        String sectionId = objectMapper.readTree(sectionResult.getResponse().getContentAsString()).path("data").path("id").asText();

        // Add lesson
        CreateLessonRequest lessonReq = new CreateLessonRequest(
                "Distributed Transactions",
                "Deep dive into Sagas and 2PC patterns",
                "https://storage.example.com/video.mp4",
                null,
                20,
                true,
                1
        );

        MvcResult lessonResult = mockMvc.perform(post("/api/v1/courses/{courseId}/sections/{sectionId}/lessons", courseId, sectionId)
                        .header("Authorization", instToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(lessonReq)))
                .andExpect(status().isOk())
                .andReturn();

        String lessonId = objectMapper.readTree(lessonResult.getResponse().getContentAsString()).path("data").path("id").asText();

        // 2. Chat Sessions Tutor & Doubt Solver
        StartAiSessionRequest sessionReq = new StartAiSessionRequest(UUID.fromString(lessonId), "DOUBT_SOLVER");
        MvcResult sessionResult = mockMvc.perform(post("/api/v1/ai/sessions")
                        .header("Authorization", studToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(sessionReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.type").value("DOUBT_SOLVER"))
                .andReturn();

        String sessionId = objectMapper.readTree(sessionResult.getResponse().getContentAsString()).path("data").path("id").asText();

        // Send user message
        SendMessageRequest msgReq = new SendMessageRequest("How does @Transactional propagation handle exceptions?");
        mockMvc.perform(post("/api/v1/ai/sessions/{sessionId}/messages", sessionId)
                        .header("Authorization", studToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(msgReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(2))) // User message + AI response
                .andExpect(jsonPath("$.data[1].sender").value("AI"))
                .andExpect(jsonPath("$.data[1].message").value(org.hamcrest.Matchers.containsString("rollbackFor")));

        // Check history
        mockMvc.perform(get("/api/v1/ai/sessions/{sessionId}/history", sessionId)
                        .header("Authorization", studToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(2)));

        // 3. Quiz & Notes Generators
        mockMvc.perform(post("/api/v1/ai/lessons/{lessonId}/generate-quiz", lessonId)
                        .header("Authorization", instToken))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/v1/ai/lessons/{lessonId}/generate-notes", lessonId)
                        .header("Authorization", studToken))
                .andExpect(status().isOk());

        // 4. Learning Roadmap generator
        GenerateRoadmapRequest roadmapReq = new GenerateRoadmapRequest("Java Microservices");
        mockMvc.perform(post("/api/v1/ai/roadmap")
                        .header("Authorization", studToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(roadmapReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.topic").value("Java Microservices"))
                .andExpect(jsonPath("$.data.roadmapJson").exists());

        // 5. Course Recommendations check (assert it recommends courses user is not enrolled in)
        mockMvc.perform(get("/api/v1/ai/recommendations")
                        .header("Authorization", studToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(greaterThanOrEqualTo(1))))
                .andExpect(jsonPath("$.data[0].id").value(courseId));
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
