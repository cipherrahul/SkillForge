package com.skillforge.community.dto;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record ForumPostResponse(
        UUID id,
        UUID courseId,
        String userEmail,
        String userFullName,
        String title,
        String content,
        boolean isQuestion,
        boolean resolved,
        String category,
        Instant createdAt,
        List<ForumCommentResponse> comments
) {
}
