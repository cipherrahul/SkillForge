package com.skillforge.course.dto;

public record CourseSearchRequest(
        String keyword,
        String categorySlug,
        String difficulty,
        Double priceMin,
        Double priceMax,
        Double ratingMin,
        String sortBy
) {
    public CourseSearchRequest(String keyword, String categorySlug) {
        this(keyword, categorySlug, null, null, null, null, null);
    }
}
