package com.skillforge.liveclass.dto;

import java.time.Instant;
import java.util.UUID;

public record ChatMessageResponse(
        UUID id,
        UUID sessionId,
        String senderEmail,
        String senderName,
        String message,
        Instant timestamp
) {
}
