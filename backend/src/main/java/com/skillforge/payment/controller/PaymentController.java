package com.skillforge.payment.controller;

import com.skillforge.auth.entity.UserEntity;
import com.skillforge.common.api.ApiResponse;
import com.skillforge.course.service.CourseService;
import com.skillforge.payment.dto.*;
import com.skillforge.payment.entity.SubscriptionPlanEntity;
import com.skillforge.payment.entity.UserSubscriptionEntity;
import com.skillforge.payment.service.PaymentService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.UUID;

@RestController
public class PaymentController {
    private final PaymentService paymentService;
    private final CourseService courseService;

    public PaymentController(PaymentService paymentService, CourseService courseService) {
        this.paymentService = paymentService;
        this.courseService = courseService;
    }

    @PostMapping("/api/v1/orders/checkout")
    public ResponseEntity<ApiResponse<OrderResponse>> checkout(@Valid @RequestBody CheckoutRequest request,
                                                               HttpServletRequest servletRequest,
                                                               Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        OrderResponse response = paymentService.checkout(request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Checkout order created", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/orders/{orderId}/complete")
    public ResponseEntity<ApiResponse<OrderResponse>> completeOrder(@PathVariable String orderId,
                                                                    HttpServletRequest servletRequest,
                                                                    Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        OrderResponse response = paymentService.completeOrder(UUID.fromString(orderId), currentUser);
        return ResponseEntity.ok(ApiResponse.success("Payment completed successfully", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/orders/{orderId}/refund")
    public ResponseEntity<ApiResponse<OrderResponse>> refundOrder(@PathVariable String orderId,
                                                                  HttpServletRequest servletRequest,
                                                                  Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        OrderResponse response = paymentService.refundOrder(UUID.fromString(orderId), currentUser);
        return ResponseEntity.ok(ApiResponse.success("Order refunded successfully", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/orders/history")
    public ResponseEntity<ApiResponse<List<OrderResponse>>> getOrderHistory(HttpServletRequest servletRequest,
                                                                            Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        List<OrderResponse> response = paymentService.getOrderHistory(currentUser.getEmail());
        return ResponseEntity.ok(ApiResponse.success("Order history loaded", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/subscriptions/plans")
    public ResponseEntity<ApiResponse<List<SubscriptionPlanEntity>>> getPlans(HttpServletRequest servletRequest) {
        List<SubscriptionPlanEntity> response = paymentService.getPlans();
        return ResponseEntity.ok(ApiResponse.success("Subscription plans loaded", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/subscriptions/active")
    public ResponseEntity<ApiResponse<UserSubscriptionEntity>> getActiveSubscription(HttpServletRequest servletRequest,
                                                                                     Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        UserSubscriptionEntity response = paymentService.getActiveSubscription(currentUser.getEmail());
        return ResponseEntity.ok(ApiResponse.success("Active subscription loaded", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/coupons")
    public ResponseEntity<ApiResponse<CouponResponse>> createCoupon(@Valid @RequestBody CreateCouponRequest request,
                                                                    HttpServletRequest servletRequest,
                                                                    Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        // Admin or instructor check (for simplicity, allowed for authenticated users but verified via service or basic authorization rules)
        CouponResponse response = paymentService.createCoupon(request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Coupon created successfully", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/coupons/validate/{code}")
    public ResponseEntity<ApiResponse<CouponResponse>> validateCoupon(@PathVariable String code,
                                                                      HttpServletRequest servletRequest) {
        CouponResponse response = paymentService.validateCoupon(code);
        return ResponseEntity.ok(ApiResponse.success("Coupon is valid", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/reports/instructor/revenue")
    public ResponseEntity<ApiResponse<RevenueReportResponse>> getInstructorRevenue(HttpServletRequest servletRequest,
                                                                                   Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        RevenueReportResponse response = paymentService.getInstructorRevenue(currentUser.getEmail());
        return ResponseEntity.ok(ApiResponse.success("Revenue report loaded", response, servletRequest.getRequestURI()));
    }
}
