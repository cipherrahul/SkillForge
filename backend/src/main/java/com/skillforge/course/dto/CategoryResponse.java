package com.skillforge.course.dto;

import java.util.UUID;

public record CategoryResponse(UUID id, String name, String slug, String description) {
}
