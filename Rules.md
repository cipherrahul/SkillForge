# Development Rules & Engineering Standards

**Project:** SkillForge (Working Name)

**Tech Stack:** Java 21 • Spring Boot 3 • PostgreSQL • Redis • Kafka • Flutter • Next.js

**Purpose:** This document defines the mandatory engineering, architecture, coding, and AI development rules for the project. Every contributor (human or AI) must follow these standards.

---

# 1. Core Development Principles

Every implementation must follow:

- Clean Architecture
- SOLID Principles
- DRY (Don't Repeat Yourself)
- KISS (Keep It Simple)
- YAGNI (Don't Build Unnecessary Features)
- Domain Driven Design (DDD)
- Secure by Default
- API First Development
- Mobile First Thinking

---

# 2. Code Quality Rules

## Mandatory

✓ Write readable code.

✓ Prefer clarity over cleverness.

✓ Keep methods small.

✓ Single Responsibility Principle.

✓ No duplicated logic.

✓ No hardcoded values.

✓ No unnecessary comments.

✓ Every class should have one clear purpose.

✓ Follow Java naming conventions.

---

# 3. Package Structure

Never organize code by technical layers only.

Always organize by **feature/module**.

Correct:

```
course/
    controller/
    service/
    repository/
    entity/
    dto/
```

Wrong:

```
controllers/
services/
repositories/
entities/
```

---

# 4. Controller Rules

Controllers should only

- Validate Request
- Call Service
- Return Response

Controllers must NEVER

- Write business logic
- Access database
- Contain calculations
- Perform validations beyond request validation

---

# 5. Service Rules

Services contain

- Business Logic
- Domain Rules
- Transaction Management
- Event Publishing

Services must NEVER

- Generate SQL
- Handle HTTP requests
- Return Entity Objects directly

---

# 6. Repository Rules

Repositories only perform

- CRUD
- Custom Queries

Repositories should NEVER

- Implement business logic
- Call other services
- Contain validation logic

---

# 7. DTO Rules

Always use DTOs.

Never expose Entity objects directly.

Every API should have

```
Request DTO

↓

Validation

↓

Service

↓

Response DTO
```

---

# 8. Validation Rules

Every request must be validated.

Examples

- Email
- Password
- Mobile Number
- Price
- Course Name
- Duration

Never trust client-side validation.

---

# 9. Exception Handling

Use centralized exception handling.

Never use

```
try {

}
catch(Exception e){

}
```

inside controllers.

Create custom exceptions.

Examples

- UserNotFoundException
- CourseNotFoundException
- PaymentFailedException
- UnauthorizedException

---

# 10. Authentication Rules

Authentication uses

- JWT
- Refresh Token
- Google OAuth
- OTP Login

Passwords

- BCrypt only

Never store

- Plain passwords
- Tokens
- Sensitive information

---

# 11. Authorization Rules

Role Based Access Control

Roles

- Student
- Instructor
- Admin
- Super Admin
- Recruiter

Always verify permissions before executing business operations.

---

# 12. Database Rules

PostgreSQL is the primary database.

Rules

- Proper indexes
- Foreign Keys
- UUID IDs
- Soft Delete
- Audit Columns

Every table contains

```
id

created_at

updated_at

created_by

updated_by

is_deleted
```

---

# 13. API Standards

REST Naming

Correct

```
GET /courses

GET /courses/{id}

POST /courses

PUT /courses/{id}

DELETE /courses/{id}
```

Wrong

```
/getCourse

/addCourse

/deleteCourse
```

---

# 14. Logging Rules

Never use

```
System.out.println()
```

Always use structured logging.

Log

- Errors
- Warnings
- Important Business Events

Never log

- Passwords
- Tokens
- Payment Details

---

# 15. Security Rules

Mandatory

- HTTPS
- JWT Authentication
- Input Validation
- SQL Injection Protection
- XSS Protection
- CSRF Protection
- Rate Limiting

Never trust user input.

---

# 16. Performance Rules

Avoid

- N+1 Queries
- Unnecessary Database Calls
- Large API Responses

Use

- Pagination
- Redis Cache
- Lazy Loading
- Batch Processing

---

# 17. API Response Format

Every API should return

```json
{
  "success": true,
  "message": "Course created successfully",
  "data": {},
  "timestamp": "",
  "path": ""
}
```

Errors

```json
{
  "success": false,
  "message": "Course not found",
  "errorCode": "COURSE_NOT_FOUND"
}
```

---

# 18. Git Rules

Branch Naming

```
feature/course-module

feature/live-class

bugfix/payment

hotfix/login

release/v1.0
```

Commit Format

```
feat:

fix:

refactor:

docs:

test:

chore:
```

---

# 19. Testing Rules

Every feature requires

- Unit Tests
- Integration Tests
- API Tests

Critical modules

- Authentication
- Payments
- Certificates

must have high test coverage.

---

# 20. Documentation Rules

Every module must include

- README
- API Documentation
- Architecture Notes
- Sequence Diagram (if applicable)

Swagger/OpenAPI documentation is mandatory.

---

# 21. UI/UX Rules

- White-first interface
- Consistent spacing
- Reusable components
- Responsive layouts
- Accessibility support
- Loading states
- Error states
- Empty states

---

# 22. AI Development Rules

When using AI to generate code

Always

- Follow existing architecture
- Reuse existing services
- Write production-ready code
- Preserve backward compatibility
- Generate tests where applicable

Never

- Change architecture without approval
- Duplicate existing logic
- Introduce new libraries without justification
- Break API contracts

---

# 23. Definition of Done (DoD)

A feature is considered complete only if:

- Business requirements are implemented
- Code review completed
- Tests pass
- APIs documented
- Validation added
- Logging implemented
- Security verified
- Performance reviewed
- UI reviewed
- Ready for deployment

---

# 24. Engineering Philosophy

Every line of code should be:

- Simple
- Maintainable
- Secure
- Scalable
- Testable
- Reusable
- Consistent
- Production Ready

**Golden Rule:**

> Build for the next 5 years, not just the next release. Every feature should be designed to scale, be easy to maintain, and deliver measurable value to students, instructors, institutions, and recruiters.

---

**Document Status:** Draft v1.0