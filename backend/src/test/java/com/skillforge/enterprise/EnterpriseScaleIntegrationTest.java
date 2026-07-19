package com.skillforge.enterprise;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.skillforge.enterprise.dto.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.UUID;

import static org.hamcrest.Matchers.greaterThan;
import static org.hamcrest.Matchers.hasSize;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class EnterpriseScaleIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void testEnterpriseHealthMetricsAndCdnResolvers() throws Exception {
        String adminEmail = "admin-p12-" + UUID.randomUUID() + "@example.com";
        String adminToken = authenticateAsUser(adminEmail, "INSTRUCTOR");

        // 1. Write Critical Security Audit Log
        LogSystemEventRequest logReq = new LogSystemEventRequest(
                "SECURITY",
                "CRITICAL",
                "Rate limit threshold overflow triggers auto firewall block"
        );

        mockMvc.perform(post("/api/v1/enterprise/audit-logs")
                        .header("Authorization", adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(logReq)))
                .andExpect(status().isOk());

        // List security logs
        mockMvc.perform(get("/api/v1/enterprise/audit-logs")
                        .header("Authorization", adminToken)
                        .param("severity", "CRITICAL"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(greaterThan(0))));

        // 2. Perform Deep Health Check (Verify DB and local storage reads write latency)
        mockMvc.perform(get("/api/v1/enterprise/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("UP"))
                .andExpect(jsonPath("$.data.dbLatencyMs").exists())
                .andExpect(jsonPath("$.data.storageLatencyMs").exists());

        // 3. Perform JVM Heap metrics load check
        mockMvc.perform(get("/api/v1/enterprise/metrics"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalHeapMemoryMb").value(greaterThan(0)))
                .andExpect(jsonPath("$.data.activeThreadsCount").value(greaterThan(0)));

        // 4. Resolve CDN geographic routing edge (India client -> ap-east edge Mumbai)
        CdnResolveRequest cdnReqIn = new CdnResolveRequest("https://storage.skillforge.com/uploads/video.mp4", "IN");
        mockMvc.perform(post("/api/v1/enterprise/cdn/resolve")
                        .header("Authorization", adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(cdnReqIn)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.resolvedCdnUrl").value("https://ap-east.cdn.skillforge.com/uploads/video.mp4"))
                .andExpect(jsonPath("$.data.routedEdgeLocation").value("APAC-MUMBAI-EDGE"));

        // Resolve CDN geographic routing edge (France client -> eu-west edge Frankfurt)
        CdnResolveRequest cdnReqFr = new CdnResolveRequest("https://storage.skillforge.com/uploads/video.mp4", "FR");
        mockMvc.perform(post("/api/v1/enterprise/cdn/resolve")
                        .header("Authorization", adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(cdnReqFr)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.resolvedCdnUrl").value("https://eu-west.cdn.skillforge.com/uploads/video.mp4"))
                .andExpect(jsonPath("$.data.routedEdgeLocation").value("EU-FRANKFURT-EDGE"));
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
