package com.skillforge.assessment.dto;

import com.skillforge.assessment.entity.AssessmentType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.List;
import java.util.UUID;

public record CreateAssessmentRequest(
        @NotBlank(message = "Title is required")
        String title,

        String description,

        @NotNull(message = "Assessment type is required")
        AssessmentType type,

        UUID lessonId,

        int maxScore,

        int passingScore,

        List<QuizQuestionDto> questions
) {
}
