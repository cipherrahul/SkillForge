package com.skillforge.assessment.dto;

import com.skillforge.assessment.entity.AssessmentType;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record AssessmentResponse(
        UUID id,
        UUID courseId,
        UUID lessonId,
        String title,
        String description,
        AssessmentType type,
        int maxScore,
        int passingScore,
        List<QuizQuestionDto> questions,
        Instant createdAt
) {
}
