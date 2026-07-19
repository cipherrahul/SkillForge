package com.skillforge.course.dto;

import java.util.List;
import java.util.UUID;

public record SectionResponse(UUID id, String title, String description, List<LessonResponse> lessons) {
}
