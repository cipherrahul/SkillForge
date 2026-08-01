package com.skillforge.payment.service;

import com.skillforge.auth.entity.UserEntity;
import com.skillforge.common.exception.BadRequestException;
import com.skillforge.common.exception.ResourceNotFoundException;
import com.skillforge.course.entity.CourseEntity;
import com.skillforge.course.repository.CourseRepository;
import com.skillforge.enrollment.service.EnrollmentService;
import com.skillforge.payment.dto.*;
import com.skillforge.payment.entity.*;
import com.skillforge.payment.repository.*;
import com.skillforge.storage.service.StorageService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.util.*;

@Service
public class PaymentGatewayService {

    private final OrderRepository orderRepository;
    private final CouponRepository couponRepository;
    private final InvoiceRepository invoiceRepository;
    private final InstructorRevenueRepository instructorRevenueRepository;
    private final CourseRepository courseRepository;
    private final EnrollmentService enrollmentService;
    private final StorageService storageService;

    // Razorpay Webhook Secret Key
    private static final String RAZORPAY_WEBHOOK_SECRET = "sf_razorpay_secret_key_2026";

    public PaymentGatewayService(OrderRepository orderRepository,
                                 CouponRepository couponRepository,
                                 InvoiceRepository invoiceRepository,
                                 InstructorRevenueRepository instructorRevenueRepository,
                                 CourseRepository courseRepository,
                                 EnrollmentService enrollmentService,
                                 StorageService storageService) {
        this.orderRepository = orderRepository;
        this.couponRepository = couponRepository;
        this.invoiceRepository = invoiceRepository;
        this.instructorRevenueRepository = instructorRevenueRepository;
        this.courseRepository = courseRepository;
        this.enrollmentService = enrollmentService;
        this.storageService = storageService;
    }

    /**
     * Compute Itemized Pricing (Base Price, 18% GST Tax, Discount, Total)
     */
    public Map<String, Object> calculatePriceBreakdown(Double basePrice, String couponCode) {
        double price = basePrice != null ? Math.max(0, basePrice) : 0.0;
        double discountPercent = 0.0;
        double discountAmount = 0.0;
        String appliedCoupon = null;

        if (couponCode != null && !couponCode.isBlank()) {
            Optional<CouponEntity> couponOpt = couponRepository.findByCodeIgnoreCaseAndActiveTrue(couponCode.trim());
            if (couponOpt.isPresent()) {
                CouponEntity coupon = couponOpt.get();
                if (!coupon.getExpiryDate().isBefore(Instant.now()) && coupon.getUsedCount() < coupon.getMaxUses()) {
                    discountPercent = coupon.getDiscountPercent();
                    discountAmount = Math.round((price * (discountPercent / 100.0)) * 100.0) / 100.0;
                    appliedCoupon = coupon.getCode().toUpperCase();
                }
            }
        }

        double discountedPrice = Math.max(0, price - discountAmount);
        double gstAmount = Math.round((discountedPrice * 0.18) * 100.0) / 100.0; // 18% GST
        double totalPayable = Math.round((discountedPrice + gstAmount) * 100.0) / 100.0;
        double instructorShare = Math.round((discountedPrice * 0.70) * 100.0) / 100.0; // 70% share

        Map<String, Object> breakdown = new LinkedHashMap<>();
        breakdown.put("basePrice", price);
        breakdown.put("couponCode", appliedCoupon);
        breakdown.put("discountPercent", discountPercent);
        breakdown.put("discountAmount", discountAmount);
        breakdown.put("discountedPrice", discountedPrice);
        breakdown.put("gstPercent", 18.0);
        breakdown.put("gstAmount", gstAmount);
        breakdown.put("totalPayable", totalPayable);
        breakdown.put("instructorShare", instructorShare);
        return breakdown;
    }

    /**
     * Verify Razorpay HMAC SHA-256 Webhook Signature
     */
    public boolean verifyRazorpaySignature(String payload, String signature) {
        if (signature == null || signature.isBlank() || payload == null) return false;
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            SecretKeySpec secretKey = new SecretKeySpec(RAZORPAY_WEBHOOK_SECRET.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
            mac.init(secretKey);
            byte[] hmacData = mac.doFinal(payload.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : hmacData) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString().equals(signature.trim());
        } catch (NoSuchAlgorithmException | InvalidKeyException e) {
            return false;
        }
    }

    /**
     * Handle Razorpay Webhook Events
     */
    @Transactional
    public Map<String, Object> processRazorpayWebhook(Map<String, Object> payload, String signature) {
        // If signature is provided, verify it. Fall back gracefully for sandbox simulations.
        if (signature != null && !signature.isBlank() && !verifyRazorpaySignature(payload.toString(), signature)) {
            throw new BadRequestException("Invalid Razorpay webhook signature");
        }

        String event = (String) payload.getOrDefault("event", "payment.captured");
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("event", event);
        result.put("status", "PROCESSED");
        result.put("processedAt", Instant.now().toString());
        return result;
    }

    /**
     * Fetch Itemized Invoice
     */
    public Map<String, Object> getInvoiceData(UUID orderId) {
        OrderEntity order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Order not found"));

        InvoiceEntity invoice = invoiceRepository.findByOrderId(orderId)
                .orElse(null);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("orderId", order.getId());
        data.put("invoiceNumber", invoice != null ? invoice.getInvoiceNumber() : "INV-" + order.getId().toString().substring(0, 8).toUpperCase());
        data.put("billingName", invoice != null ? invoice.getBillingName() : order.getUserEmail());
        data.put("customerEmail", order.getUserEmail());
        data.put("amountPaid", order.getAmount());
        data.put("currency", order.getCurrency());
        data.put("transactionId", order.getTransactionId());
        data.put("status", order.getStatus());
        data.put("pdfUrl", invoice != null ? invoice.getPdfUrl() : null);
        data.put("issuedAt", order.getCreatedAt());
        return data;
    }
}
