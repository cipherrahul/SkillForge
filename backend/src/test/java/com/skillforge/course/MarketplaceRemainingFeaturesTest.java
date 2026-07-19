package com.skillforge.course;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.skillforge.course.dto.CreateCategoryRequest;
import com.skillforge.course.dto.CreateCourseRequest;
import com.skillforge.course.dto.CreateLessonRequest;
import com.skillforge.course.dto.WishlistRequest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.UUID;

import static org.hamcrest.Matchers.hasSize;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class MarketplaceRemainingFeaturesTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void testCategoriesListAndCourseWorkflow() throws Exception {
        String token = authenticateAsInstructor("market-inst-" + UUID.randomUUID());

        // 1. Create a category
        CreateCategoryRequest categoryReq = new CreateCategoryRequest("Backend Tech", "All things backend");
        mockMvc.perform(post("/api/v1/categories")
                        .header("Authorization", token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(categoryReq)))
                .andExpect(status().isOk());

        // 2. Get list of categories
        mockMvc.perform(get("/api/v1/categories"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data").isArray());

        // 3. Create a course
        String courseId = createCourse(token, "Advanced Java", 250.00, "Advanced", "backend-tech");

        // 4. Create a section
        String sectionId = createSection(token, courseId, "Concurrency");

        // 5. Create lessons (one preview, one premium)
        CreateLessonRequest previewLesson = new CreateLessonRequest("Threads Intro", "Introductory thread concepts", "http://videos.com/intro.mp4", "http://pdfs.com/intro.pdf", 10, true, 1);
        CreateLessonRequest premiumLesson = new CreateLessonRequest("ForkJoinPool", "Advanced parallel streams", "http://videos.com/premium.mp4", "http://pdfs.com/premium.pdf", 45, false, 2);

        String prevLessonId = createLesson(token, courseId, sectionId, previewLesson);
        String premLessonId = createLesson(token, courseId, sectionId, premiumLesson);

        // 6. Test Course Preview Boundary (Unauthenticated User Detail View)
        // For unauthenticated request (no header), preview lesson should have URLs, premium should have null URLs.
        MvcResult detailResultPublic = mockMvc.perform(get("/api/v1/courses/{courseId}", courseId))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode publicData = objectMapper.readTree(detailResultPublic.getResponse().getContentAsString()).path("data");
        JsonNode publicLessons = publicData.path("sections").get(0).path("lessons");

        assertEquals(2, publicLessons.size());
        // Preview lesson (Threads Intro)
        assertEquals("Threads Intro", publicLessons.get(0).path("title").asText());
        assertEquals("http://videos.com/intro.mp4", publicLessons.get(0).path("videoUrl").asText());
        // Premium lesson (ForkJoinPool)
        assertEquals("ForkJoinPool", publicLessons.get(1).path("title").asText());
        assertTrue(publicLessons.get(1).path("videoUrl").isNull());

        // 7. Update lesson
        CreateLessonRequest updateReq = new CreateLessonRequest("Threads Intro v2", "Updated intro", "http://videos.com/intro_v2.mp4", null, 15, true, 1);
        mockMvc.perform(put("/api/v1/courses/{courseId}/sections/{sectionId}/lessons/{lessonId}", courseId, sectionId, prevLessonId)
                        .header("Authorization", token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.title").value("Threads Intro v2"));

        // 8. Delete lesson
        mockMvc.perform(delete("/api/v1/courses/{courseId}/sections/{sectionId}/lessons/{lessonId}", courseId, sectionId, premLessonId)
                        .header("Authorization", token))
                .andExpect(status().isOk());

        // Verify lesson was removed
        mockMvc.perform(get("/api/v1/courses/{courseId}", courseId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.sections[0].lessons", hasSize(1)));
    }

    @Test
    void testReviewsAndRatings() throws Exception {
        String instToken = authenticateAsInstructor("reviews-inst-" + UUID.randomUUID());
        String studToken = authenticateAsStudent("reviews-stud-" + UUID.randomUUID());

        // Create course
        String courseId = createCourse(instToken, "Java OOP", 50.00, "Beginner", "programming");

        // Add review
        String reviewPayload = "{\"rating\":5,\"comment\":\"Superb course!\"}";
        mockMvc.perform(post("/api/v1/courses/{courseId}/reviews", courseId)
                        .header("Authorization", studToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(reviewPayload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.rating").value(5))
                .andExpect(jsonPath("$.data.comment").value("Superb course!"));

        // Check reviews list
        mockMvc.perform(get("/api/v1/courses/{courseId}/reviews", courseId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(1)));

        // Verify course stats updated
        mockMvc.perform(get("/api/v1/courses/{courseId}", courseId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.averageRating").value(5.0))
                .andExpect(jsonPath("$.data.totalReviews").value(1));
    }

    @Test
    void testWishlistWorkflow() throws Exception {
        String instToken = authenticateAsInstructor("wish-inst-" + UUID.randomUUID());
        String studToken = authenticateAsStudent("wish-stud-" + UUID.randomUUID());

        String courseId = createCourse(instToken, "Kotlin Essentials", 99.00, "Intermediate", "programming");

        // Add to wishlist
        WishlistRequest wishlistRequest = new WishlistRequest(UUID.fromString(courseId));
        mockMvc.perform(post("/api/v1/wishlist")
                        .header("Authorization", studToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(wishlistRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        // Get wishlist
        mockMvc.perform(get("/api/v1/wishlist")
                        .header("Authorization", studToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(1)))
                .andExpect(jsonPath("$.data[0].title").value("Kotlin Essentials"));

        // Remove from wishlist
        mockMvc.perform(delete("/api/v1/wishlist/{courseId}", courseId)
                        .header("Authorization", studToken))
                .andExpect(status().isOk());

        // Check empty wishlist
        mockMvc.perform(get("/api/v1/wishlist")
                        .header("Authorization", studToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(0)));
    }

    @Test
    void testExtendedSearchAndFilters() throws Exception {
        String instToken = authenticateAsInstructor("search-inst-" + UUID.randomUUID());

        // Create 3 courses with different parameters
        createCourse(instToken, "Node.js Basic", 10.00, "Beginner", "programming");
        createCourse(instToken, "Advanced Go", 150.00, "Advanced", "programming");
        String rustCourseId = createCourse(instToken, "Rust Expert", 200.00, "Advanced", "programming");

        // Review rust course to give it a rating
        String studToken = authenticateAsStudent("search-stud-" + UUID.randomUUID());
        String reviewPayload = "{\"rating\":4,\"comment\":\"Loved Rust!\"}";
        mockMvc.perform(post("/api/v1/courses/{courseId}/reviews", rustCourseId)
                        .header("Authorization", studToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(reviewPayload))
                .andExpect(status().isOk());

        // Test filter by difficulty = Advanced
        mockMvc.perform(get("/api/v1/courses")
                        .param("difficulty", "Advanced"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(2)));

        // Test filter by priceMin/priceMax
        mockMvc.perform(get("/api/v1/courses")
                        .param("priceMin", "120.00")
                        .param("priceMax", "180.00"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(1)))
                .andExpect(jsonPath("$.data[0].title").value("Advanced Go"));

        // Test filter by ratingMin
        mockMvc.perform(get("/api/v1/courses")
                        .param("ratingMin", "4.0"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(1)))
                .andExpect(jsonPath("$.data[0].title").value("Rust Expert"));

        // Test sorting by price desc
        MvcResult sortResult = mockMvc.perform(get("/api/v1/courses")
                        .param("sortBy", "price_desc"))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode searchData = objectMapper.readTree(sortResult.getResponse().getContentAsString()).path("data");
        assertTrue(searchData.get(0).path("price").asDouble() >= searchData.get(1).path("price").asDouble());
    }

    private String authenticateAsInstructor(String email) throws Exception {
        return registerAndGetToken(email, "INSTRUCTOR");
    }

    private String authenticateAsStudent(String email) throws Exception {
        return registerAndGetToken(email, "STUDENT");
    }

    private String registerAndGetToken(String email, String role) throws Exception {
        String cleanEmail = email.replace("-", "") + "@example.com";
        String registerPayload = "{\"fullName\":\"Test User\",\"email\":\"" + cleanEmail + "\",\"password\":\"Password123!\",\"role\":\"" + role + "\"}";
        MvcResult result = mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(registerPayload))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode response = objectMapper.readTree(result.getResponse().getContentAsString());
        return "Bearer " + response.path("data").path("accessToken").asText();
    }

    private String createCourse(String token, String title, double price, String difficulty, String categorySlug) throws Exception {
        CreateCourseRequest request = new CreateCourseRequest(
                title,
                "Description for " + title,
                price,
                15,
                difficulty,
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

    private String createSection(String token, String courseId, String title) throws Exception {
        String payload = "{\"title\":\"" + title + "\",\"description\":\"Section desc\"}";
        MvcResult result = mockMvc.perform(post("/api/v1/courses/{courseId}/sections", courseId)
                        .header("Authorization", token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(payload))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode response = objectMapper.readTree(result.getResponse().getContentAsString());
        return response.path("data").path("id").asText();
    }

    private String createLesson(String token, String courseId, String sectionId, CreateLessonRequest request) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/v1/courses/{courseId}/sections/{sectionId}/lessons", courseId, sectionId)
                        .header("Authorization", token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode response = objectMapper.readTree(result.getResponse().getContentAsString());
        return response.path("data").path("id").asText();
    }
}
