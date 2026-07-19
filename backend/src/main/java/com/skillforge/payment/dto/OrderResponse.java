package com.skillforge.payment.dto;

import com.skillforge.payment.entity.OrderStatus;

import java.time.Instant;
import java.util.UUID;

public record OrderResponse(
        UUID id,
        String userEmail,
        UUID courseId,
        UUID subscriptionPlanId,
        double amount,
        String currency,
        OrderStatus status,
        String transactionId,
        String couponCode,
        double discountAmount,
        Instant createdAt
) {
}
