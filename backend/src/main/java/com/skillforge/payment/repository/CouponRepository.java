package com.skillforge.payment.repository;

import com.skillforge.payment.entity.CouponEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface CouponRepository extends JpaRepository<CouponEntity, UUID> {
    Optional<CouponEntity> findByCodeIgnoreCaseAndActiveTrue(String code);
}
