package com.skillforge.course;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.skillforge.course.dto.CreateCategoryRequest;
import com.skillforge.course.dto.CreateCourseRequest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class CourseControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void createCategoryShouldSucceed() throws Exception {
        String token = authenticateAsInstructor("category-owner-" + UUID.randomUUID());
        CreateCategoryRequest request = new CreateCategoryRequest("Programming", "Learn coding");
        String payload = objectMapper.writeValueAsString(request);

        mockMvc.perform(post("/api/v1/categories")
                        .header("Authorization", token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void createCourseShouldSucceed() throws Exception {
        String token = authenticateAsInstructor("course-owner-" + UUID.randomUUID());
        CreateCourseRequest request = new CreateCourseRequest(
                "Spring Boot Mastery",
                "Build modern applications",
                199.99,
                20,
                "Intermediate",
                "programming",
                "https://images.example.com/course.png",
                true
        );
        String payload = objectMapper.writeValueAsString(request);

        mockMvc.perform(post("/api/v1/courses")
                        .header("Authorization", token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void createSectionShouldSucceedForAuthenticatedInstructor() throws Exception {
        String token = authenticateAsInstructor("section-owner-" + UUID.randomUUID());
        String courseId = createCourse(token, "Section Course");

        String payload = "{\"title\":\"Introduction\",\"description\":\"Start here\"}";

        mockMvc.perform(post("/api/v1/courses/{courseId}/sections", courseId)
                        .header("Authorization", token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void listCoursesShouldReturnOk() throws Exception {
        mockMvc.perform(get("/api/v1/courses"))
                .andExpect(status().isOk());
    }

    private String authenticateAsInstructor(String email) throws Exception {
        String registerPayload = "{\"fullName\":\"Instructor\",\"email\":\"" + email.replace("-", "") + "@example.com\",\"password\":\"Password123!\",\"role\":\"INSTRUCTOR\"}";
        MvcResult result = mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(registerPayload))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode response = objectMapper.readTree(result.getResponse().getContentAsString());
        return "Bearer " + response.path("data").path("accessToken").asText();
    }

    private String createCourse(String token, String title) throws Exception {
        String payload = objectMapper.writeValueAsString(new CreateCourseRequest(
                title,
                "Build modern applications",
                199.99,
                20,
                "Intermediate",
                "programming",
                "https://images.example.com/course.png",
                true
        ));

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
