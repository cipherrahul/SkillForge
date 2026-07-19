package com.skillforge.auth.service;

import com.skillforge.auth.entity.Permission;
import com.skillforge.auth.entity.Role;
import com.skillforge.auth.entity.UserEntity;
import com.skillforge.common.exception.UnauthorizedException;
import org.springframework.stereotype.Service;

import java.util.Set;

@Service
public class AuthorizationService {
    private static final Set<Permission> STUDENT_PERMISSIONS = Set.of(Permission.READ_COURSES);
    private static final Set<Permission> INSTRUCTOR_PERMISSIONS = Set.of(Permission.READ_COURSES, Permission.MANAGE_COURSES);
    private static final Set<Permission> ADMIN_PERMISSIONS = Set.of(Permission.READ_COURSES, Permission.MANAGE_COURSES, Permission.MANAGE_USERS);
    private static final Set<Permission> SUPER_ADMIN_PERMISSIONS = Set.of(Permission.READ_COURSES, Permission.MANAGE_COURSES, Permission.MANAGE_USERS, Permission.MANAGE_PAYMENTS);

    public void assertPermission(UserEntity user, Permission permission) {
        if (user == null || user.isDeleted()) {
            throw new UnauthorizedException("User is not authorized");
        }

        Set<Permission> allowed = switch (user.getRole()) {
            case STUDENT -> STUDENT_PERMISSIONS;
            case INSTRUCTOR -> INSTRUCTOR_PERMISSIONS;
            case ADMIN -> ADMIN_PERMISSIONS;
            case SUPER_ADMIN -> SUPER_ADMIN_PERMISSIONS;
            case RECRUITER -> STUDENT_PERMISSIONS;
        };

        if (!allowed.contains(permission)) {
            throw new UnauthorizedException("User does not have the required permission");
        }
    }

    public boolean hasRole(UserEntity user, Role role) {
        return user != null && user.getRole() == role;
    }
}
