package com.skillforge.enterprise.dto;

public record SystemMetricsResponse(
        double systemCpuLoad,
        long totalHeapMemoryMb,
        long usedHeapMemoryMb,
        int activeThreadsCount,
        long databaseConnectionPoolActive
) {
}
