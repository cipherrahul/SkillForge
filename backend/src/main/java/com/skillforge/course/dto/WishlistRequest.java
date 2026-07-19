package com.skillforge.course.dto;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record WishlistRequest(@NotNull(message = "Course ID is required") UUID courseId) {
}
