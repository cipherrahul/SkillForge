package com.skillforge.payment.dto;

public record RevenueReportResponse(
        double totalRevenue,
        double instructorShare,
        double platformShare
) {
}
