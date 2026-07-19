package com.skillforge.community.repository;

import com.skillforge.community.entity.GroupMemberEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface GroupMemberRepository extends JpaRepository<GroupMemberEntity, UUID> {
    Optional<GroupMemberEntity> findByGroupIdAndUserEmail(UUID groupId, String userEmail);
    List<GroupMemberEntity> findByUserEmail(String userEmail);
}
