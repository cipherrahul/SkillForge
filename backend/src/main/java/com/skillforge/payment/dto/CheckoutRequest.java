package com.skillforge.payment.dto;

import java.util.UUID;

public record CheckoutRequest(
        UUID courseId, // optional for course purchase

        UUID subscriptionPlanId, // optional for subscription checkout

        String couponCode // optional promo code
) {
}
