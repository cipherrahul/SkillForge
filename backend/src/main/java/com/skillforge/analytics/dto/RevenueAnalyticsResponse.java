package com.skillforge.analytics.dto;

public record RevenueAnalyticsResponse(
        double totalGrossRevenue,
        double totalDiscounts,
        long completedOrdersCount,
        double averageOrderValue
) {
}
