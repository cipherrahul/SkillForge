package com.skillforge.config;

import com.skillforge.auth.entity.Role;
import com.skillforge.auth.entity.UserEntity;
import com.skillforge.auth.repository.UserRepository;
import com.skillforge.career.entity.JobListingEntity;
import com.skillforge.career.repository.JobListingRepository;
import com.skillforge.course.entity.CategoryEntity;
import com.skillforge.course.entity.CourseEntity;
import com.skillforge.course.repository.CategoryRepository;
import com.skillforge.course.repository.CourseRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class DatabaseSeeder implements CommandLineRunner {

    private final UserRepository userRepository;
    private final CategoryRepository categoryRepository;
    private final CourseRepository courseRepository;
    private final JobListingRepository jobListingRepository;
    private final PasswordEncoder passwordEncoder;

    public DatabaseSeeder(UserRepository userRepository,
                          CategoryRepository categoryRepository,
                          CourseRepository courseRepository,
                          JobListingRepository jobListingRepository,
                          PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.categoryRepository = categoryRepository;
        this.courseRepository = courseRepository;
        this.jobListingRepository = jobListingRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) throws Exception {
        seedUsers();
        seedCategories();
        seedCourses();
        seedJobListings();
    }

    private void seedUsers() {
        if (!userRepository.existsByEmail("student@skillforge.com")) {
            UserEntity student = new UserEntity();
            student.setEmail("student@skillforge.com");
            student.setFullName("Rahul Sharma");
            student.setPasswordHash(passwordEncoder.encode("password123"));
            student.setRole(Role.STUDENT);
            userRepository.save(student);
        }

        if (!userRepository.existsByEmail("instructor@skillforge.com")) {
            UserEntity instructor = new UserEntity();
            instructor.setEmail("instructor@skillforge.com");
            instructor.setFullName("Dr. Aris Thorne");
            instructor.setPasswordHash(passwordEncoder.encode("password123"));
            instructor.setRole(Role.INSTRUCTOR);
            userRepository.save(instructor);
        }

        if (!userRepository.existsByEmail("admin@skillforge.com")) {
            UserEntity admin = new UserEntity();
            admin.setEmail("admin@skillforge.com");
            admin.setFullName("Platform Administrator");
            admin.setPasswordHash(passwordEncoder.encode("password123"));
            admin.setRole(Role.ADMIN);
            userRepository.save(admin);
        }
    }

    private void seedCategories() {
        if (categoryRepository.count() == 0) {
            createCategory("Web Development", "web-development", "Modern frontend and backend web technologies.");
            createCategory("Mobile Development", "mobile-development", "Cross-platform mobile apps with Flutter & React Native.");
            createCategory("Backend Architecture", "backend-architecture", "Microservices, Spring Boot, and Enterprise Java.");
            createCategory("Data Science & AI", "data-science-ai", "Machine Learning, Deep Learning, and LLM Engineering.");
        }
    }

    private void createCategory(String name, String slug, String description) {
        CategoryEntity c = new CategoryEntity();
        c.setName(name);
        c.setSlug(slug);
        c.setDescription(description);
        categoryRepository.save(c);
    }

    private void seedCourses() {
        if (courseRepository.count() == 0) {
            CourseEntity c1 = new CourseEntity();
            c1.setTitle("Full-Stack Web Development (React & Node.js)");
            c1.setDescription("Master modern web development from scratch with hands-on projects.");
            c1.setPrice(4999.0);
            c1.setDurationHours(48);
            c1.setDifficulty("Beginner");
            c1.setCategorySlug("web-development");
            c1.setInstructorEmail("instructor@skillforge.com");
            c1.setThumbnailUrl("");
            c1.setPublished(true);
            courseRepository.save(c1);

            CourseEntity c2 = new CourseEntity();
            c2.setTitle("Flutter & Dart: Complete Cross-Platform Guide");
            c2.setDescription("Build beautiful mobile and web applications with Flutter.");
            c2.setPrice(3499.0);
            c2.setDurationHours(32);
            c2.setDifficulty("Intermediate");
            c2.setCategorySlug("mobile-development");
            c2.setInstructorEmail("instructor@skillforge.com");
            c2.setThumbnailUrl("");
            c2.setPublished(true);
            courseRepository.save(c2);

            CourseEntity c3 = new CourseEntity();
            c3.setTitle("Java Spring Boot & Microservices Architecture");
            c3.setDescription("Enterprise backend development using Spring Boot and Docker.");
            c3.setPrice(5999.0);
            c3.setDurationHours(60);
            c3.setDifficulty("Advanced");
            c3.setCategorySlug("backend-architecture");
            c3.setInstructorEmail("instructor@skillforge.com");
            c3.setThumbnailUrl("");
            c3.setPublished(true);
            courseRepository.save(c3);
        }
    }

    private void seedJobListings() {
        if (jobListingRepository.count() == 0) {
            JobListingEntity j1 = new JobListingEntity();
            j1.setTitle("Frontend Developer Intern");
            j1.setCompanyName("Google Cloud Solutions");
            j1.setLocation("Bangalore (Hybrid)");
            j1.setType("INTERNSHIP");
            j1.setSalaryRange("₹35,000 / mo");
            j1.setDescription("Work with world-class engineering teams to build modern cloud dashboard components.");
            j1.setRequirements("React.js, TypeScript, Tailwind");
            j1.setPostedByEmail("admin@skillforge.com");
            j1.setActive(true);
            jobListingRepository.save(j1);

            JobListingEntity j2 = new JobListingEntity();
            j2.setTitle("Flutter Mobile App Intern");
            j2.setCompanyName("Razorpay Technologies");
            j2.setLocation("Remote");
            j2.setType("INTERNSHIP");
            j2.setSalaryRange("₹40,000 / mo");
            j2.setDescription("Help engineer next-gen mobile payment checkout screens and transaction dashboards.");
            j2.setRequirements("Flutter, Dart, REST APIs");
            j2.setPostedByEmail("admin@skillforge.com");
            j2.setActive(true);
            jobListingRepository.save(j2);

            JobListingEntity j3 = new JobListingEntity();
            j3.setTitle("Senior Software Engineer (Full Stack)");
            j3.setCompanyName("Goldman Sachs");
            j3.setLocation("Bengaluru, KA");
            j3.setType("JOB");
            j3.setSalaryRange("18 - 24 LPA");
            j3.setDescription("Engineers will design high-throughput financial trading systems and real-time ledger engines.");
            j3.setRequirements("Java, Spring Boot, React, Kafka");
            j3.setPostedByEmail("admin@skillforge.com");
            j3.setActive(true);
            jobListingRepository.save(j3);
        }
    }
}
