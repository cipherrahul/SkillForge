package com.skillforge.liveclass.repository;

import com.skillforge.liveclass.entity.AttendanceEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface AttendanceRepository extends JpaRepository<AttendanceEntity, UUID> {
    List<AttendanceEntity> findByLiveSessionId(UUID liveSessionId);
    Optional<AttendanceEntity> findByLiveSessionIdAndUserEmail(UUID liveSessionId, String userEmail);
}
