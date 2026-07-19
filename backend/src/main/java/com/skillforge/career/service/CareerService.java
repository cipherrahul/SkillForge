package com.skillforge.career.service;

import com.skillforge.auth.entity.UserEntity;
import com.skillforge.common.exception.BadRequestException;
import com.skillforge.common.exception.ResourceNotFoundException;
import com.skillforge.career.dto.*;
import com.skillforge.career.entity.*;
import com.skillforge.career.repository.*;
import com.skillforge.storage.service.StorageService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
public class CareerService {
    private final JobListingRepository jobListingRepository;
    private final ResumeRepository resumeRepository;
    private final JobApplicationRepository jobApplicationRepository;
    private final MockInterviewRepository mockInterviewRepository;
    private final StorageService storageService;

    public CareerService(JobListingRepository jobListingRepository,
                         ResumeRepository resumeRepository,
                         JobApplicationRepository jobApplicationRepository,
                         MockInterviewRepository mockInterviewRepository,
                         StorageService storageService) {
        this.jobListingRepository = jobListingRepository;
        this.resumeRepository = resumeRepository;
        this.jobApplicationRepository = jobApplicationRepository;
        this.mockInterviewRepository = mockInterviewRepository;
        this.storageService = storageService;
    }

    @Transactional
    public JobResponse createJob(CreateJobRequest request, UserEntity currentUser) {
        JobListingEntity job = new JobListingEntity();
        job.setTitle(request.title().trim());
        job.setCompanyName(request.companyName().trim());
        job.setLocation(request.location());
        job.setType(request.type().toUpperCase().trim());
        job.setDescription(request.description().trim());
        job.setRequirements(request.requirements());
        job.setSalaryRange(request.salaryRange());
        job.setPostedByEmail(currentUser.getEmail());
        job.setCreatedBy(currentUser.getEmail());
        job.setUpdatedBy(currentUser.getEmail());

        JobListingEntity saved = jobListingRepository.save(job);
        return mapJob(saved);
    }

    public List<JobResponse> getJobs(String type) {
        List<JobListingEntity> list = (type != null && !type.isBlank())
                ? jobListingRepository.findByType(type.toUpperCase().trim())
                : jobListingRepository.findAll();

        return list.stream()
                .filter(j -> !j.isDeleted() && j.isActive())
                .map(this::mapJob)
                .toList();
    }

    public JobResponse getJobDetails(UUID jobId) {
        JobListingEntity job = jobListingRepository.findById(jobId)
                .orElseThrow(() -> new ResourceNotFoundException("Job listing not found"));
        return mapJob(job);
    }

    @Transactional
    public String buildResume(BuildResumeRequest request, UserEntity currentUser) {
        String resumeText = """
                ==================================================
                                  STUDENT RESUME
                ==================================================
                Full Name: %s
                Email:     %s
                
                EDUCATION:
                %s
                
                EXPERIENCE:
                %s
                
                SKILLS:
                %s
                
                PROJECTS:
                %s
                ==================================================
                """.formatted(request.fullName(), currentUser.getEmail(),
                request.education() != null ? request.education() : "Not specified",
                request.experience() != null ? request.experience() : "Not specified",
                request.skills() != null ? request.skills() : "Not specified",
                request.projects() != null ? request.projects() : "Not specified");

        String filename = "resume_" + currentUser.getEmail().replace("@", "_").replace(".", "_") + ".txt";
        String pdfUrl = storageService.storeBytes(resumeText.getBytes(), filename);

        ResumeEntity resume = resumeRepository.findByUserEmail(currentUser.getEmail())
                .orElseGet(() -> {
                    ResumeEntity r = new ResumeEntity();
                    r.setUserEmail(currentUser.getEmail());
                    r.setCreatedBy(currentUser.getEmail());
                    return r;
                });

        resume.setFullName(request.fullName());
        resume.setEducation(request.education());
        resume.setExperience(request.experience());
        resume.setSkills(request.skills());
        resume.setProjects(request.projects());
        resume.setPdfUrl(pdfUrl);
        resume.setUpdatedAt(Instant.now());
        resume.setUpdatedBy(currentUser.getEmail());
        resumeRepository.save(resume);

        return pdfUrl;
    }

    @Transactional
    public ApplicationResponse applyJob(UUID jobId, ApplyJobRequest request, UserEntity currentUser) {
        JobListingEntity job = jobListingRepository.findById(jobId)
                .orElseThrow(() -> new ResourceNotFoundException("Job listing not found"));

        ResumeEntity resume = resumeRepository.findByUserEmail(currentUser.getEmail())
                .orElseThrow(() -> new BadRequestException("Please construct your resume first before applying"));

        JobApplicationEntity app = new JobApplicationEntity();
        app.setJobId(jobId);
        app.setStudentEmail(currentUser.getEmail());
        app.setResumeUrl(resume.getPdfUrl());
        app.setStatus("SUBMITTED");
        app.setCoverLetter(request.coverLetter());
        app.setCreatedBy(currentUser.getEmail());
        app.setUpdatedBy(currentUser.getEmail());

        JobApplicationEntity saved = jobApplicationRepository.save(app);
        return mapApplication(saved, job.getTitle(), job.getCompanyName());
    }

