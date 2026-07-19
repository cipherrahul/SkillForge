package com.skillforge.storage;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class StorageControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void testUploadAndRetrievePdf() throws Exception {
        MockMultipartFile mockFile = new MockMultipartFile(
                "file",
                "syllabus.pdf",
                "application/pdf",
                "Mock PDF content".getBytes()
        );

        MvcResult result = mockMvc.perform(multipart("/api/v1/storage/upload")
                        .file(mockFile))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode response = objectMapper.readTree(result.getResponse().getContentAsString());
        String fileUrl = response.path("data").asText();
        assertNotNull(fileUrl);

        // Fetch back the uploaded file
        mockMvc.perform(get(fileUrl))
                .andExpect(status().isOk())
                .andExpect(header().string("Content-Type", "application/pdf"));
    }

    @Test
    void testUploadAndRetrieveVideo() throws Exception {
        MockMultipartFile mockFile = new MockMultipartFile(
                "file",
                "intro.mp4",
                "video/mp4",
                "Mock MP4 video content".getBytes()
        );

        MvcResult result = mockMvc.perform(multipart("/api/v1/storage/upload")
                        .file(mockFile))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode response = objectMapper.readTree(result.getResponse().getContentAsString());
        String fileUrl = response.path("data").asText();
        assertNotNull(fileUrl);

        // Fetch back the uploaded file
        mockMvc.perform(get(fileUrl))
                .andExpect(status().isOk())
                .andExpect(header().string("Content-Type", "video/mp4"));
    }
}
