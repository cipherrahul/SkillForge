package com.skillforge.course.service;

import com.skillforge.auth.entity.Role;
import com.skillforge.auth.entity.UserEntity;
import com.skillforge.auth.repository.UserRepository;
import com.skillforge.common.exception.BadRequestException;
import com.skillforge.common.exception.ResourceNotFoundException;
import com.skillforge.common.exception.UnauthorizedException;
import com.skillforge.course.dto.*;
import com.skillforge.course.entity.*;
import com.skillforge.course.repository.*;
import org.springframework.stereotype.Service;
import com.skillforge.enrollment.service.EnrollmentService;

import java.security.Principal;
import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Stream;

@Service
public class CourseService {
    private final CategoryRepository categoryRepository;
    private final CourseRepository courseRepository;
    private final SectionRepository sectionRepository;
    private final UserRepository userRepository;
    private final LessonRepository lessonRepository;
    private final ReviewRepository reviewRepository;
    private final WishlistRepository wishlistRepository;
    private final EnrollmentService enrollmentService;

    public CourseService(CategoryRepository categoryRepository,
                         CourseRepository courseRepository,
                         SectionRepository sectionRepository,
                         UserRepository userRepository,
                         LessonRepository lessonRepository,
                         ReviewRepository reviewRepository,
                         WishlistRepository wishlistRepository,
                         EnrollmentService enrollmentService) {
        this.categoryRepository = categoryRepository;
        this.courseRepository = courseRepository;
        this.sectionRepository = sectionRepository;
        this.userRepository = userRepository;
        this.lessonRepository = lessonRepository;
        this.reviewRepository = reviewRepository;
        this.wishlistRepository = wishlistRepository;
        this.enrollmentService = enrollmentService;
    }

    public UserEntity getCurrentUser(Principal principal) {
        if (principal == null || principal.getName() == null || principal.getName().isBlank()) {
            throw new UnauthorizedException("Authentication required");
        }
        return userRepository.findByEmail(principal.getName())
                .orElseThrow(() -> new UnauthorizedException("User not found"));
    }

    public Optional<UserEntity> getOptionalUser(Principal principal) {
        if (principal == null || principal.getName() == null || principal.getName().isBlank()) {
            return Optional.empty();
        }
        return userRepository.findByEmail(principal.getName());
    }

    public CategoryResponse createCategory(CreateCategoryRequest request) {
        String slug = request.name().trim().toLowerCase().replaceAll("\\s+", "-");
        if (categoryRepository.existsBySlug(slug)) {
            throw new BadRequestException("Category already exists");
        }

        CategoryEntity category = new CategoryEntity();
        category.setName(request.name().trim());
        category.setSlug(slug);
        category.setDescription(request.description());
        CategoryEntity saved = categoryRepository.save(category);
        return new CategoryResponse(saved.getId(), saved.getName(), saved.getSlug(), saved.getDescription());
    }

    public List<CategoryResponse> listCategories() {
        return categoryRepository.findAll().stream()
                .filter(cat -> !cat.isDeleted())
                .map(cat -> new CategoryResponse(cat.getId(), cat.getName(), cat.getSlug(), cat.getDescription()))
                .toList();
    }

    public CourseResponse createCourse(CreateCourseRequest request, UserEntity currentUser) {
        if (!categoryRepository.existsBySlug(request.categorySlug().trim().toLowerCase())) {
            throw new BadRequestException("Category not found");
        }

        CourseEntity course = new CourseEntity();
        course.setTitle(request.title().trim());
        course.setDescription(request.description().trim());
        course.setPrice(request.price());
        course.setDurationHours(request.durationHours());
        course.setDifficulty(request.difficulty().trim());
        course.setCategorySlug(request.categorySlug().trim().toLowerCase());
        course.setInstructorEmail(currentUser.getEmail());
        course.setThumbnailUrl(request.thumbnailUrl() == null || request.thumbnailUrl().isBlank() ? "https://images.example.com/course.png" : request.thumbnailUrl());
        course.setPublished(request.published());
        CourseEntity saved = courseRepository.save(course);
        return mapCourse(saved, currentUser);
    }

