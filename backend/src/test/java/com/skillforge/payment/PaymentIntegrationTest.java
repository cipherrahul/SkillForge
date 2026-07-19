package com.skillforge.payment;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.skillforge.course.dto.CreateCategoryRequest;
import com.skillforge.course.dto.CreateCourseRequest;
import com.skillforge.payment.dto.CheckoutRequest;
import com.skillforge.payment.dto.CreateCouponRequest;
import com.skillforge.payment.entity.SubscriptionPlanEntity;
import com.skillforge.payment.repository.SubscriptionPlanRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.time.Instant;
import java.util.UUID;

import static org.hamcrest.Matchers.greaterThan;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class PaymentIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private SubscriptionPlanRepository subscriptionPlanRepository;

    @Test
    void testCoursePurchaseAndSubscriptionsFlows() throws Exception {
        String instEmail = "inst-p6-" + UUID.randomUUID() + "@example.com";
        String studEmail = "stud-p6-" + UUID.randomUUID() + "@example.com";

        String instToken = authenticateAsUser(instEmail, "INSTRUCTOR");
        String studToken = authenticateAsUser(studEmail, "STUDENT");

        // 1. Setup course
        CreateCategoryRequest categoryReq = new CreateCategoryRequest("Cloud DevOps", "Container tools and setups");
        mockMvc.perform(post("/api/v1/categories")
                        .header("Authorization", instToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(categoryReq)))
                .andExpect(status().isOk());

        String courseId = createCourse(instToken, "Kubernetes Advanced", 100.00, "cloud-devops");

        // 2. Create Discount Coupon (25% off)
        CreateCouponRequest couponRequest = new CreateCouponRequest(
                "WINTER25",
                25,
                Instant.now().plusSeconds(86400),
                10
        );

        mockMvc.perform(post("/api/v1/coupons")
                        .header("Authorization", instToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(couponRequest)))
                .andExpect(status().isOk());

        // Validate Coupon
        mockMvc.perform(get("/api/v1/coupons/validate/{code}", "WINTER25"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.discountPercent").value(25));

        // 3. Checkout Single Course Purchase with coupon (Original price: 100.00, after 25% off: 75.00)
        CheckoutRequest checkoutReq = new CheckoutRequest(
                UUID.fromString(courseId),
                null,
                "WINTER25"
        );

        MvcResult checkoutResult = mockMvc.perform(post("/api/v1/orders/checkout")
                        .header("Authorization", studToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(checkoutReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.amount").value(75.00))
                .andExpect(jsonPath("$.data.discountAmount").value(25.00))
                .andExpect(jsonPath("$.data.status").value("PENDING"))
                .andReturn();

        String orderId = objectMapper.readTree(checkoutResult.getResponse().getContentAsString()).path("data").path("id").asText();

        // Complete Order (Simulate payment success callback)
        mockMvc.perform(post("/api/v1/orders/{orderId}/complete", orderId)
                        .header("Authorization", studToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("COMPLETED"))
                .andExpect(jsonPath("$.data.transactionId").exists());

        // Check student is auto-enrolled
        mockMvc.perform(get("/api/v1/enrollments")
                        .header("Authorization", studToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].courseId").value(courseId));

        // Check Instructor Revenue Split generated
        mockMvc.perform(get("/api/v1/reports/instructor/revenue")
                        .header("Authorization", instToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalRevenue").value(75.00))
                .andExpect(jsonPath("$.data.instructorShare").value(52.50)) // 70% of 75.00
                .andExpect(jsonPath("$.data.platformShare").value(22.50));

        // 4. Test Subscriptions Model
        // Insert a subscription plan into database
        SubscriptionPlanEntity plan = new SubscriptionPlanEntity();
        plan.setName("Monthly Pro Pass");
        plan.setDescription("All access to courses pass");
        plan.setPrice(29.99);
        plan.setIntervalMonths(1);
        plan = subscriptionPlanRepository.save(plan);

        // Checkout subscription
        CheckoutRequest subCheckout = new CheckoutRequest(
                null,
                plan.getId(),
                null
        );

        MvcResult subCheckoutResult = mockMvc.perform(post("/api/v1/orders/checkout")
                        .header("Authorization", studToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(subCheckout)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.amount").value(29.99))
                .andReturn();

        String subOrderId = objectMapper.readTree(subCheckoutResult.getResponse().getContentAsString()).path("data").path("id").asText();

        // Complete subscription order
        mockMvc.perform(post("/api/v1/orders/{orderId}/complete", subOrderId)
                        .header("Authorization", studToken))
                .andExpect(status().isOk());

        // Check active subscription loaded
        mockMvc.perform(get("/api/v1/subscriptions/active")
                        .header("Authorization", studToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("ACTIVE"));
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
