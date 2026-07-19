package com.skillforge.mobile;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.skillforge.course.dto.*;
import com.skillforge.mobile.dto.*;
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
class MobileIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void testMobileDevicesSyncAndPushesFlows() throws Exception {
        String instEmail = "inst-p11-" + UUID.randomUUID() + "@example.com";
        String studEmail = "stud-p11-" + UUID.randomUUID() + "@example.com";

        String instToken = authenticateAsUser(instEmail, "INSTRUCTOR");
        String studToken = authenticateAsUser(studEmail, "STUDENT");

        // 1. Setup Course & Lesson
        CreateCategoryRequest categoryReq = new CreateCategoryRequest("Mobile Tech", "Native app frameworks");
        mockMvc.perform(post("/api/v1/categories")
                        .header("Authorization", instToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(categoryReq)))
                .andExpect(status().isOk());

        String courseId = createCourse(instToken, "SwiftUI Essentials", 59.99, "mobile-tech");

        // Add Section & Lesson
        CreateSectionRequest sectionReq = new CreateSectionRequest("Layouts and Views", "Stacks and Spacer controls");
        MvcResult sectionResult = mockMvc.perform(post("/api/v1/courses/{courseId}/sections", courseId)
                        .header("Authorization", instToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(sectionReq)))
                .andExpect(status().isOk())
                .andReturn();

        String sectionId = objectMapper.readTree(sectionResult.getResponse().getContentAsString()).path("data").path("id").asText();

        CreateLessonRequest lessonReq = new CreateLessonRequest(
                "Grid Containers",
                "How to construct LazyVGrid components",
                "https://storage.example.com/swiftui_grid.mp4",
                null,
                15,
                true,
                1
        );

        mockMvc.perform(post("/api/v1/courses/{courseId}/sections/{sectionId}/lessons", courseId, sectionId)
                        .header("Authorization", instToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(lessonReq)))
                .andExpect(status().isOk());

        // Enroll Student
        mockMvc.perform(post("/api/v1/courses/{courseId}/enroll", courseId)
                        .header("Authorization", studToken))
                .andExpect(status().isOk());

        // 2. Register Mobile Device Token
        RegisterDeviceRequest deviceReq = new RegisterDeviceRequest("FCM_TOKEN_STUDENT_123", "ANDROID");
        mockMvc.perform(post("/api/v1/mobile/devices")
                        .header("Authorization", studToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(deviceReq)))
                .andExpect(status().isOk());

        // 3. Verify Student Mobile Dashboard
        mockMvc.perform(get("/api/v1/mobile/student/dashboard")
                        .header("Authorization", studToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.enrolledCourses", hasSize(1)))
                .andExpect(jsonPath("$.data.enrolledCourses[0]").value("SwiftUI Essentials"))
                .andExpect(jsonPath("$.data.statsXp").value(0));

        // 4. Verify Instructor Mobile Dashboard
        mockMvc.perform(get("/api/v1/mobile/instructor/dashboard")
                        .header("Authorization", instToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalCoursesCreated").value(1))
                .andExpect(jsonPath("$.data.activeStudentsCount").value(1));

        // 5. Verify Offline manifest downloads package
        mockMvc.perform(get("/api/v1/mobile/courses/{courseId}/offline-manifest", courseId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.downloads", hasSize(1)))
                .andExpect(jsonPath("$.data.downloads[0].title").value("Grid Containers"))
                .andExpect(jsonPath("$.data.downloads[0].downloadUrl").value("https://storage.example.com/swiftui_grid.mp4"));

        // 6. Push Simulation Test
        SendTestPushRequest pushReq = new SendTestPushRequest(
                "SwiftUI Doubt Session starting!",
                "Check out the link on chat box to join room",
                studEmail
        );

        mockMvc.perform(post("/api/v1/mobile/notifications/test")
                        .header("Authorization", instToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(pushReq)))
                .andExpect(status().isOk());

        // Verify push logged in histories
        mockMvc.perform(get("/api/v1/mobile/notifications")
                        .header("Authorization", studToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(1)))
                .andExpect(jsonPath("$.data[0].title").value("SwiftUI Doubt Session starting!"))
                .andExpect(jsonPath("$.data[0].body").value("Check out the link on chat box to join room"));

        // Deregister token
        mockMvc.perform(delete("/api/v1/mobile/devices/{deviceToken}", "FCM_TOKEN_STUDENT_123")
                        .header("Authorization", studToken))
                .andExpect(status().isOk());
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
