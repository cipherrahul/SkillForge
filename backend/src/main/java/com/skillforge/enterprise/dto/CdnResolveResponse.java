package com.skillforge.enterprise.dto;

import java.time.Instant;

public record CdnResolveResponse(
        String originalUrl,
        String resolvedCdnUrl,
        String routedEdgeLocation,
        Instant expiryTime
) {
}
