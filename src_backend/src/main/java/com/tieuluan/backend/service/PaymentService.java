package com.tieuluan.backend.service;

import com.tieuluan.backend.config.VNPayConfig;
import com.tieuluan.backend.dto.OrderDTO;
import com.tieuluan.backend.model.Order;
import com.tieuluan.backend.model.StudyPack;
import com.tieuluan.backend.model.Transaction;
import com.tieuluan.backend.model.User;
import com.tieuluan.backend.repository.OrderRepository;
import com.tieuluan.backend.repository.StudyPackRepository;
import com.tieuluan.backend.repository.TransactionRepository;
import com.tieuluan.backend.repository.UserRepository;
import com.tieuluan.backend.util.VNPayUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.text.SimpleDateFormat;
import java.time.ZonedDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class PaymentService {

    private final OrderRepository orderRepository;
    private final TransactionRepository transactionRepository;
    private final StudyPackRepository studyPackRepository;
    private final UserRepository userRepository;
    private final VNPayConfig vnPayConfig;

    /**
     * Tạo order mới cho user
     */
    @Transactional
    public OrderDTO createOrder(Long packId) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String email = auth.getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        StudyPack pack = studyPackRepository.findById(packId)
                .filter(p -> p.getDeletedAt() == null)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy gói học tập"));

        Order order = new Order();
        order.setUserId(user.getId());
        order.setPackId(pack.getId());
        order.setPriceAtPurchase(pack.getPrice());
        order.setStatus(Order.OrderStatus.PENDING);
        order.setStartedAt(ZonedDateTime.now());
        Order saved = orderRepository.save(order);

        OrderDTO dto = OrderDTO.fromEntity(saved);
        dto.setPackName(pack.getName());
        return dto;
    }

    /**
     * Tạo URL thanh toán VNPay - THEO ĐẶT TRANG TÀI LIỆU OFFICIAL VNPay
     */
    @Transactional
    public OrderDTO.VNPayPaymentResponse createVNPayPayment(Long orderId, String ipAddress) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy đơn hàng"));

        if (order.getStatus() != Order.OrderStatus.PENDING) {
            throw new RuntimeException("Đơn hàng không ở trạng thái chờ thanh toán");
        }

        StudyPack pack = studyPackRepository.findById(order.getPackId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy gói học tập"));

        try {
            // 1. Tạo/Update Transaction
            List<Transaction> existed = transactionRepository.findByOrderId(orderId);
            Transaction txn = existed.isEmpty() ? new Transaction() : existed.get(0);
            txn.setOrderId(order.getId());
            txn.setAmount(order.getPriceAtPurchase());
            txn.setProvider("VNPay");
            txn.setStatus(Transaction.TransactionStatus.INIT);
            txn.setMessage("Đang chờ thanh toán");
            transactionRepository.save(txn);

            // 2. Tạo thông tin thanh toán THEO CODE MẪU VNPay
            String vnp_TxnRef = String.valueOf(orderId);
            int vnp_Amount = order.getPriceAtPurchase()
                    .multiply(new java.math.BigDecimal("100"))
                    .intValue();

            // 3. Tạo params map THEO THỨ TỰ CODE MẪU VNPay
            Map<String, String> vnp_Params = new HashMap<>();
            vnp_Params.put("vnp_Version", "2.1.0");
            vnp_Params.put("vnp_Command", "pay");
            vnp_Params.put("vnp_TmnCode", vnPayConfig.getTmnCode());
            vnp_Params.put("vnp_Amount", String.valueOf(vnp_Amount));
            vnp_Params.put("vnp_CurrCode", "VND");

            if (vnPayConfig.getBankCode() != null && !vnPayConfig.getBankCode().isEmpty()) {
                vnp_Params.put("vnp_BankCode", vnPayConfig.getBankCode());
            }

            vnp_Params.put("vnp_TxnRef", vnp_TxnRef);

            String orderInfo = removeVietnameseDiacritics("Thanh toan don hang " + vnp_TxnRef);
            vnp_Params.put("vnp_OrderInfo", orderInfo);
            vnp_Params.put("vnp_OrderType", vnPayConfig.getOrderType());
            vnp_Params.put("vnp_Locale", "vn");
            vnp_Params.put("vnp_ReturnUrl", vnPayConfig.getReturnUrl());
            vnp_Params.put("vnp_IpAddr", ipAddress);

            // 4. Tạo timestamp
            Calendar cld = Calendar.getInstance(TimeZone.getTimeZone("Etc/GMT+7"));
            SimpleDateFormat formatter = new SimpleDateFormat("yyyyMMddHHmmss");
            String vnp_CreateDate = formatter.format(cld.getTime());
            vnp_Params.put("vnp_CreateDate", vnp_CreateDate);

            cld.add(Calendar.MINUTE, 15);
            String vnp_ExpireDate = formatter.format(cld.getTime());
            vnp_Params.put("vnp_ExpireDate", vnp_ExpireDate);

            // 5. Build hash data và query
            Map<String, String> result = VNPayUtil.buildHashDataAndQuery(vnp_Params);
            String hashData = result.get("hashData");
            String queryUrl = result.get("queryUrl");

            // 6. Tính chữ ký
            String vnp_SecureHash = VNPayUtil.hmacSHA512(vnPayConfig.getHashSecret(), hashData);

            // 7. Build payment URL
            String paymentUrl = vnPayConfig.getUrl() + "?" + queryUrl + "&vnp_SecureHash=" + vnp_SecureHash;

            log.info("=== VNPAY PAYMENT URL ===");
            log.info("Order ID: {}, Amount: {}", orderId, vnp_Amount);

            return new OrderDTO.VNPayPaymentResponse(paymentUrl, order.getId(), "OK");

        } catch (Exception e) {
            log.error("Lỗi khi tạo URL thanh toán", e);
            throw new RuntimeException("Lỗi khi tạo URL thanh toán: " + e.getMessage());
        }
    }

    /**
     * ✅ IPN Callback - FIXED: Upgrade role sau thanh toán
     */
    @Transactional
    public Map<String, String> handleVNPayCallback(Map<String, String> params) {
        Map<String, String> response = new HashMap<>();

        try {
            log.info("=== VNPAY IPN CALLBACK ===");
            log.info("Received params: {}", params);

            // 1. Lấy hash từ VNPay
            String receivedHash = params.get("vnp_SecureHash");
            if (receivedHash == null) {
                log.error("Missing vnp_SecureHash");
                response.put("RspCode", "97");
                response.put("Message", "Invalid signature");
                return response;
            }

            // 2. Tạo params để verify
            Map<String, String> signParams = new HashMap<>();
            for (Map.Entry<String, String> entry : params.entrySet()) {
                String key = entry.getKey();
                if (key.startsWith("vnp_")
                        && !key.equals("vnp_SecureHash")
                        && !key.equals("vnp_SecureHashType")) {
                    signParams.put(key, entry.getValue());
                }
            }

            // 3. Verify signature
            Map<String, String> hashResult = VNPayUtil.buildHashDataAndQuery(signParams);
            String hashData = hashResult.get("hashData");
            String calculatedHash = VNPayUtil.hmacSHA512(vnPayConfig.getHashSecret(), hashData);

            if (!receivedHash.equalsIgnoreCase(calculatedHash)) {
                log.error("Invalid signature");
                response.put("RspCode", "97");
                response.put("Message", "Invalid signature");
                return response;
            }

            // 4. Lấy thông tin giao dịch
            String txnRef = params.get("vnp_TxnRef");
            String responseCode = params.get("vnp_ResponseCode");
            String transactionStatus = params.get("vnp_TransactionStatus");
            String transactionNo = params.get("vnp_TransactionNo");
            String bankCode = params.get("vnp_BankCode");
            String amountStr = params.get("vnp_Amount");

            log.info("TxnRef: {}, ResponseCode: {}", txnRef, responseCode);

            // 5. Tìm order
            Long orderId;
            try {
                orderId = Long.parseLong(txnRef);
            } catch (NumberFormatException e) {
                log.error("Invalid txnRef: {}", txnRef);
                response.put("RspCode", "01");
                response.put("Message", "Order not found");
                return response;
            }

            Order order = orderRepository.findById(orderId)
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy đơn hàng"));

            // 6. Verify amount
            long vnpAmount = Long.parseLong(amountStr);
            long orderAmount = order.getPriceAtPurchase()
                    .multiply(new java.math.BigDecimal("100"))
                    .longValue();

            if (vnpAmount != orderAmount) {
                log.error("Invalid amount");
                response.put("RspCode", "04");
                response.put("Message", "Invalid amount");
                return response;
            }

            // 7. Kiểm tra đã xử lý chưa
            List<Transaction> list = transactionRepository.findByOrderId(order.getId());
            Transaction txn = list.isEmpty() ? new Transaction() : list.get(0);

            if (!list.isEmpty() && txn.getStatus() == Transaction.TransactionStatus.SUCCEEDED) {
                log.info("Order already confirmed: {}", order.getId());
                response.put("RspCode", "02");
                response.put("Message", "Order already confirmed");
                return response;
            }

            // 8. Cập nhật transaction
            txn.setOrderId(order.getId());
            txn.setProvider("VNPay");
            txn.setProviderTxnId(transactionNo);
            txn.setMethod(bankCode);
            txn.setAmount(order.getPriceAtPurchase());

            Map<String, Object> rawPayload = new HashMap<>();
            params.forEach((k, v) -> rawPayload.put(k, v));
            txn.setRawPayload(rawPayload);

            // 9. ✅ FIXED: Xử lý kết quả với upgrade role
            String finalCode = responseCode != null ? responseCode : transactionStatus;
            if ("00".equals(finalCode)) {
                order.setStatus(Order.OrderStatus.PAID);
                txn.setStatus(Transaction.TransactionStatus.SUCCEEDED);
                txn.setMessage("Thanh toán thành công");

                StudyPack pack = studyPackRepository.findById(order.getPackId()).orElse(null);
                if (pack != null) {
                    ZonedDateTime expiresAt = order.getStartedAt().plusDays(pack.getDurationDays());
                    order.setExpiresAt(expiresAt);

                    // ✅ LOGIC MỚI: Tự động upgrade role
                    User user = userRepository.findById(order.getUserId())
                            .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

                    if (pack.getTargetRole() == StudyPack.TargetRole.TEACHER) {
                        user.setRole(User.UserRole.TEACHER);
                        log.info("✅ Upgraded user {} to TEACHER", user.getEmail());
                    } else {
                        if (user.getRole() == User.UserRole.NORMAL_USER) {
                            user.setRole(User.UserRole.PREMIUM_USER);
                            log.info("✅ Upgraded user {} to PREMIUM_USER", user.getEmail());
                        }
                    }

                    userRepository.save(user);
                }

                log.info("✅ Payment SUCCESS for order {}", order.getId());
            } else {
                order.setStatus(Order.OrderStatus.FAILED);
                txn.setStatus(Transaction.TransactionStatus.FAILED);
                txn.setMessage("Thanh toán thất bại: " + getErrorMessage(responseCode));
                log.info("❌ Payment FAILED for order {}", order.getId());
            }

            // 10. Lưu DB
            orderRepository.save(order);
            transactionRepository.save(txn);

            // 11. Trả về success
            response.put("RspCode", "00");
            response.put("Message", "Confirm Success");

            log.info("✅ IPN processed successfully");
            return response;

        } catch (Exception e) {
            log.error("❌ Error processing IPN", e);
            response.put("RspCode", "99");
            response.put("Message", "Unknown error: " + e.getMessage());
            return response;
        }
    }

    /**
     * ✅ Return URL - FIXED: Upgrade role nếu IPN chưa gọi
     */
    @Transactional
    public Map<String, Object> handleVNPayReturn(Map<String, String> params) {
        Map<String, Object> response = new LinkedHashMap<>();

        try {
            log.info("=== VNPAY RETURN URL ===");
            log.info("Received params: {}", params);

            // 1. Verify signature
            String receivedHash = params.get("vnp_SecureHash");
            if (receivedHash == null) {
                response.put("success", false);
                response.put("message", "Thiếu chữ ký bảo mật");
                response.put("code", "NO_SIGNATURE");
                return response;
            }

            Map<String, String> signParams = new HashMap<>();
            for (Map.Entry<String, String> entry : params.entrySet()) {
                String key = entry.getKey();
                if (key.startsWith("vnp_")
                        && !key.equals("vnp_SecureHash")
                        && !key.equals("vnp_SecureHashType")) {
                    signParams.put(key, entry.getValue());
                }
            }

            Map<String, String> hashResult = VNPayUtil.buildHashDataAndQuery(signParams);
            String hashData = hashResult.get("hashData");
            String calculatedHash = VNPayUtil.hmacSHA512(vnPayConfig.getHashSecret(), hashData);

            if (!receivedHash.equalsIgnoreCase(calculatedHash)) {
                log.error("❌ Invalid signature");
                response.put("success", false);
                response.put("message", "Chữ ký không hợp lệ");
                response.put("code", "INVALID_SIGNATURE");
                return response;
            }

            log.info("✅ Signature verified");

            // 2. Lấy thông tin
            String txnRef = params.get("vnp_TxnRef");
            String responseCode = params.get("vnp_ResponseCode");
            String transactionNo = params.get("vnp_TransactionNo");
            String bankCode = params.get("vnp_BankCode");
            String amountStr = params.get("vnp_Amount");
            String payDate = params.get("vnp_PayDate");
            String cardType = params.get("vnp_CardType");

            // 3. Parse orderId
            Long orderId;
            try {
                orderId = Long.parseLong(txnRef);
            } catch (NumberFormatException e) {
                response.put("success", false);
                response.put("message", "Mã đơn hàng không hợp lệ");
                return response;
            }

            // 4. Lấy thông tin từ DB
            Order order = orderRepository.findById(orderId).orElse(null);
            if (order == null) {
                response.put("success", false);
                response.put("message", "Không tìm thấy đơn hàng");
                return response;
            }

            List<Transaction> transactions = transactionRepository.findByOrderId(orderId);
            Transaction transaction = transactions.isEmpty() ? new Transaction() : transactions.get(0);

            StudyPack pack = studyPackRepository.findById(order.getPackId()).orElse(null);
            if (pack == null) {
                response.put("success", false);
                response.put("message", "Không tìm thấy gói học tập");
                return response;
            }

            // 5. Verify amount
            long vnpAmount = Long.parseLong(amountStr);
            long orderAmount = order.getPriceAtPurchase()
                    .multiply(new java.math.BigDecimal("100"))
                    .longValue();

            if (vnpAmount != orderAmount) {
                log.warn("⚠️ Amount mismatch");
            }

            // 6. Kiểm tra kết quả
            boolean isSuccess = "00".equals(responseCode);
            log.info("Payment result: {}", isSuccess ? "SUCCESS" : "FAILED");

            // 7. ✅ FIXED: Cập nhật order nếu vẫn PENDING
            if (order.getStatus() == Order.OrderStatus.PENDING) {
                log.info("⚠️ Order still PENDING, updating from Return URL...");

                transaction.setOrderId(order.getId());
                transaction.setProvider("VNPay");
                transaction.setProviderTxnId(transactionNo);
                transaction.setMethod(bankCode);
                transaction.setAmount(order.getPriceAtPurchase());

                Map<String, Object> rawPayload = new HashMap<>();
                params.forEach((k, v) -> rawPayload.put(k, v));
                transaction.setRawPayload(rawPayload);

                if (isSuccess) {
                    order.setStatus(Order.OrderStatus.PAID);
                    transaction.setStatus(Transaction.TransactionStatus.SUCCEEDED);
                    transaction.setMessage("Thanh toán thành công");

                    ZonedDateTime expiresAt = order.getStartedAt().plusDays(pack.getDurationDays());
                    order.setExpiresAt(expiresAt);

                    // ✅ LOGIC MỚI: Upgrade role (giống callback)
                    User user = userRepository.findById(order.getUserId())
                            .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

                    if (pack.getTargetRole() == StudyPack.TargetRole.TEACHER) {
                        user.setRole(User.UserRole.TEACHER);
                        log.info("✅ Upgraded user {} to TEACHER (from Return URL)", user.getEmail());
                    } else {
                        if (user.getRole() == User.UserRole.NORMAL_USER) {
                            user.setRole(User.UserRole.PREMIUM_USER);
                            log.info("✅ Upgraded user {} to PREMIUM_USER (from Return URL)", user.getEmail());
                        }
                    }

                    userRepository.save(user);
                    log.info("✅ Payment SUCCESS - Updated from Return URL");
                } else {
                    order.setStatus(Order.OrderStatus.FAILED);
                    transaction.setStatus(Transaction.TransactionStatus.FAILED);
                    transaction.setMessage("Thanh toán thất bại");
                    log.info("❌ Payment FAILED - Updated from Return URL");
                }

                orderRepository.save(order);
                transactionRepository.save(transaction);
            } else {
                log.info("ℹ️ Order already processed: {}", order.getStatus());
            }

            // 8. Build response
            response.put("success", isSuccess);
            response.put("responseCode", responseCode);
            response.put("message", isSuccess ? "Thanh toán thành công" : getErrorMessage(responseCode));
            response.put("code", isSuccess ? "SUCCESS" : "PAYMENT_FAILED");

            // Order info
            Map<String, Object> orderInfo = new LinkedHashMap<>();
            orderInfo.put("orderId", order.getId());
            orderInfo.put("orderStatus", order.getStatus().name());
            orderInfo.put("packName", pack.getName());
            orderInfo.put("packDescription", pack.getDescription());
            orderInfo.put("amount", order.getPriceAtPurchase());
            orderInfo.put("durationDays", pack.getDurationDays());
            orderInfo.put("createdAt", order.getCreatedAt().toString());

            if (order.getStartedAt() != null) {
                orderInfo.put("startedAt", order.getStartedAt().toString());
            }
            if (order.getExpiresAt() != null) {
                orderInfo.put("expiresAt", order.getExpiresAt().toString());
            }

            response.put("order", orderInfo);

            // Transaction info
            Map<String, Object> txnInfo = new LinkedHashMap<>();
            txnInfo.put("txnRef", txnRef);
            txnInfo.put("transactionNo", transactionNo);
            txnInfo.put("bankCode", bankCode);
            txnInfo.put("cardType", cardType);
            txnInfo.put("payDate", payDate);
            txnInfo.put("payDateFormatted", formatPayDate(payDate));
            txnInfo.put("amount", vnpAmount / 100);

            if (transaction.getId() != null) {
                txnInfo.put("transactionId", transaction.getId());
                txnInfo.put("transactionStatus", transaction.getStatus().name());
                txnInfo.put("provider", transaction.getProvider());
            }

            response.put("transaction", txnInfo);

            // User info
            User user = userRepository.findById(order.getUserId()).orElse(null);
            if (user != null) {
                Map<String, Object> userInfo = new LinkedHashMap<>();
                userInfo.put("userId", user.getId());
                userInfo.put("email", user.getEmail());
                userInfo.put("fullName", user.getFullName());
                userInfo.put("role", user.getRole().name());
                userInfo.put("isBlocked", user.getIsBlocked());
                response.put("user", userInfo);
            }

            log.info("✅ Return URL processed successfully");
            return response;

        } catch (Exception e) {
            log.error("❌ Error processing return URL", e);
            response.put("success", false);
            response.put("message", "Lỗi xử lý kết quả thanh toán: " + e.getMessage());
            response.put("code", "INTERNAL_ERROR");
            return response;
        }
    }

    /**
     * Format pay date
     */
    private String formatPayDate(String payDate) {
        if (payDate == null || payDate.length() != 14) {
            return payDate;
        }

        try {
            String year = payDate.substring(0, 4);
            String month = payDate.substring(4, 6);
            String day = payDate.substring(6, 8);
            String hour = payDate.substring(8, 10);
            String minute = payDate.substring(10, 12);
            String second = payDate.substring(12, 14);

            return String.format("%s/%s/%s %s:%s:%s", day, month, year, hour, minute, second);
        } catch (Exception e) {
            return payDate;
        }
    }

    /**
     * Map error messages
     */
    private String getErrorMessage(String responseCode) {
        Map<String, String> errorMessages = new HashMap<>();
        errorMessages.put("00", "Giao dịch thành công");
        errorMessages.put("07", "Trừ tiền thành công. Giao dịch bị nghi ngờ");
        errorMessages.put("09", "Thẻ/Tài khoản chưa đăng ký InternetBanking");
        errorMessages.put("10", "Xác thực thông tin không đúng quá 3 lần");
        errorMessages.put("11", "Đã hết hạn chờ thanh toán");
        errorMessages.put("12", "Thẻ/Tài khoản bị khóa");
        errorMessages.put("13", "Nhập sai OTP");
        errorMessages.put("24", "Khách hàng hủy giao dịch");
        errorMessages.put("51", "Tài khoản không đủ số dư");
        errorMessages.put("65", "Tài khoản vượt quá hạn mức giao dịch");
        errorMessages.put("75", "Ngân hàng thanh toán đang bảo trì");
        errorMessages.put("79", "Nhập sai mật khẩu quá số lần quy định");
        errorMessages.put("99", "Lỗi không xác định");

        return errorMessages.getOrDefault(responseCode, "Lỗi không xác định (Code: " + responseCode + ")");
    }

    /**
     * Lấy danh sách order của user
     */
    public List<OrderDTO> getMyOrders() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String email = auth.getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        List<Order> orders = orderRepository.findByUserIdOrderByCreatedAtDesc(user.getId());

        return orders.stream().map(order -> {
            OrderDTO dto = OrderDTO.fromEntity(order);
            studyPackRepository.findById(order.getPackId())
                    .ifPresent(pack -> dto.setPackName(pack.getName()));
            return dto;
        }).collect(Collectors.toList());
    }

    /**
     * Remove Vietnamese diacritics
     */
    private String removeVietnameseDiacritics(String text) {
        if (text == null) return "";
        String normalized = java.text.Normalizer.normalize(text, java.text.Normalizer.Form.NFD);
        return normalized.replaceAll("[\\p{InCombiningDiacriticalMarks}]", "")
                .replaceAll("[^a-zA-Z0-9\\s]", "")
                .trim();
    }
}