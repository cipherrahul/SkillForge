# Memory.md

# Project Memory & Context

**Project:** SkillForge (Working Name)

**Purpose:** This document acts as the persistent project memory for developers and AI coding assistants. It records key architectural decisions, project goals, completed work, current priorities, and important constraints so future development remains consistent.

---

# 1. Project Overview

SkillForge is a **career-oriented online learning platform** designed for students, instructors, institutions, and recruiters.

Unlike traditional LMS platforms, SkillForge focuses on:

- Practical learning
- Industry projects
- Weekly doubt sessions
- Live mentoring
- AI-assisted learning
- Internship opportunities
- Placement support
- Multi-tenant SaaS for institutions

---

# 2. Current Technology Stack

## Backend

- Java 21
- Spring Boot 3
- Spring Security
- Spring Data JPA

## Database

- PostgreSQL
- Redis
- OpenSearch

## Event Processing

- Apache Kafka

## Storage

- AWS S3

## Mobile

- Flutter

## Web

- Next.js
- TypeScript
- Tailwind CSS

## Deployment

- Docker
- Kubernetes
- AWS
- GitHub Actions

---

# 3. Architecture Decisions

The project will:

✅ Start as a **Modular Monolith**

Later evolve into:

- Authentication Service
- Course Service
- Live Class Service
- Payment Service
- Notification Service
- AI Service
- Analytics Service

Only split services when scaling requires it.

---

# 4. Core User Roles

- Student
- Instructor
- Admin
- Super Admin
- Recruiter
- Institution

Each role has independent permissions managed through RBAC.

---

# 5. Core Modules

- Authentication
- User Management
- Course Marketplace
- Learning
- Live Classes
- Mentoring
- Assessments
- Certificates
- Payments
- Internship Portal
- Placement Portal
- Notifications
- AI Assistant
- Analytics
- Multi-Tenant Management

---

# 6. Product Priorities

Priority Order

1. Authentication
2. Course Marketplace
3. Learning Experience
4. Payments
5. Live Classes
6. Mentoring
7. AI Features
8. Placement
9. Multi-Tenant SaaS
10. Advanced Analytics

---

# 7. UI/UX Decisions

Theme

- White-first
- Modern
- Minimal
- Professional

Primary Color

```
#2563EB
```

Student Navigation

```
Home

My Learning

Explore

Community

Profile
```

Instructor Navigation

```
Dashboard

Courses

Live

Analytics

Profile
```

---

# 8. Development Conventions

Always

- Follow Clean Architecture
- Use DTOs
- Use feature-based modules
- Write RESTful APIs
- Write reusable components
- Write production-ready code

Never

- Put business logic in controllers
- Expose entities directly
- Duplicate logic
- Hardcode configuration
- Break API contracts

---

# 9. Current Milestone

Current Focus

```
All Backend Setup Completed (SaaS Excluded)
```

The platform is fully deployable and verified.

---

# 10. Known Constraints

- Mobile-first design
- Low-latency API responses
- Scalable to millions of users
- Multi-tenant support
- Enterprise-ready security
- High code maintainability

---

# 11. Future Vision

The platform should evolve into an ecosystem where:

- Students learn
- Instructors teach and earn
- Institutions operate branded learning portals
- Recruiters hire verified talent
- AI provides personalized guidance throughout the learning journey

---

# 12. Engineering Decisions Log

| Decision | Status |
|----------|--------|
| Java 21 + Spring Boot 3 | ✅ Approved |
| PostgreSQL as primary DB | ✅ Approved |
| Redis for caching | ✅ Approved |
| Kafka for events | ✅ Approved |
| Flutter for mobile | ✅ Approved |
| Next.js for web | ✅ Approved |
| AWS for deployment | ✅ Approved |
| Modular Monolith first | ✅ Approved |
| White-first UI | ✅ Approved |
| AI-powered learning features | ✅ Approved |

---

# 13. Definition of Success

The project is successful when it:

- Delivers a premium learning experience
- Supports millions of users reliably
- Enables instructors to build sustainable businesses
- Helps students become job-ready
- Provides institutions with a scalable SaaS platform
- Maintains clean, secure, and maintainable code

---

# 14. AI Assistant Instructions

When contributing to this project, always:

- Read `PRD.md` first to understand business goals.
- Follow `Architecture.md` for technical decisions.
- Enforce `Rules.md` for coding standards.
- Build features according to `Phases.md`.
- Follow `Design.md` for UI consistency.
- Update this `Memory.md` whenever major architectural decisions, completed milestones, or priorities change.

---

# 15. Change Log

## v1.10

- Completed all Phase 12 features: deep health verification latency diagnostics (database latency check, local file storage timing), live JVM metrics (heap volume size, active threads counts), CDN georouting edge translations, and system security event audit logs.
- Integrated comprehensive automated integration tests for all deep health diagnostic and CDN edge route APIs.

## v1.9

- Completed all Phase 11 features: mobile push notification device token registry, simulated dispatcher notification transaction logs, streamlined student mobile dashboard endpoints, instructor mobile control panels (earnings, pending reviews), and course batch offline sync manifest compile.
- Integrated comprehensive automated integration tests for all mobile-optimized sync and push APIs.

## v1.1

- Completed all Phase 2 remaining features: Lesson CRUD, Video/PDF uploads, Reviews & Ratings, Course Wishlist, Course Preview, and Advanced Search/Filters.
- Integrated comprehensive automated integration tests for all marketplace APIs.

## v1.0

- Initial project documentation created
- Core architecture finalized
- Development roadmap defined
- UI/UX standards established
- Technology stack approved

---

**Document Status:** Active

**Last Updated:** Phase 3 Complete

**References:**

- `PRD.md`
- `Architecture.md`
- `Rules.md`
- `Phases.md`
- `Design.md`