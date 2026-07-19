package com.skillforge.community.dto;

import java.time.Instant;
import java.util.UUID;

public record ForumCommentResponse(
        UUID id,
        UUID postId,
        String userEmail,
        String userFullName,
        String content,
        boolean isAnswer,
        Instant createdAt
) {
}
