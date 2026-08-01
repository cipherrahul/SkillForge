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
    private final com.skillforge.payment.service.PaymentGatewayService paymentGatewayService;

    public PaymentController(PaymentService paymentService,
            CourseService courseService,
            com.skillforge.payment.service.PaymentGatewayService paymentGatewayService) {
        this.paymentService = paymentService;
        this.courseService = courseService;
        this.paymentGatewayService = paymentGatewayService;
    }

    @PostMapping("/api/v1/orders/checkout")
    public ResponseEntity<ApiResponse<OrderResponse>> checkout(@Valid @RequestBody CheckoutRequest request,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
            HttpServletRequest servletRequest,
            Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        OrderResponse response = paymentService.checkoutWithIdempotency(request, currentUser, idempotencyKey);
        return ResponseEntity
                .ok(ApiResponse.success("Checkout order created", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/orders/{orderId}/complete")
    public ResponseEntity<ApiResponse<OrderResponse>> completeOrder(@PathVariable String orderId,
            HttpServletRequest servletRequest,
            Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        OrderResponse response = paymentService.completeOrder(UUID.fromString(orderId), currentUser);
        return ResponseEntity
                .ok(ApiResponse.success("Payment completed successfully", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/orders/{orderId}/refund")
    public ResponseEntity<ApiResponse<OrderResponse>> refundOrder(@PathVariable String orderId,
            HttpServletRequest servletRequest,
            Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        OrderResponse response = paymentService.refundOrder(UUID.fromString(orderId), currentUser);
        return ResponseEntity
                .ok(ApiResponse.success("Order refunded successfully", response, servletRequest.getRequestURI()));
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
        return ResponseEntity
                .ok(ApiResponse.success("Subscription plans loaded", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/subscriptions/active")
    public ResponseEntity<ApiResponse<UserSubscriptionEntity>> getActiveSubscription(HttpServletRequest servletRequest,
            Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        UserSubscriptionEntity response = paymentService.getActiveSubscription(currentUser.getEmail());
        return ResponseEntity
                .ok(ApiResponse.success("Active subscription loaded", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/coupons")
    public ResponseEntity<ApiResponse<CouponResponse>> createCoupon(@Valid @RequestBody CreateCouponRequest request,
            HttpServletRequest servletRequest,
            Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        CouponResponse response = paymentService.createCoupon(request, currentUser);
        return ResponseEntity
                .ok(ApiResponse.success("Coupon created successfully", response, servletRequest.getRequestURI()));
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
        return ResponseEntity
                .ok(ApiResponse.success("Revenue report loaded", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/payouts/request")
    public ResponseEntity<ApiResponse<PayoutResponse>> requestPayout(@Valid @RequestBody PayoutRequest request,
            HttpServletRequest servletRequest,
            Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        PayoutResponse response = paymentService.requestPayout(request, currentUser);
        return ResponseEntity.ok(
                ApiResponse.success("Payout request submitted successfully", response, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/payouts/history")
    public ResponseEntity<ApiResponse<List<PayoutResponse>>> getPayoutHistory(HttpServletRequest servletRequest,
            Principal principal) {
        UserEntity currentUser = courseService.getCurrentUser(principal);
        List<PayoutResponse> response = paymentService.getPayoutHistory(currentUser.getEmail());
        return ResponseEntity
                .ok(ApiResponse.success("Payout history loaded", response, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/payments/calculate-price")
    public ResponseEntity<ApiResponse<Object>> calculatePriceBreakdown(@RequestBody java.util.Map<String, Object> body,
            HttpServletRequest servletRequest) {
        Double basePrice = ((Number) body.getOrDefault("basePrice", 0.0)).doubleValue();
        String couponCode = (String) body.get("couponCode");
        Object breakdown = paymentGatewayService.calculatePriceBreakdown(basePrice, couponCode);
        return ResponseEntity
                .ok(ApiResponse.success("Price breakdown calculated", breakdown, servletRequest.getRequestURI()));
    }

    @PostMapping("/api/v1/payments/webhooks/razorpay")
    public ResponseEntity<ApiResponse<Object>> handleRazorpayWebhook(@RequestBody java.util.Map<String, Object> payload,
            @RequestHeader(value = "X-Razorpay-Signature", required = false) String signature,
            HttpServletRequest servletRequest) {
        Object result = paymentGatewayService.processRazorpayWebhook(payload, signature);
        return ResponseEntity
                .ok(ApiResponse.success("Razorpay webhook processed", result, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/payments/invoices/{orderId}")
    public ResponseEntity<ApiResponse<Object>> getInvoice(@PathVariable String orderId,
            HttpServletRequest servletRequest) {
        Object invoice = paymentGatewayService.getInvoiceData(UUID.fromString(orderId));
        return ResponseEntity.ok(ApiResponse.success("Invoice loaded", invoice, servletRequest.getRequestURI()));
    }
}
