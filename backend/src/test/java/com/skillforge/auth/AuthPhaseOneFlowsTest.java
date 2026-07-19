package com.skillforge.auth;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.skillforge.auth.dto.OtpLoginRequest;
import com.skillforge.auth.dto.OtpRequest;
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
class AuthPhaseOneFlowsTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void otpRequestShouldSucceed() throws Exception {
        OtpRequest request = new OtpRequest("student@example.com");
        byte[] body = objectMapper.writeValueAsString(request).getBytes();

        mockMvc.perform(post("/api/v1/auth/otp/request")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk());
    }

    @Test
    void otpLoginShouldSucceedWhenCodeIsValid() throws Exception {
        OtpLoginRequest request = new OtpLoginRequest("student@example.com", "123456");
        byte[] body = objectMapper.writeValueAsString(request).getBytes();

        mockMvc.perform(post("/api/v1/auth/otp/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk());
    }
}