    public CourseResponse updateCourse(String courseId, CreateCourseRequest request, UserEntity currentUser) {
        UUID courseUuid = parseUuid(courseId, "Invalid course ID");
        CourseEntity course = courseRepository.findById(courseUuid)
                .orElseThrow(() -> new ResourceNotFoundException("Course not found"));

        if (!course.getInstructorEmail().equalsIgnoreCase(currentUser.getEmail()) &&
                currentUser.getRole() != Role.ADMIN && currentUser.getRole() != Role.SUPER_ADMIN) {
            throw new UnauthorizedException("You can only edit your own courses");
        }

        if (!categoryRepository.existsBySlug(request.categorySlug().trim().toLowerCase())) {
            throw new BadRequestException("Category not found");
        }

        course.setTitle(request.title().trim());
        course.setDescription(request.description().trim());
        course.setPrice(request.price());
        course.setDurationHours(request.durationHours());
        course.setDifficulty(request.difficulty().trim());
        course.setCategorySlug(request.categorySlug().trim().toLowerCase());
        course.setThumbnailUrl(request.thumbnailUrl() == null || request.thumbnailUrl().isBlank() ? "https://images.example.com/course.png" : request.thumbnailUrl());
        course.setPublished(request.published());
        course.setUpdatedAt(Instant.now());

        CourseEntity saved = courseRepository.save(course);
        return mapCourse(saved, currentUser);
    }

    public SectionResponse createSection(String courseId, CreateSectionRequest request, UserEntity currentUser) {
        UUID courseUuid = parseUuid(courseId, "Invalid course id");
        CourseEntity course = courseRepository.findById(courseUuid)
                .orElseThrow(() -> new ResourceNotFoundException("Course not found"));
        if (!course.getInstructorEmail().equalsIgnoreCase(currentUser.getEmail())) {
            throw new UnauthorizedException("You can only edit your own courses");
        }

        SectionEntity section = new SectionEntity();
        section.setTitle(request.title().trim());
        section.setDescription(request.description() == null ? "" : request.description().trim());
        course.addSection(section);
        sectionRepository.save(section);
        courseRepository.save(course);
        return mapSection(section, currentUser);
    }

    public LessonResponse createLesson(String courseId, String sectionId, CreateLessonRequest request, UserEntity currentUser) {
        UUID courseUuid = parseUuid(courseId, "Invalid course ID");
        UUID sectionUuid = parseUuid(sectionId, "Invalid section ID");

        CourseEntity course = courseRepository.findById(courseUuid)
                .orElseThrow(() -> new ResourceNotFoundException("Course not found"));
        SectionEntity section = sectionRepository.findById(sectionUuid)
                .orElseThrow(() -> new ResourceNotFoundException("Section not found"));

        if (!section.getCourse().getId().equals(course.getId())) {
            throw new BadRequestException("Section does not belong to the given course");
        }
        if (!course.getInstructorEmail().equalsIgnoreCase(currentUser.getEmail())) {
            throw new UnauthorizedException("You can only edit your own courses");
        }

        LessonEntity lesson = new LessonEntity();
        lesson.setTitle(request.title().trim());
        lesson.setDescription(request.description() == null ? "" : request.description().trim());
        lesson.setVideoUrl(request.videoUrl());
        lesson.setPdfUrl(request.pdfUrl());
        lesson.setDurationMinutes(request.durationMinutes());
        lesson.setPreview(request.isPreview());
        lesson.setSortOrder(request.sortOrder());
        section.addLesson(lesson);

        lessonRepository.save(lesson);
        sectionRepository.save(section);

        return mapLesson(lesson, currentUser);
    }

