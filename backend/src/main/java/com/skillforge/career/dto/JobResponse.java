package com.skillforge.career.dto;

import java.time.Instant;
import java.util.UUID;

public record JobResponse(
        UUID id,
        String title,
        String companyName,
        String location,
        String type,
        String description,
        String requirements,
        String salaryRange,
        String postedByEmail,
        boolean active,
        Instant createdAt
) {
}
