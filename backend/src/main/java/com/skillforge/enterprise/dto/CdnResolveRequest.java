package com.skillforge.enterprise.dto;

import jakarta.validation.constraints.NotBlank;

public record CdnResolveRequest(
        @NotBlank(message = "Original storage resource URL is required")
        String originalUrl,

        String clientCountry // optional geo-routing override
) {
}
