# System Architecture

**Project:** SkillForge (Working Name)

**Architecture Style:** Modular Monolith → Microservices Ready

**Backend:** Java 21 + Spring Boot 3

**Goal:** Build an enterprise-grade, scalable, maintainable, and high-performance online learning platform capable of serving millions of users.

---

# 1. Architecture Principles

The system follows the following principles:

- Clean Architecture
- Domain Driven Design (DDD)
- SOLID Principles
- Modular Development
- Event-Driven Communication
- API First
- Mobile First
- Cloud Native
- Security by Design
- Scalable by Default

---

# 2. High-Level Architecture

```
                Flutter Mobile App
                       │
                Next.js Web Portal
                       │
              Admin Dashboard (Next.js)
                       │
                  HTTPS / REST API
                       │
                 Spring Boot Backend
                       │
        ┌──────────────┼──────────────┐
        │              │              │
   PostgreSQL      Redis Cache     OpenSearch
        │              │              │
        └──────────────┼──────────────┘
                       │
                    Kafka Events
                       │
         Email • Push • Analytics • AI
                       │
                  AWS S3 Storage
                       │
                 LiveKit Video Server
```

---

# 3. Development Strategy

The application starts as a **Modular Monolith**.

Advantages:

- Easier deployment
- Faster development
- Simpler debugging
- Lower infrastructure cost
- Shared transactions
- Easier testing

When traffic grows (500K+ users), individual modules can be extracted into microservices without major rewrites.

---

# 4. Core Modules

## Authentication

Responsibilities

- Login
- Registration
- JWT
- Refresh Token
- OTP
- OAuth
- Roles
- Permissions

---

## User Module

Handles

- Students
- Instructors
- Admins
- Super Admins
- Recruiters

---

## Course Module

Responsible for

- Categories
- Courses
- Chapters
- Lessons
- Attachments
- Pricing
- Reviews
- Ratings

---

## Enrollment Module

Handles

- Purchases
- Enrollment
- Progress
- Completion
- Course Access

---

## Learning Module

Features

- Video Learning
- PDFs
- Assignments
- Coding Practice
- Notes
- Bookmarks
- Progress Tracking

---

## Live Class Module

Responsible for

- Weekly Classes
- Mentoring Sessions
- Meeting Schedule
- Attendance
- Recordings

---

## Assessment Module

Handles

- Quiz
- MCQ
- Coding Tests
- Assignments
- Auto Evaluation
- Result Publishing

---

## Certificate Module

Responsible for

- Certificate Generation
- QR Verification
- Download
- Validation

---

## Internship Module

Features

- Internship Listings
- Applications
- Company Dashboard
- Shortlisting

---

## Placement Module

Features

- Resume
- Mock Interview
- Job Portal
- Recruiter Dashboard

---

## Payment Module

Handles

- Orders
- Payments
- Refunds
- Coupons
- Invoices

---

## Notification Module

Supports

- Email
- Push Notification
- SMS
- In-App Notifications

---

## AI Module

Responsible for

- AI Tutor
- Quiz Generation
- Notes Generation
- Learning Roadmaps
- Recommendation Engine

---

## Analytics Module

Tracks

- Revenue
- Student Activity
- Instructor Growth
- Platform Metrics
- Business KPIs

---

# 5. Database Strategy

## Primary Database

PostgreSQL

Stores

- Users
- Courses
- Payments
- Enrollments
- Assignments
- Certificates

---

## Cache

Redis

Stores

- Sessions
- OTP
- JWT Blacklist
- Frequently Accessed Data
- Rate Limiting

---

## Search

OpenSearch

Indexes

- Courses
- Instructors
- Skills
- Blogs
- Jobs

---

# 6. Event-Driven Architecture

Kafka handles asynchronous processing.

Events

```
Student Registered

↓

Welcome Email

↓

Analytics

↓

Recommendation Engine

------------------------

Course Purchased

↓

Enrollment

↓

Invoice

↓

Notification

↓

Analytics

------------------------

Course Completed

↓

Certificate

↓

Achievement

↓

Placement Recommendation

↓

Email
```

---

# 7. Security Architecture

Authentication

- JWT Access Token
- Refresh Token
- Google OAuth

Authorization

- RBAC
- Permission Based Access

Protection

- HTTPS
- Password Encryption
- SQL Injection Protection
- XSS Protection
- CSRF Protection
- Rate Limiting
- Audit Logs

---

# 8. File Storage

AWS S3 stores

- Videos
- PDFs
- Images
- Certificates
- Assignments

Videos are delivered through a CDN with adaptive HLS streaming for smooth playback.

---

# 9. Deployment Architecture

```
Internet

↓

Cloudflare CDN

↓

NGINX

↓

Spring Boot Application

↓

PostgreSQL

↓

Redis

↓

Kafka

↓

OpenSearch

↓

AWS S3
```

Containerization

- Docker
- Kubernetes

CI/CD

- GitHub Actions

Hosting

- AWS

---

# 10. Monitoring

Monitoring Stack

- Prometheus
- Grafana
- OpenTelemetry
- Sentry

Logging

- Structured JSON Logs
- Centralized Log Collection
- Error Alerts

Health Checks

- Spring Boot Actuator
- Readiness Probe
- Liveness Probe

---

# 11. Scalability Strategy

Horizontal Scaling

- Stateless APIs
- Load Balancer
- Multiple Application Instances

Database

- Read Replicas
- Connection Pooling
- Index Optimization

Caching

- Redis
- CDN
- Query Optimization

Asynchronous Processing

- Kafka
- Background Workers
- Scheduled Jobs

---

# 12. Recommended Project Structure

```
backend/
│
├── auth/
├── user/
├── course/
├── enrollment/
├── learning/
├── liveclass/
├── assessment/
├── certificate/
├── internship/
├── placement/
├── payment/
├── notification/
├── analytics/
├── ai/
├── common/
├── config/
├── security/
├── infrastructure/
└── shared/
```

Each module contains:

```
controller/
service/
repository/
entity/
dto/
mapper/
validator/
exception/
config/
event/
```

---

# 13. Future Microservice Extraction

When scale demands, extract these services independently:

- Authentication Service
- Course Service
- Live Class Service
- Payment Service
- Notification Service
- AI Service
- Analytics Service
- Search Service
- Placement Service

The frontend remains unchanged because communication occurs through stable REST APIs.

---

# 14. Architecture Goals

The platform must be:

- Secure by default
- Highly scalable
- Cloud native
- Modular
- Testable
- Maintainable
- AI-ready
- Mobile-first
- Enterprise-grade
- Multi-tenant ready

---