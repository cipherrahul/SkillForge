package com.skillforge.payment.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;

public record CreateCouponRequest(
        @NotBlank(message = "Coupon code is required")
        String code,

        @Min(value = 1, message = "Discount must be at least 1%")
        @Max(value = 100, message = "Discount cannot exceed 100%")
        int discountPercent,

        @NotNull(message = "Expiry date is required")
        Instant expiryDate,

        @Min(value = 1, message = "Max uses must be at least 1")
        int maxUses
) {
}
