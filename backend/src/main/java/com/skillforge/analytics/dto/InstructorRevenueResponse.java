package com.skillforge.analytics.dto;

import java.util.List;

/**
 * DTO for the instructor-specific revenue report endpoint.
 * Used by the web instructor dashboard Earnings view.
 */
public record InstructorRevenueResponse(
        double grossSales,
        double instructorShare,
        double platformFee,
        long totalOrders,
        List<PayoutEntry> payoutHistory
) {
    public record PayoutEntry(
            String id,
            String date,
            double amount,
            String status,
            String method
    ) {}
}
