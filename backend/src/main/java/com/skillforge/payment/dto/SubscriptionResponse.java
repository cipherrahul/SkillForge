package com.skillforge.payment.dto;

import com.skillforge.payment.entity.SubscriptionStatus;

import java.time.Instant;
import java.util.UUID;

public record SubscriptionResponse(
        UUID id,
        String userEmail,
        UUID subscriptionPlanId,
        Instant startDate,
        Instant endDate,
        SubscriptionStatus status
) {
}
