package com.skillforge.auth;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.skillforge.auth.dto.RegisterRequest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void registerUserShouldSucceed() throws Exception {
        RegisterRequest request = new RegisterRequest("Test User", "test@example.com", "password123", "STUDENT");

        String requestJson = objectMapper.writeValueAsString(request);
        byte[] requestPayload = requestJson.getBytes();
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestPayload))
                .andExpect(status().isOk());
    }

    @Test
    void otpRequestShouldSucceed() throws Exception {
        String requestJson = "{\"email\":\"otp@example.com\"}";

        mockMvc.perform(post("/api/v1/auth/otp/request")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestJson))
                .andExpect(status().isOk());
    }

    @Test
    void googleLoginShouldSucceed() throws Exception {
        String requestJson = "{\"email\":\"google@example.com\",\"fullName\":\"Google User\"}";

        mockMvc.perform(post("/api/v1/auth/google/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestJson))
                .andExpect(status().isOk());
    }

    @Test
    void passwordResetFlowShouldSucceed() throws Exception {
        String requestJson = "{\"email\":\"reset@example.com\"}";

        String resetResponse = mockMvc.perform(post("/api/v1/auth/password/reset")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestJson))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();

        JsonNode responseNode = objectMapper.readTree(resetResponse);
        String token = responseNode.get("data").asText();

        String confirmJson = "{\"email\":\"reset@example.com\",\"token\":\"" + token + "\",\"newPassword\":\"newpassword123\"}";
        mockMvc.perform(post("/api/v1/auth/password/reset/confirm")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(confirmJson))
                .andExpect(status().isOk());
    }
}
