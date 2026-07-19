package com.skillforge.payment.dto;

import java.time.Instant;
import java.util.UUID;

public record CouponResponse(
        UUID id,
        String code,
        int discountPercent,
        Instant expiryDate,
        int maxUses,
        int usedCount,
        boolean active
) {
}
