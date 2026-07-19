package com.skillforge.assessment.dto;

import com.skillforge.assessment.entity.QuestionType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.List;

public record QuizQuestionDto(
        @NotBlank(message = "Question text is required")
        String questionText,

        @NotNull(message = "Question type is required")
        QuestionType questionType,

        @NotNull(message = "Options are required")
        List<String> options,

        @NotNull(message = "Correct option index is required")
        Integer correctOptionIndex,

        String explanation
) {
}
