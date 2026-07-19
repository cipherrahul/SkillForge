# SkillForge Backend

## Phase 1 - Authentication & User Management

This backend module is the starting point for the SkillForge platform.

### Implemented
- Spring Boot 3 application bootstrap
- Feature-based auth module for registration and login
- JWT access and refresh token support
- BCrypt password hashing
- Protected profile endpoints
- Profile update support
- Centralized API response and exception handling
- Security configuration with JWT filter
- OpenAPI documentation setup
- Docker and database compose scaffolding

### Next Steps
1. Add role-based authorization rules for admin and instructor flows
2. Integrate PostgreSQL as the default datasource
3. Add password reset and email OTP flows
4. Add course and enrollment modules for Phase 2
