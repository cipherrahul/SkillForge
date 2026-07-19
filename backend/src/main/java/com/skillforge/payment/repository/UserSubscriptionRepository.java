package com.skillforge.payment.repository;

import com.skillforge.payment.entity.SubscriptionStatus;
import com.skillforge.payment.entity.UserSubscriptionEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserSubscriptionRepository extends JpaRepository<UserSubscriptionEntity, UUID> {
    Optional<UserSubscriptionEntity> findFirstByUserEmailAndStatusOrderByEndDateDesc(String userEmail, SubscriptionStatus status);
    List<UserSubscriptionEntity> findByUserEmail(String userEmail);
}
