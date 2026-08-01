package com.skillforge.payment.service;

import com.skillforge.payment.entity.IdempotencyKeyEntity;
import com.skillforge.payment.repository.IdempotencyRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Optional;

@Service
public class IdempotencyService {

    private final IdempotencyRepository idempotencyRepository;

    public IdempotencyService(IdempotencyRepository idempotencyRepository) {
        this.idempotencyRepository = idempotencyRepository;
    }

    /**
     * Retrieve cached response if idempotency key exists
     */
    public Optional<IdempotencyKeyEntity> getExistingRecord(String key) {
        if (key == null || key.isBlank()) return Optional.empty();
        return idempotencyRepository.findByKeyValue(key.trim());
    }

    /**
     * Record completed response for an idempotency key
     */
    @Transactional
    public IdempotencyKeyEntity saveRecord(String key, String userEmail, String endpoint, String responseBody, int statusCode) {
        if (key == null || key.isBlank()) return null;
        
        Optional<IdempotencyKeyEntity> existing = idempotencyRepository.findByKeyValue(key.trim());
        IdempotencyKeyEntity entity = existing.orElseGet(IdempotencyKeyEntity::new);
        
        entity.setKeyValue(key.trim());
        entity.setUserEmail(userEmail != null ? userEmail : "SYSTEM");
        entity.setRequestEndpoint(endpoint);
        entity.setResponseBody(responseBody);
        entity.setResponseStatusCode(statusCode);
        entity.setCreatedAt(Instant.now());

        return idempotencyRepository.save(entity);
    }
}
