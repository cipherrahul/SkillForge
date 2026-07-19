package com.skillforge.community.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record CreateGroupRequest(
        @NotBlank(message = "Group name is required")
        @Pattern(regexp = "^[a-zA-Z0-9\\s-_]+$", message = "Name contains invalid characters")
        String name,

        String description
) {
}
