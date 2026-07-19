package com.skillforge.mobile.dto;

import java.util.List;
import java.util.UUID;

public record OfflineManifestResponse(
        UUID courseId,
        String courseTitle,
        List<OfflineLessonItem> downloads
) {
    public record OfflineLessonItem(
            UUID lessonId,
            String title,
            String type,
            String downloadUrl,
            int durationSeconds
    ) {}
}
