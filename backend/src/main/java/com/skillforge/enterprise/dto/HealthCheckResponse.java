package com.skillforge.enterprise.dto;

public record HealthCheckResponse(
        String status,
        long dbLatencyMs,
        long storageLatencyMs,
        boolean cacheOperational
) {
}
