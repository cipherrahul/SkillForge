package com.skillforge.career;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.skillforge.career.dto.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.time.Instant;
import java.util.UUID;

import static org.hamcrest.Matchers.greaterThanOrEqualTo;
import static org.hamcrest.Matchers.hasSize;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class CareerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void testRecruitmentAndMockInterviewsFlows() throws Exception {
        String recEmail = "rec-p8-" + UUID.randomUUID() + "@example.com";
        String studEmail = "stud-p8-" + UUID.randomUUID() + "@example.com";

        String recToken = authenticateAsUser(recEmail, "INSTRUCTOR"); // Instructor/Recruiter
        String studToken = authenticateAsUser(studEmail, "STUDENT");

        // 1. Create Internship listing
        CreateJobRequest jobReq = new CreateJobRequest(
                "Backend Engineer Intern",
                "SkillForge Systems",
                "Remote",
                "INTERNSHIP",
                "Looking for Java/Spring Boot enthusiasts.",
                "Java core, SQL",
                "1500-2000 USD/Month"
        );

        MvcResult jobResult = mockMvc.perform(post("/api/v1/jobs")
                        .header("Authorization", recToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(jobReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.title").value("Backend Engineer Intern"))
                .andExpect(jsonPath("$.data.type").value("INTERNSHIP"))
                .andReturn();

        String jobId = objectMapper.readTree(jobResult.getResponse().getContentAsString()).path("data").path("id").asText();

        // 2. Build Student Resume
        BuildResumeRequest resumeReq = new BuildResumeRequest(
                "Jane Doe",
                "B.S. in Computer Science",
                "Freelance Web Developer",
                "Java, Spring Boot, PostgreSQL, Docker",
                "SkillForge Learning System"
        );

        mockMvc.perform(post("/api/v1/resumes")
                        .header("Authorization", studToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(resumeReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").value(org.hamcrest.Matchers.containsString("resume_")));

        // 3. Student applies for the internship
        ApplyJobRequest applyReq = new ApplyJobRequest("I have extensive project history using Spring Boot backend setups.");
        MvcResult applyResult = mockMvc.perform(post("/api/v1/jobs/{jobId}/apply", jobId)
                        .header("Authorization", studToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(applyReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("SUBMITTED"))
                .andReturn();

        String applicationId = objectMapper.readTree(applyResult.getResponse().getContentAsString()).path("data").path("id").asText();

        // 4. Recruiter reviews and shortlists the application
        mockMvc.perform(put("/api/v1/jobs/applications/{applicationId}/status", applicationId)
                        .header("Authorization", recToken)
                        .param("status", "SHORTLISTED"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("SHORTLISTED"));

        // Verify application displays shortlisted in listings
        mockMvc.perform(get("/api/v1/jobs/applications")
                        .header("Authorization", recToken)
                        .param("jobId", jobId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].status").value("SHORTLISTED"));

        // 5. Book and Grade Mock Interview
        BookInterviewRequest bookReq = new BookInterviewRequest("Java Systems Design", Instant.now().plusSeconds(7200));
        MvcResult bookResult = mockMvc.perform(post("/api/v1/mock-interviews")
                        .header("Authorization", studToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(bookReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("SCHEDULED"))
                .andReturn();

        String interviewId = objectMapper.readTree(bookResult.getResponse().getContentAsString()).path("data").path("id").asText();

        // Submit grading feedback
        SubmitFeedbackRequest feedbackReq = new SubmitFeedbackRequest("Excellent understanding of microservice caching topologies.", 92);
        mockMvc.perform(post("/api/v1/mock-interviews/{interviewId}/feedback", interviewId)
                        .header("Authorization", recToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(feedbackReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("COMPLETED"))
                .andExpect(jsonPath("$.data.score").value(92));

        // 6. Recruitment dashboard analytics check
        mockMvc.perform(get("/api/v1/career/analytics")
                        .header("Authorization", recToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalInternships").value(1))
                .andExpect(jsonPath("$.data.totalApplications").value(1))
                .andExpect(jsonPath("$.data.totalShortlisted").value(1))
                .andExpect(jsonPath("$.data.placementRatePercent").value(100.0));
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
}
