package com.skillforge.payment.service;

import com.skillforge.auth.entity.UserEntity;
import com.skillforge.auth.repository.UserRepository;
import com.skillforge.common.exception.BadRequestException;
import com.skillforge.common.exception.ResourceNotFoundException;
import com.skillforge.course.entity.CourseEntity;
import com.skillforge.course.repository.CourseRepository;
import com.skillforge.enrollment.service.EnrollmentService;
import com.skillforge.payment.dto.*;
import com.skillforge.payment.entity.*;
import com.skillforge.payment.repository.*;
import com.skillforge.storage.service.StorageService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class PaymentService {
    private final OrderRepository orderRepository;
    private final RefundRepository refundRepository;
    private final SubscriptionPlanRepository subscriptionPlanRepository;
    private final UserSubscriptionRepository userSubscriptionRepository;
    private final CouponRepository couponRepository;
    private final InvoiceRepository invoiceRepository;
    private final InstructorRevenueRepository instructorRevenueRepository;
    private final CourseRepository courseRepository;
    private final UserRepository userRepository;
    private final EnrollmentService enrollmentService;
    private final StorageService storageService;

    public PaymentService(OrderRepository orderRepository,
                          RefundRepository refundRepository,
                          SubscriptionPlanRepository subscriptionPlanRepository,
                          UserSubscriptionRepository userSubscriptionRepository,
                          CouponRepository couponRepository,
                          InvoiceRepository invoiceRepository,
                          InstructorRevenueRepository instructorRevenueRepository,
                          CourseRepository courseRepository,
                          UserRepository userRepository,
                          EnrollmentService enrollmentService,
                          StorageService storageService) {
        this.orderRepository = orderRepository;
        this.refundRepository = refundRepository;
        this.subscriptionPlanRepository = subscriptionPlanRepository;
        this.userSubscriptionRepository = userSubscriptionRepository;
        this.couponRepository = couponRepository;
        this.invoiceRepository = invoiceRepository;
        this.instructorRevenueRepository = instructorRevenueRepository;
        this.courseRepository = courseRepository;
        this.userRepository = userRepository;
        this.enrollmentService = enrollmentService;
        this.storageService = storageService;
    }

    @Transactional
    public OrderResponse checkout(CheckoutRequest request, UserEntity currentUser) {
        return checkoutWithIdempotency(request, currentUser, null);
    }

    @Transactional
    public OrderResponse checkoutWithIdempotency(CheckoutRequest request, UserEntity currentUser, String idempotencyKey) {
        if (idempotencyKey != null && !idempotencyKey.isBlank()) {
            Optional<OrderEntity> existingOrder = orderRepository.findByIdempotencyKey(idempotencyKey.trim());
            if (existingOrder.isPresent()) {
                return mapOrder(existingOrder.get());
            }
        }

        if ((request.courseId() != null && request.subscriptionPlanId() != null) ||
                (request.courseId() == null && request.subscriptionPlanId() == null)) {
            throw new BadRequestException("Provide either courseId or subscriptionPlanId");
        }

        double price = 0.0;
        if (request.courseId() != null) {
            CourseEntity course = courseRepository.findById(request.courseId())
                    .orElseThrow(() -> new ResourceNotFoundException("Course not found"));
            price = course.getPrice();
        } else {
            SubscriptionPlanEntity plan = subscriptionPlanRepository.findById(request.subscriptionPlanId())
                    .orElseThrow(() -> new ResourceNotFoundException("Subscription plan not found"));
            price = plan.getPrice();
        }

        double discountAmount = 0.0;
        String appliedCoupon = null;

        if (request.couponCode() != null && !request.couponCode().isBlank()) {
            CouponEntity coupon = couponRepository.findByCodeIgnoreCaseAndActiveTrue(request.couponCode())
                    .orElseThrow(() -> new BadRequestException("Invalid or inactive coupon code"));

            if (coupon.getExpiryDate().isBefore(Instant.now())) {
                throw new BadRequestException("Coupon code has expired");
            }
            if (coupon.getUsedCount() >= coupon.getMaxUses()) {
                throw new BadRequestException("Coupon code usage limit reached");
            }

            discountAmount = price * (coupon.getDiscountPercent() / 100.0);
            price = Math.max(0, price - discountAmount);
            appliedCoupon = coupon.getCode().toUpperCase();

            // Track coupon use
            coupon.setUsedCount(coupon.getUsedCount() + 1);
            coupon.setUpdatedAt(Instant.now());
            couponRepository.save(coupon);
        }

        OrderEntity order = new OrderEntity();
        order.setIdempotencyKey(idempotencyKey != null && !idempotencyKey.isBlank() ? idempotencyKey.trim() : null);
        order.setUserEmail(currentUser.getEmail());
        order.setCourseId(request.courseId());
        order.setSubscriptionPlanId(request.subscriptionPlanId());
        order.setAmount(price);
        order.setStatus(OrderStatus.PENDING);
        order.setCouponCode(appliedCoupon);
        order.setDiscountAmount(discountAmount);
        order.setCreatedBy(currentUser.getEmail());
        order.setUpdatedBy(currentUser.getEmail());

        OrderEntity saved = orderRepository.save(order);
        return mapOrder(saved);
    }

    @Transactional
    public OrderResponse completeOrder(UUID orderId, UserEntity currentUser) {
        OrderEntity order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Order not found"));

        if (order.getStatus() != OrderStatus.PENDING) {
            throw new BadRequestException("Order is already processed");
        }

        order.setStatus(OrderStatus.COMPLETED);
        order.setTransactionId("TXN_" + UUID.randomUUID().toString().replace("-", "").substring(0, 12).toUpperCase());
        order.setUpdatedAt(Instant.now());
        order.setUpdatedBy(currentUser.getEmail());
        orderRepository.save(order);

        String itemName = "Subscription Service";

        // Enroll Student
        if (order.getCourseId() != null) {
            CourseEntity course = courseRepository.findById(order.getCourseId())
                    .orElseThrow(() -> new ResourceNotFoundException("Course not found"));
            itemName = course.getTitle();

            enrollmentService.enroll(order.getCourseId(), currentUser);

            // Instructor revenue share split (70%)
            InstructorRevenueEntity rev = new InstructorRevenueEntity();
            rev.setInstructorEmail(course.getInstructorEmail());
            rev.setCourseId(course.getId());
            rev.setOrderId(order.getId());
            rev.setTotalAmount(order.getAmount());
            rev.setInstructorShare(order.getAmount() * 0.70);
            rev.setPayoutStatus("PENDING");
            rev.setCreatedBy(currentUser.getEmail());
            rev.setUpdatedBy(currentUser.getEmail());
            instructorRevenueRepository.save(rev);
        } else {
            SubscriptionPlanEntity plan = subscriptionPlanRepository.findById(order.getSubscriptionPlanId())
                    .orElseThrow(() -> new ResourceNotFoundException("Subscription plan not found"));
            itemName = plan.getName();

            // Setup subscription
            UserSubscriptionEntity sub = new UserSubscriptionEntity();
            sub.setUserEmail(currentUser.getEmail());
            sub.setSubscriptionPlanId(plan.getId());
            sub.setStartDate(Instant.now());
            sub.setEndDate(Instant.now().plus(plan.getIntervalMonths() * 30L, ChronoUnit.DAYS));
            sub.setStatus(SubscriptionStatus.ACTIVE);
            sub.setCreatedBy(currentUser.getEmail());
            sub.setUpdatedBy(currentUser.getEmail());
            userSubscriptionRepository.save(sub);
        }

        // Issue Invoice file
        String invoiceNum = "INV-" + UUID.randomUUID().toString().replace("-", "").substring(0, 10).toUpperCase();
        String invoiceText = """
                ==================================================
                              SKILLFORGE PLATFORM
                               OFFICIAL INVOICE
                ==================================================
                Invoice Number: %s
                Date Issued:    %s
                Customer Name:  %s
                Customer Email: %s
                
                Product/Plan:   %s
                Paid Amount:    %s %.2f
                Discount:       %.2f (Promo: %s)
                Transaction ID: %s
                
                Thank you for learning with SkillForge!
                ==================================================
                """.formatted(invoiceNum, Instant.now().toString(), currentUser.getFullName(), currentUser.getEmail(),
                itemName, order.getCurrency(), order.getAmount(), order.getDiscountAmount(),
                order.getCouponCode() != null ? order.getCouponCode() : "NONE", order.getTransactionId());

        String filename = "invoice_" + order.getId() + ".txt";
        String pdfUrl = storageService.storeBytes(invoiceText.getBytes(), filename);

        InvoiceEntity invoice = new InvoiceEntity();
        invoice.setOrderId(order.getId());
        invoice.setInvoiceNumber(invoiceNum);
        invoice.setBillingName(currentUser.getFullName());
        invoice.setPdfUrl(pdfUrl);
        invoice.setCreatedBy(currentUser.getEmail());
        invoice.setUpdatedBy(currentUser.getEmail());
        invoiceRepository.save(invoice);

        return mapOrder(order);
    }

    @Transactional
    public OrderResponse refundOrder(UUID orderId, UserEntity currentUser) {
        OrderEntity order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Order not found"));

        if (order.getStatus() != OrderStatus.COMPLETED) {
            throw new BadRequestException("Only completed orders can be refunded");
        }

        order.setStatus(OrderStatus.REFUNDED);
        order.setUpdatedAt(Instant.now());
        order.setUpdatedBy(currentUser.getEmail());
        orderRepository.save(order);

        RefundEntity refund = new RefundEntity();
        refund.setOrderId(orderId);
        refund.setAmount(order.getAmount());
        refund.setReason("Customer request");
        refund.setStatus(RefundStatus.COMPLETED);
        refund.setCreatedBy(currentUser.getEmail());
        refund.setUpdatedBy(currentUser.getEmail());
        refundRepository.save(refund);

        return mapOrder(order);
    }

    public boolean hasActiveSubscription(String email) {
        Optional<UserSubscriptionEntity> activeSub = userSubscriptionRepository
                .findFirstByUserEmailAndStatusOrderByEndDateDesc(email, SubscriptionStatus.ACTIVE);

        if (activeSub.isPresent()) {
            UserSubscriptionEntity sub = activeSub.get();
            if (sub.getEndDate().isAfter(Instant.now())) {
                return true;
            } else {
                // Auto expire
                sub.setStatus(SubscriptionStatus.EXPIRED);
                sub.setUpdatedAt(Instant.now());
                userSubscriptionRepository.save(sub);
            }
        }
        return false;
    }

    public List<OrderResponse> getOrderHistory(String email) {
        return orderRepository.findByUserEmail(email).stream()
                .filter(o -> !o.isDeleted())
                .map(this::mapOrder)
                .toList();
    }

    @org.springframework.cache.annotation.Cacheable(value = "subscriptionPlans")
    public List<SubscriptionPlanEntity> getPlans() {
        return subscriptionPlanRepository.findAll();
    }

    public UserSubscriptionEntity getActiveSubscription(String email) {
        return userSubscriptionRepository.findFirstByUserEmailAndStatusOrderByEndDateDesc(email, SubscriptionStatus.ACTIVE)
                .filter(s -> s.getEndDate().isAfter(Instant.now()))
                .orElse(null);
    }

    @Transactional
    public CouponResponse createCoupon(CreateCouponRequest request, UserEntity currentUser) {
        CouponEntity coupon = new CouponEntity();
        coupon.setCode(request.code().toUpperCase().trim());
        coupon.setDiscountPercent(request.discountPercent());
        coupon.setExpiryDate(request.expiryDate());
        coupon.setMaxUses(request.maxUses());
        coupon.setCreatedBy(currentUser.getEmail());
        coupon.setUpdatedBy(currentUser.getEmail());

        CouponEntity saved = couponRepository.save(coupon);
        return mapCoupon(saved);
    }

    public CouponResponse validateCoupon(String code) {
        CouponEntity coupon = couponRepository.findByCodeIgnoreCaseAndActiveTrue(code)
                .orElseThrow(() -> new BadRequestException("Coupon not found or inactive"));

        if (coupon.getExpiryDate().isBefore(Instant.now())) {
            throw new BadRequestException("Coupon has expired");
        }
        if (coupon.getUsedCount() >= coupon.getMaxUses()) {
            throw new BadRequestException("Coupon limit reached");
        }

        return mapCoupon(coupon);
    }

    private final java.util.List<PayoutResponse> payoutLogs = new java.util.concurrent.CopyOnWriteArrayList<>();

    public PayoutResponse requestPayout(PayoutRequest request, UserEntity currentUser) {
        PayoutResponse payout = new PayoutResponse(
                UUID.randomUUID(),
                currentUser.getEmail(),
                request.amount(),
                "PROCESSING",
                request.payoutMethod(),
                Instant.now()
        );
        payoutLogs.add(0, payout);
        return payout;
    }

    public List<PayoutResponse> getPayoutHistory(String email) {
        return payoutLogs.stream()
                .filter(p -> p.instructorEmail().equalsIgnoreCase(email))
                .toList();
    }

    public RevenueReportResponse getInstructorRevenue(String email) {
        List<InstructorRevenueEntity> revs = instructorRevenueRepository.findByInstructorEmail(email);
        double total = revs.stream().mapToDouble(InstructorRevenueEntity::getTotalAmount).sum();
        double share = revs.stream().mapToDouble(InstructorRevenueEntity::getInstructorShare).sum();
        return new RevenueReportResponse(total, share, total - share);
    }

    private OrderResponse mapOrder(OrderEntity o) {
        return new OrderResponse(
                o.getId(),
                o.getUserEmail(),
                o.getCourseId(),
                o.getSubscriptionPlanId(),
                o.getAmount(),
                o.getCurrency(),
                o.getStatus(),
                o.getTransactionId(),
                o.getCouponCode(),
                o.getDiscountAmount(),
                o.getCreatedAt()
        );
    }

    private CouponResponse mapCoupon(CouponEntity c) {
        return new CouponResponse(
                c.getId(),
                c.getCode(),
                c.getDiscountPercent(),
                c.getExpiryDate(),
                c.getMaxUses(),
                c.getUsedCount(),
                c.isActive()
        );
    }
}

