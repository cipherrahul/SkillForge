package com.skillforge.auth;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.skillforge.auth.dto.LoginRequest;
import com.skillforge.auth.dto.RegisterRequest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class AuthRefreshFlowTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void refreshTokenShouldSucceed() throws Exception {
        RegisterRequest registerRequest = new RegisterRequest("Refresh User", "refresh@example.com", "password123", "STUDENT");
        String registerJson = objectMapper.writeValueAsString(registerRequest);
        byte[] registerPayload = registerJson.getBytes();
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(registerPayload))
                .andExpect(status().isOk());

        LoginRequest loginRequest = new LoginRequest("refresh@example.com", "password123");
        String loginJson = objectMapper.writeValueAsString(loginRequest);
        byte[] loginPayload = loginJson.getBytes();
        String responseBody = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginPayload))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();

        JsonNode dataNode = objectMapper.readTree(responseBody).get("data");
        String refreshToken = dataNode.get("refreshToken").asText();

        String refreshJson = objectMapper.writeValueAsString(new com.skillforge.auth.dto.RefreshTokenRequest(refreshToken));
        byte[] refreshPayload = refreshJson.getBytes();
        mockMvc.perform(post("/api/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(refreshPayload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }
}