    public LessonResponse updateLesson(String courseId, String sectionId, String lessonId, CreateLessonRequest request, UserEntity currentUser) {
        UUID courseUuid = parseUuid(courseId, "Invalid course ID");
        UUID sectionUuid = parseUuid(sectionId, "Invalid section ID");
        UUID lessonUuid = parseUuid(lessonId, "Invalid lesson ID");

        CourseEntity course = courseRepository.findById(courseUuid)
                .orElseThrow(() -> new ResourceNotFoundException("Course not found"));
        SectionEntity section = sectionRepository.findById(sectionUuid)
                .orElseThrow(() -> new ResourceNotFoundException("Section not found"));
        LessonEntity lesson = lessonRepository.findById(lessonUuid)
                .orElseThrow(() -> new ResourceNotFoundException("Lesson not found"));

        if (!section.getCourse().getId().equals(course.getId())) {
            throw new BadRequestException("Section does not belong to the given course");
        }
        if (!lesson.getSection().getId().equals(section.getId())) {
            throw new BadRequestException("Lesson does not belong to the given section");
        }
        if (!course.getInstructorEmail().equalsIgnoreCase(currentUser.getEmail())) {
            throw new UnauthorizedException("You can only edit your own courses");
        }

        lesson.setTitle(request.title().trim());
        lesson.setDescription(request.description() == null ? "" : request.description().trim());
        lesson.setVideoUrl(request.videoUrl());
        lesson.setPdfUrl(request.pdfUrl());
        lesson.setDurationMinutes(request.durationMinutes());
        lesson.setPreview(request.isPreview());
        lesson.setSortOrder(request.sortOrder());
        lesson.setUpdatedAt(Instant.now());

        LessonEntity saved = lessonRepository.save(lesson);
        return mapLesson(saved, currentUser);
    }

    public void deleteLesson(String courseId, String sectionId, String lessonId, UserEntity currentUser) {
        UUID courseUuid = parseUuid(courseId, "Invalid course ID");
        UUID sectionUuid = parseUuid(sectionId, "Invalid section ID");
        UUID lessonUuid = parseUuid(lessonId, "Invalid lesson ID");

        CourseEntity course = courseRepository.findById(courseUuid)
                .orElseThrow(() -> new ResourceNotFoundException("Course not found"));
        SectionEntity section = sectionRepository.findById(sectionUuid)
                .orElseThrow(() -> new ResourceNotFoundException("Section not found"));
        LessonEntity lesson = lessonRepository.findById(lessonUuid)
                .orElseThrow(() -> new ResourceNotFoundException("Lesson not found"));

        if (!section.getCourse().getId().equals(course.getId())) {
            throw new BadRequestException("Section does not belong to the given course");
        }
        if (!lesson.getSection().getId().equals(section.getId())) {
            throw new BadRequestException("Lesson does not belong to the given section");
        }
        if (!course.getInstructorEmail().equalsIgnoreCase(currentUser.getEmail())) {
            throw new UnauthorizedException("You can only edit your own courses");
        }

        section.removeLesson(lesson);
        sectionRepository.save(section);
    }

    public CourseResponse getCourseDetails(String courseId, UserEntity currentUser) {
        UUID courseUuid = parseUuid(courseId, "Invalid course ID");
        CourseEntity course = courseRepository.findById(courseUuid)
                .orElseThrow(() -> new ResourceNotFoundException("Course not found"));

        if (course.isDeleted()) {
            throw new ResourceNotFoundException("Course has been deleted");
        }

        return mapCourse(course, currentUser);
    }

