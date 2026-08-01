package com.skillforge.payment.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "idempotency_keys", indexes = {
    @Index(name = "idx_idempotency_key", columnList = "key_value", unique = true)
})
public class IdempotencyKeyEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "key_value", nullable = false, unique = true)
    private String keyValue;

    @Column(nullable = false)
    private String userEmail;

    private String requestEndpoint;

    @Column(length = 4000)
    private String responseBody;

    private int responseStatusCode = 200;

    @Column(nullable = false)
    private Instant createdAt = Instant.now();

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public String getKeyValue() { return keyValue; }
    public void setKeyValue(String keyValue) { this.keyValue = keyValue; }
    public String getUserEmail() { return userEmail; }
    public void setUserEmail(String userEmail) { this.userEmail = userEmail; }
    public String getRequestEndpoint() { return requestEndpoint; }
    public void setRequestEndpoint(String requestEndpoint) { this.requestEndpoint = requestEndpoint; }
    public String getResponseBody() { return responseBody; }
    public void setResponseBody(String responseBody) { this.responseBody = responseBody; }
    public int getResponseStatusCode() { return responseStatusCode; }
    public void setResponseStatusCode(int responseStatusCode) { this.responseStatusCode = responseStatusCode; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
