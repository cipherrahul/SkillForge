package com.skillforge.ai.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.UUID;

public record StartAiSessionRequest(
        UUID lessonId, // optional context

        @NotBlank(message = "Session type is required")
        String type // TUTOR, DOUBT_SOLVER, ASSISTANT
) {
}