    public ReviewResponse addReview(String courseId, CreateReviewRequest request, UserEntity currentUser) {
        UUID courseUuid = parseUuid(courseId, "Invalid course ID");
        CourseEntity course = courseRepository.findById(courseUuid)
                .orElseThrow(() -> new ResourceNotFoundException("Course not found"));

        Optional<ReviewEntity> existing = reviewRepository.findByCourseIdAndUserEmail(course.getId(), currentUser.getEmail());
        ReviewEntity review;
        if (existing.isPresent()) {
            review = existing.get();
            review.setRating(request.rating());
            review.setComment(request.comment());
            review.setUpdatedAt(Instant.now());
        } else {
            review = new ReviewEntity();
            review.setCourseId(course.getId());
            review.setUserEmail(currentUser.getEmail());
            review.setUserFullName(currentUser.getFullName());
            review.setRating(request.rating());
            review.setComment(request.comment());
        }

        ReviewEntity saved = reviewRepository.save(review);

        // Recalculate averageRating and totalReviews
        List<ReviewEntity> reviews = reviewRepository.findByCourseId(course.getId());
        double avg = reviews.stream().mapToInt(ReviewEntity::getRating).average().orElse(0.0);
        course.setTotalReviews(reviews.size());
        course.setAverageRating(avg);
        courseRepository.save(course);

        return new ReviewResponse(saved.getId(), saved.getCourseId(), saved.getUserEmail(), saved.getUserFullName(), saved.getRating(), saved.getComment(), saved.getCreatedAt());
    }

    public List<ReviewResponse> getReviews(String courseId) {
        UUID courseUuid = parseUuid(courseId, "Invalid course ID");
        return reviewRepository.findByCourseId(courseUuid).stream()
                .map(r -> new ReviewResponse(r.getId(), r.getCourseId(), r.getUserEmail(), r.getUserFullName(), r.getRating(), r.getComment(), r.getCreatedAt()))
                .toList();
    }

    public void addToWishlist(String courseId, UserEntity currentUser) {
        UUID courseUuid = parseUuid(courseId, "Invalid course ID");
        if (!courseRepository.existsById(courseUuid)) {
            throw new ResourceNotFoundException("Course not found");
        }

        if (wishlistRepository.existsByUserEmailAndCourseId(currentUser.getEmail(), courseUuid)) {
            return; // Already added
        }

        WishlistEntity wishlist = new WishlistEntity();
        wishlist.setUserEmail(currentUser.getEmail());
        wishlist.setCourseId(courseUuid);
        wishlistRepository.save(wishlist);
    }

    public void removeFromWishlist(String courseId, UserEntity currentUser) {
        UUID courseUuid = parseUuid(courseId, "Invalid course ID");
        wishlistRepository.findByUserEmailAndCourseId(currentUser.getEmail(), courseUuid)
                .ifPresent(wishlistRepository::delete);
    }

    public List<CourseResponse> getWishlist(UserEntity currentUser) {
        List<WishlistEntity> wishlist = wishlistRepository.findByUserEmail(currentUser.getEmail());
        return wishlist.stream()
                .map(w -> courseRepository.findById(w.getCourseId()))
                .filter(Optional::isPresent)
                .map(Optional::get)
                .map(c -> mapCourse(c, currentUser))
                .toList();
    }

