package com.skillforge.payment.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;

public record PayoutRequest(
        @Min(value = 1, message = "Payout amount must be greater than 0")
        double amount,
        @NotBlank(message = "Payment method / payout account is required")
        String payoutMethod
) {
}
