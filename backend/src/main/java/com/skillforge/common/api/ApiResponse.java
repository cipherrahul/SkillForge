package com.skillforge.common.api;

import java.time.Instant;

public record ApiResponse<T>(
        boolean success,
        String message,
        T data,
        String timestamp,
        String path,
        String errorCode
) {
    public static <T> ApiResponse<T> success(String message, T data, String path) {
        return new ApiResponse<>(true, message, data, Instant.now().toString(), path, null);
    }

    public static <T> ApiResponse<T> failure(String message, String errorCode, String path) {
        return new ApiResponse<>(false, message, null, Instant.now().toString(), path, errorCode);
    }
}