    public List<CourseResponse> searchCourses(CourseSearchRequest request, UserEntity currentUser) {
        Stream<CourseEntity> stream = courseRepository.findAll().stream()
                .filter(course -> !course.isDeleted());

        // For search endpoint, typically we only show published courses, unless the requester is the instructor or an admin
        stream = stream.filter(course -> course.isPublished() || (currentUser != null &&
                (currentUser.getRole() == Role.ADMIN || currentUser.getRole() == Role.SUPER_ADMIN ||
                        course.getInstructorEmail().equalsIgnoreCase(currentUser.getEmail()))));

        if (request.keyword() != null && !request.keyword().isBlank()) {
            String kw = request.keyword().toLowerCase();
            stream = stream.filter(c -> c.getTitle().toLowerCase().contains(kw) || c.getDescription().toLowerCase().contains(kw));
        }

        if (request.categorySlug() != null && !request.categorySlug().isBlank()) {
            stream = stream.filter(c -> c.getCategorySlug().equalsIgnoreCase(request.categorySlug()));
        }

        if (request.difficulty() != null && !request.difficulty().isBlank()) {
            stream = stream.filter(c -> c.getDifficulty().equalsIgnoreCase(request.difficulty()));
        }

        if (request.priceMin() != null) {
            stream = stream.filter(c -> c.getPrice() >= request.priceMin());
        }

        if (request.priceMax() != null) {
            stream = stream.filter(c -> c.getPrice() <= request.priceMax());
        }

        if (request.ratingMin() != null) {
            stream = stream.filter(c -> c.getAverageRating() >= request.ratingMin());
        }

        // Apply sorting
        String sortBy = request.sortBy() == null ? "createdat_desc" : request.sortBy().toLowerCase();
        Comparator<CourseEntity> comparator = switch (sortBy) {
            case "price_asc" -> Comparator.comparingDouble(CourseEntity::getPrice);
            case "price_desc" -> Comparator.comparingDouble(CourseEntity::getPrice).reversed();
            case "rating_desc" -> Comparator.comparingDouble(CourseEntity::getAverageRating).reversed();
            default -> Comparator.comparing(CourseEntity::getCreatedAt).reversed();
        };

        return stream.sorted(comparator)
                .map(c -> mapCourse(c, currentUser))
                .toList();
    }

    private UUID parseUuid(String id, String errorMessage) {
        try {
            return UUID.fromString(id);
        } catch (IllegalArgumentException ex) {
            throw new BadRequestException(errorMessage);
        }
    }

    private CourseResponse mapCourse(CourseEntity course, UserEntity currentUser) {
        List<SectionResponse> sections = course.getSections().stream()
                .map(section -> mapSection(section, currentUser))
                .toList();
        String instructorName = userRepository.findByEmail(course.getInstructorEmail())
                .map(UserEntity::getFullName)
                .orElse("Unknown Instructor");
        return new CourseResponse(
                course.getId(),
                course.getTitle(),
                course.getDescription(),
                course.getPrice(),
                course.getDurationHours(),
                course.getDifficulty(),
                course.getCategorySlug(),
                course.getInstructorEmail(),
                instructorName,
                course.getThumbnailUrl(),
                course.isPublished(),
                course.getAverageRating(),
                course.getTotalReviews(),
                course.getEnrolledCount(),
                sections
        );
    }

    private SectionResponse mapSection(SectionEntity section, UserEntity currentUser) {
        List<LessonResponse> lessons = section.getLessons().stream()
                .map(lesson -> mapLesson(lesson, currentUser))
                .toList();
        return new SectionResponse(
                section.getId(),
                section.getTitle(),
                section.getDescription(),
                lessons
        );
    }

    private LessonResponse mapLesson(LessonEntity lesson, UserEntity currentUser) {
        boolean hasAccess = false;
        if (currentUser != null) {
            hasAccess = currentUser.getRole() == Role.ADMIN ||
                    currentUser.getRole() == Role.SUPER_ADMIN ||
                    lesson.getSection().getCourse().getInstructorEmail().equalsIgnoreCase(currentUser.getEmail()) ||
                    enrollmentService.isEnrolled(currentUser.getEmail(), lesson.getSection().getCourse().getId());
        }

        // If the user doesn't have premium/instructor access and it's not a preview lesson, hide URLs
        String videoUrl = (lesson.isPreview() || hasAccess) ? lesson.getVideoUrl() : null;
        String pdfUrl = (lesson.isPreview() || hasAccess) ? lesson.getPdfUrl() : null;

        return new LessonResponse(
                lesson.getId(),
                lesson.getTitle(),
                lesson.getDescription(),
                videoUrl,
                pdfUrl,
                lesson.getDurationMinutes(),
                lesson.isPreview(),
                lesson.getSortOrder()
        );
    }
}
