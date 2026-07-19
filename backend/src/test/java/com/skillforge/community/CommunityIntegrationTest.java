package com.skillforge.community;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.skillforge.community.dto.*;
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
class CommunityIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void testForumAndGamificationFlows() throws Exception {
        String studentEmail = "stud-p5-" + UUID.randomUUID() + "@example.com";
        String helperEmail = "helper-p5-" + UUID.randomUUID() + "@example.com";

        String studentToken = authenticateAsUser(studentEmail, "STUDENT");
        String helperToken = authenticateAsUser(helperEmail, "STUDENT");

        // 1. Create Forum Post (isQuestion = true)
        CreatePostRequest postRequest = new CreatePostRequest(
                null, // General post
                "Spring Boot transaction management issue",
                "How does @Transactional propagate exceptions?",
                true, // Question
                "PROGRAMMING"
        );

        MvcResult postResult = mockMvc.perform(post("/api/v1/forum/posts")
                        .header("Authorization", studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(postRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.title").value("Spring Boot transaction management issue"))
                .andExpect(jsonPath("$.data.isQuestion").value(true))
                .andExpect(jsonPath("$.data.resolved").value(false))
                .andReturn();

        String postId = objectMapper.readTree(postResult.getResponse().getContentAsString()).path("data").path("id").asText();

        // 2. Helper comments on the post (answers the question)
        CreateCommentRequest commentRequest = new CreateCommentRequest(
                "RuntimeExceptions trigger rollbacks by default; checked exceptions do not."
        );

        MvcResult commentResult = mockMvc.perform(post("/api/v1/forum/posts/{postId}/comments", postId)
                        .header("Authorization", helperToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(commentRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content").value("RuntimeExceptions trigger rollbacks by default; checked exceptions do not."))
                .andExpect(jsonPath("$.data.isAnswer").value(false))
                .andReturn();

        String commentId = objectMapper.readTree(commentResult.getResponse().getContentAsString()).path("data").path("id").asText();

        // 3. Post creator accepts the answer
        mockMvc.perform(put("/api/v1/forum/comments/{commentId}/accept", commentId)
                        .header("Authorization", studentToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.isAnswer").value(true));

        // Check if post details show resolved
        mockMvc.perform(get("/api/v1/forum/posts/{postId}", postId)
                        .header("Authorization", studentToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.resolved").value(true))
                .andExpect(jsonPath("$.data.comments", hasSize(1)))
                .andExpect(jsonPath("$.data.comments[0].isAnswer").value(true));

        // 4. Student Groups flow
        CreateGroupRequest groupReq = new CreateGroupRequest("Spring Fans", "Discussion for Spring ecosystem");
        MvcResult groupResult = mockMvc.perform(post("/api/v1/groups")
                        .header("Authorization", studentToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(groupReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("Spring Fans"))
                .andExpect(jsonPath("$.data.memberCount").value(0))
                .andReturn();

        String groupId = objectMapper.readTree(groupResult.getResponse().getContentAsString()).path("data").path("id").asText();

        // Join group
        mockMvc.perform(post("/api/v1/groups/{groupId}/join", groupId)
                        .header("Authorization", studentToken))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/v1/groups")
                        .header("Authorization", studentToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].memberCount").value(1));

        // 5. Verify Gamification (Leaderboard rankings & Achievements)
        // Student created post (+15 XP)
        // Helper replied (+5 XP) and got accepted answer (+30 XP) = 35 XP
        MvcResult leaderboardResult = mockMvc.perform(get("/api/v1/leaderboard")
                        .header("Authorization", studentToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(greaterThanOrEqualTo(2))))
                .andReturn();

        JsonNode lbData = objectMapper.readTree(leaderboardResult.getResponse().getContentAsString()).path("data");
        // Helper should be higher XP or student should have stats recorded
        boolean studentXpFound = false;
        for (JsonNode row : lbData) {
            if (row.path("userEmail").asText().equalsIgnoreCase(studentEmail)) {
                studentXpFound = true;
                assertEquals(15, row.path("xpPoints").asInt());
            }
        }
        assertTrue(studentXpFound);

        // Verify Achievements logged for student
        mockMvc.perform(get("/api/v1/achievements")
                        .header("Authorization", studentToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].title").value("First Discussion"));
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
