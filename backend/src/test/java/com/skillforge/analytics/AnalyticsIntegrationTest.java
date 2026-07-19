package com.skillforge.analytics;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.skillforge.course.dto.*;
import com.skillforge.analytics.dto.*;
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
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class AnalyticsIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void testLogsEngagementAndCsvReportExports() throws Exception {
        String instEmail = "inst-p10-" + UUID.randomUUID() + "@example.com";
        String studEmail = "stud-p10-" + UUID.randomUUID() + "@example.com";

        String instToken = authenticateAsUser(instEmail, "INSTRUCTOR");
        String studToken = authenticateAsUser(studEmail, "STUDENT");

        // 1. Setup course
        CreateCategoryRequest categoryReq = new CreateCategoryRequest("Cloud Networking", "Router configurations");
        mockMvc.perform(post("/api/v1/categories")
                        .header("Authorization", instToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(categoryReq)))
                .andExpect(status().isOk());

        String courseId = createCourse(instToken, "AWS VPC Core Architecture", 19.99, "cloud-networking");

        // 2. Log Student Activity
        LogActivityRequest activityReq = new LogActivityRequest("WATCH_LESSON", 45);
        mockMvc.perform(post("/api/v1/analytics/logs")
                        .header("Authorization", studToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(activityReq)))
                .andExpect(status().isOk());

        // 3. Verify Student Cohort stats
        mockMvc.perform(get("/api/v1/analytics/students")
                        .header("Authorization", instToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.activeStudentsLast30Days").value(1));

        // 4. Verify Platform KPIs
        mockMvc.perform(get("/api/v1/analytics/kpis")
                        .header("Authorization", instToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.studentEngagementHours").value(0.75)); // 45 / 60 = 0.75 hrs

        // 5. Verify Course performance
        mockMvc.perform(get("/api/v1/analytics/courses/{courseId}", courseId)
                        .header("Authorization", instToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.title").value("AWS VPC Core Architecture"))
                .andExpect(jsonPath("$.data.enrolledCount").value(0))
                .andExpect(jsonPath("$.data.revenueGenerated").value(0.0));

        // 6. Verify export CSV endpoint
        mockMvc.perform(get("/api/v1/analytics/reports/export")
                        .header("Authorization", instToken))
                .andExpect(status().isOk())
                .andExpect(content().contentType("text/csv; charset=UTF-8"))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("Course ID,Course Title,Enrolled Count")));
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
