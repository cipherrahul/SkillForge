package com.skillforge.payment.dto;

import java.time.Instant;
import java.util.UUID;

public record InvoiceResponse(
        UUID id,
        UUID orderId,
        String invoiceNumber,
        String billingName,
        String billingAddress,
        String pdfUrl,
        Instant issuedAt
) {
}
