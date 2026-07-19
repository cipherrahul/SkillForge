package com.skillforge.playground.dto;

public record PlaygroundResponse(
        String output,
        String error,
        int exitCode
) {
}