    public List<ApplicationResponse> getApplications(String studentEmail, UUID jobId) {
        List<JobApplicationEntity> list;
        if (studentEmail != null && !studentEmail.isBlank()) {
            list = jobApplicationRepository.findByStudentEmail(studentEmail);
        } else if (jobId != null) {
            list = jobApplicationRepository.findByJobId(jobId);
        } else {
            list = jobApplicationRepository.findAll();
        }

        return list.stream()
                .filter(a -> !a.isDeleted())
                .map(a -> {
                    JobListingEntity job = jobListingRepository.findById(a.getJobId()).orElse(null);
                    String title = job != null ? job.getTitle() : "Unknown Job";
                    String company = job != null ? job.getCompanyName() : "Unknown Company";
                    return mapApplication(a, title, company);
                })
                .toList();
    }

    @Transactional
    public ApplicationResponse updateApplicationStatus(UUID applicationId, String status, UserEntity currentUser) {
        JobApplicationEntity app = jobApplicationRepository.findById(applicationId)
                .orElseThrow(() -> new ResourceNotFoundException("Job application not found"));

        app.setStatus(status.toUpperCase().trim());
        app.setUpdatedAt(Instant.now());
        app.setUpdatedBy(currentUser.getEmail());
        jobApplicationRepository.save(app);

        JobListingEntity job = jobListingRepository.findById(app.getJobId()).orElse(null);
        String title = job != null ? job.getTitle() : "Unknown Job";
        String company = job != null ? job.getCompanyName() : "Unknown Company";

        return mapApplication(app, title, company);
    }

    @Transactional
    public MockInterviewResponse bookMockInterview(BookInterviewRequest request, UserEntity currentUser) {
        MockInterviewEntity mi = new MockInterviewEntity();
        mi.setStudentEmail(currentUser.getEmail());
        mi.setTopic(request.topic().trim());
        mi.setScheduledTime(request.scheduledTime());
        mi.setStatus("SCHEDULED");
        mi.setCreatedBy(currentUser.getEmail());
        mi.setUpdatedBy(currentUser.getEmail());

        MockInterviewEntity saved = mockInterviewRepository.save(mi);
        return mapMockInterview(saved);
    }

    @Transactional
    public MockInterviewResponse submitInterviewFeedback(UUID interviewId, SubmitFeedbackRequest request, UserEntity currentUser) {
        MockInterviewEntity mi = mockInterviewRepository.findById(interviewId)
                .orElseThrow(() -> new ResourceNotFoundException("Mock interview not found"));

        mi.setFeedback(request.feedback().trim());
        mi.setScore(request.score());
        mi.setStatus("COMPLETED");
        mi.setUpdatedAt(Instant.now());
        mi.setUpdatedBy(currentUser.getEmail());

        MockInterviewEntity saved = mockInterviewRepository.save(mi);
        return mapMockInterview(saved);
    }

    public List<MockInterviewResponse> getMockInterviews(String studentEmail) {
        return mockInterviewRepository.findByStudentEmail(studentEmail).stream()
                .filter(m -> !m.isDeleted())
                .map(this::mapMockInterview)
                .toList();
    }

    public PlacementAnalyticsResponse getAnalytics() {
        List<JobListingEntity> jobs = jobListingRepository.findAll();
        long totalJobs = jobs.stream().filter(j -> !j.isDeleted() && j.getType().equalsIgnoreCase("JOB")).count();
        long totalInternships = jobs.stream().filter(j -> !j.isDeleted() && j.getType().equalsIgnoreCase("INTERNSHIP")).count();

        List<JobApplicationEntity> apps = jobApplicationRepository.findAll().stream().filter(a -> !a.isDeleted()).toList();
        long totalApplications = apps.size();
        long totalShortlisted = apps.stream()
                .filter(a -> a.getStatus().equalsIgnoreCase("SHORTLISTED") || a.getStatus().equalsIgnoreCase("OFFERED"))
                .count();

        double placementRate = totalApplications > 0 ? ((double) totalShortlisted / totalApplications) * 100.0 : 0.0;

        return new PlacementAnalyticsResponse(totalJobs, totalInternships, totalApplications, totalShortlisted, placementRate);
    }

    private JobResponse mapJob(JobListingEntity j) {
        return new JobResponse(
                j.getId(),
                j.getTitle(),
                j.getCompanyName(),
                j.getLocation(),
                j.getType(),
                j.getDescription(),
                j.getRequirements(),
                j.getSalaryRange(),
                j.getPostedByEmail(),
                j.isActive(),
                j.getCreatedAt()
        );
    }

    private ApplicationResponse mapApplication(JobApplicationEntity a, String jobTitle, String companyName) {
        return new ApplicationResponse(
                a.getId(),
                a.getJobId(),
                jobTitle,
                companyName,
                a.getStudentEmail(),
                a.getResumeUrl(),
                a.getStatus(),
                a.getCoverLetter(),
                a.getCreatedAt()
        );
    }

    private MockInterviewResponse mapMockInterview(MockInterviewEntity m) {
        return new MockInterviewResponse(
                m.getId(),
                m.getStudentEmail(),
                m.getTopic(),
                m.getScheduledTime(),
                m.getStatus(),
                m.getFeedback(),
                m.getScore(),
                m.getCreatedAt()
        );
    }
}
