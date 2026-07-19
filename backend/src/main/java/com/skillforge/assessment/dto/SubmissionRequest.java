package com.skillforge.assessment.dto;

import java.util.List;

public record SubmissionRequest(
        List<Integer> selectedAnswers,
        String fileUrl
) {
}
