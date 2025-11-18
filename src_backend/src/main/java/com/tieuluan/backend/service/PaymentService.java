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
     * Tạo URL thanh toán VNPay - THEO ĐẤT TRANG TÀI LIỆU OFFICIAL VNPay
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
            String vnp_TxnRef = String.valueOf(orderId); // Dùng orderId làm TxnRef
            int vnp_Amount = order.getPriceAtPurchase()
                    .multiply(new java.math.BigDecimal("100"))
                    .intValue(); // Nhân 100 để bỏ phần thập phân

            // 3. Tạo params map THEO THỨ TỰ CODE MẪU VNPay
            Map<String, String> vnp_Params = new HashMap<>();
            vnp_Params.put("vnp_Version", "2.1.0");
            vnp_Params.put("vnp_Command", "pay");
            vnp_Params.put("vnp_TmnCode", vnPayConfig.getTmnCode());
            vnp_Params.put("vnp_Amount", String.valueOf(vnp_Amount));
            vnp_Params.put("vnp_CurrCode", "VND");

            // Chỉ thêm BankCode nếu có
            if (vnPayConfig.getBankCode() != null && !vnPayConfig.getBankCode().isEmpty()) {
                vnp_Params.put("vnp_BankCode", vnPayConfig.getBankCode());
            }

            vnp_Params.put("vnp_TxnRef", vnp_TxnRef);

            // OrderInfo - PHẢI loại bỏ dấu tiếng Việt theo quy định VNPay
            String orderInfo = removeVietnameseDiacritics("Thanh toan don hang " + vnp_TxnRef);
            vnp_Params.put("vnp_OrderInfo", orderInfo);
            vnp_Params.put("vnp_OrderType", vnPayConfig.getOrderType());

            // Locale và các tham số khác
            vnp_Params.put("vnp_Locale", "vn");
            vnp_Params.put("vnp_ReturnUrl", vnPayConfig.getReturnUrl());
            vnp_Params.put("vnp_IpAddr", ipAddress);

            // 4. Tạo timestamp THEO GMT+7 như code mẫu VNPay
            Calendar cld = Calendar.getInstance(TimeZone.getTimeZone("Etc/GMT+7"));
            SimpleDateFormat formatter = new SimpleDateFormat("yyyyMMddHHmmss");
            String vnp_CreateDate = formatter.format(cld.getTime());
            vnp_Params.put("vnp_CreateDate", vnp_CreateDate);

            // Expire date: 15 phút sau
            cld.add(Calendar.MINUTE, 15);
            String vnp_ExpireDate = formatter.format(cld.getTime());
            vnp_Params.put("vnp_ExpireDate", vnp_ExpireDate);

            // 5. Build hash data và query THEO CODE MẪU VNPay
            Map<String, String> result = VNPayUtil.buildHashDataAndQuery(vnp_Params);
            String hashData = result.get("hashData");
            String queryUrl = result.get("queryUrl");

            // 6. Tính chữ ký HMAC-SHA512
            String vnp_SecureHash = VNPayUtil.hmacSHA512(vnPayConfig.getHashSecret(), hashData);

            // 7. Build payment URL
            String paymentUrl = vnPayConfig.getUrl() + "?" + queryUrl + "&vnp_SecureHash=" + vnp_SecureHash;

            log.info("=== VNPAY PAYMENT URL (OFFICIAL SPEC) ===");
            log.info("Order ID  : {}", orderId);
            log.info("TxnRef    : {}", vnp_TxnRef);
            log.info("Amount    : {}", vnp_Amount);
            log.info("HashData  : {}", hashData);
            log.info("SecureHash: {}", vnp_SecureHash);
            log.info("URL       : {}", paymentUrl);

            return new OrderDTO.VNPayPaymentResponse(paymentUrl, order.getId(), "OK");

        } catch (Exception e) {
            log.error("Lỗi khi tạo URL thanh toán", e);
            throw new RuntimeException("Lỗi khi tạo URL thanh toán: " + e.getMessage());
        }
    }

    /**
     * IPN Callback - Xử lý thông báo từ VNPay THEO SPECIFICATION
     * ĐÂY LÀ METHOD QUAN TRỌNG NHẤT - Dùng để confirm thanh toán
     */
    @Transactional
    public Map<String, String> handleVNPayCallback(Map<String, String> params) {
        Map<String, String> response = new HashMap<>();

        try {
            log.info("=== VNPAY IPN CALLBACK (OFFICIAL SPEC) ===");
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

            // 3. Tính lại chữ ký
            Map<String, String> hashResult = VNPayUtil.buildHashDataAndQuery(signParams);
            String hashData = hashResult.get("hashData");
            String calculatedHash = VNPayUtil.hmacSHA512(vnPayConfig.getHashSecret(), hashData);

            log.info("HashData       : {}", hashData);
            log.info("Calculated hash: {}", calculatedHash);
            log.info("Received hash  : {}", receivedHash);

            // 4. Verify signature
            if (!receivedHash.equalsIgnoreCase(calculatedHash)) {
                log.error("Invalid signature");
                response.put("RspCode", "97");
                response.put("Message", "Invalid signature");
                return response;
            }

            // 5. Lấy thông tin giao dịch
            String txnRef = params.get("vnp_TxnRef");
            String responseCode = params.get("vnp_ResponseCode");
            String transactionStatus = params.get("vnp_TransactionStatus");
            String transactionNo = params.get("vnp_TransactionNo");
            String bankCode = params.get("vnp_BankCode");
            String amountStr = params.get("vnp_Amount");

            log.info("TxnRef: {}, ResponseCode: {}, TransactionStatus: {}, TransactionNo: {}",
                    txnRef, responseCode, transactionStatus, transactionNo);

            // 6. Tìm order
            Long orderId;
            try {
                orderId = Long.parseLong(txnRef);
            } catch (NumberFormatException e) {
                log.error("Invalid txnRef format: {}", txnRef);
                response.put("RspCode", "01");
                response.put("Message", "Order not found");
                return response;
            }

            Order order = orderRepository.findById(orderId)
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy đơn hàng với ID: " + orderId));

            // 7. Verify amount
            long vnpAmount = Long.parseLong(amountStr);
            long orderAmount = order.getPriceAtPurchase()
                    .multiply(new java.math.BigDecimal("100"))
                    .longValue();

            if (vnpAmount != orderAmount) {
                log.error("Invalid amount: expected {}, got {}", orderAmount, vnpAmount);
                response.put("RspCode", "04");
                response.put("Message", "Invalid amount");
                return response;
            }

            // 8. Kiểm tra đã xử lý chưa (idempotent)
            List<Transaction> list = transactionRepository.findByOrderId(order.getId());
            Transaction txn = list.isEmpty() ? new Transaction() : list.get(0);

            if (!list.isEmpty() && txn.getStatus() == Transaction.TransactionStatus.SUCCEEDED) {
                log.info("Order already confirmed: {}", order.getId());
                response.put("RspCode", "02");
                response.put("Message", "Order already confirmed");
                return response;
            }

            // 9. Cập nhật transaction
            txn.setOrderId(order.getId());
            txn.setProvider("VNPay");
            txn.setProviderTxnId(transactionNo);
            txn.setMethod(bankCode);
            txn.setAmount(order.getPriceAtPurchase());

            // Lưu raw payload
            Map<String, Object> rawPayload = new HashMap<>();
            params.forEach((k, v) -> rawPayload.put(k, v));
            txn.setRawPayload(rawPayload);

            // 10. Xử lý kết quả
            String finalCode = responseCode != null ? responseCode : transactionStatus;
            if ("00".equals(finalCode)) {
                // ✅ Thanh toán thành công
                order.setStatus(Order.OrderStatus.PAID);
                txn.setStatus(Transaction.TransactionStatus.SUCCEEDED);
                txn.setMessage("Thanh toán thành công");

                // Tính expiresAt dựa vào durationDays
                StudyPack pack = studyPackRepository.findById(order.getPackId()).orElse(null);
                if (pack != null) {
                    ZonedDateTime expiresAt = order.getStartedAt().plusDays(pack.getDurationDays());
                    order.setExpiresAt(expiresAt);
                }

                // Kích hoạt premium cho user
                User user = userRepository.findById(order.getUserId())
                        .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));
                user.setIsPremium(true);
                userRepository.save(user);

                log.info("✅ Payment SUCCESS for order {}", order.getId());
            } else {
                // ❌ Thanh toán thất bại
                order.setStatus(Order.OrderStatus.CANCELED);
                txn.setStatus(Transaction.TransactionStatus.FAILED);
                txn.setMessage("Thanh toán thất bại: " + finalCode);

                log.warn("❌ Payment FAILED for order {} with code {}", order.getId(), finalCode);
            }

            // 11. Lưu DB
            orderRepository.save(order);
            transactionRepository.save(txn);

            // 12. Trả về success cho VNPay
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
     * Return URL - User được redirect về đây sau khi thanh toán
     * ✅ CẬP NHẬT: Thêm logic cập nhật Order nếu IPN callback không được gọi
     */
    @Transactional // ❌ ĐÃ BỎ readOnly = true
    public Map<String, Object> handleVNPayReturn(Map<String, String> params) {
        Map<String, Object> response = new LinkedHashMap<>();

        try {
            log.info("=== VNPAY RETURN URL (NGROK) ===");
            log.info("Received params: {}", params);

            // 1. Lấy hash từ VNPay
            String receivedHash = params.get("vnp_SecureHash");
            if (receivedHash == null) {
                log.error("Missing vnp_SecureHash");
                response.put("success", false);
                response.put("message", "Thiếu chữ ký bảo mật");
                response.put("code", "NO_SIGNATURE");
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

            // 3. Tính lại chữ ký
            Map<String, String> hashResult = VNPayUtil.buildHashDataAndQuery(signParams);
            String hashData = hashResult.get("hashData");
            String calculatedHash = VNPayUtil.hmacSHA512(vnPayConfig.getHashSecret(), hashData);

            log.info("HashData       : {}", hashData);
            log.info("Calculated hash: {}", calculatedHash);
            log.info("Received hash  : {}", receivedHash);

            // 4. Verify signature
            if (!receivedHash.equalsIgnoreCase(calculatedHash)) {
                log.error("❌ Invalid signature");
                response.put("success", false);
                response.put("message", "Chữ ký không hợp lệ");
                response.put("code", "INVALID_SIGNATURE");
                return response;
            }

            log.info("✅ Signature verified");

            // 5. Lấy thông tin từ params
            String txnRef = params.get("vnp_TxnRef");
            String responseCode = params.get("vnp_ResponseCode");
            String transactionNo = params.get("vnp_TransactionNo");
            String bankCode = params.get("vnp_BankCode");
            String amountStr = params.get("vnp_Amount");
            String payDate = params.get("vnp_PayDate");
            String cardType = params.get("vnp_CardType");

            log.info("TxnRef: {}, ResponseCode: {}, TransactionNo: {}",
                    txnRef, responseCode, transactionNo);

            // 6. Parse orderId
            Long orderId;
            try {
                orderId = Long.parseLong(txnRef);
            } catch (NumberFormatException e) {
                log.error("Invalid txnRef format: {}", txnRef);
                response.put("success", false);
                response.put("message", "Mã đơn hàng không hợp lệ");
                response.put("code", "INVALID_ORDER_ID");
                return response;
            }

            // 7. Lấy thông tin từ DB
            Order order = orderRepository.findById(orderId).orElse(null);
            if (order == null) {
                log.error("Order not found: {}", orderId);
                response.put("success", false);
                response.put("message", "Không tìm thấy đơn hàng");
                response.put("code", "ORDER_NOT_FOUND");
                return response;
            }

            List<Transaction> transactions = transactionRepository.findByOrderId(orderId);
            Transaction transaction = transactions.isEmpty() ? new Transaction() : transactions.get(0);

            StudyPack pack = studyPackRepository.findById(order.getPackId()).orElse(null);
            if (pack == null) {
                log.error("Pack not found: {}", order.getPackId());
                response.put("success", false);
                response.put("message", "Không tìm thấy gói học tập");
                response.put("code", "PACK_NOT_FOUND");
                return response;
            }

            // 8. Verify amount
            long vnpAmount = Long.parseLong(amountStr);
            long orderAmount = order.getPriceAtPurchase()
                    .multiply(new java.math.BigDecimal("100"))
                    .longValue();

            if (vnpAmount != orderAmount) {
                log.warn("⚠️ Amount mismatch: expected {}, got {}", orderAmount, vnpAmount);
            }

            // 9. Kiểm tra trạng thái thanh toán
            boolean isSuccess = "00".equals(responseCode);

            log.info("Payment result: {} (code: {})", isSuccess ? "SUCCESS" : "FAILED", responseCode);

            // ✅ 10. CẬP NHẬT ORDER NẾU VẪN Ở TRẠNG THÁI PENDING
            if (order.getStatus() == Order.OrderStatus.PENDING) {
                log.info("⚠️ Order still PENDING, updating from Return URL...");

                // Cập nhật Transaction
                transaction.setOrderId(order.getId());
                transaction.setProvider("VNPay");
                transaction.setProviderTxnId(transactionNo);
                transaction.setMethod(bankCode);
                transaction.setAmount(order.getPriceAtPurchase());

                // Lưu raw payload
                Map<String, Object> rawPayload = new HashMap<>();
                params.forEach((k, v) -> rawPayload.put(k, v));
                transaction.setRawPayload(rawPayload);

                if (isSuccess) {
                    // ✅ Thanh toán thành công
                    order.setStatus(Order.OrderStatus.PAID);
                    transaction.setStatus(Transaction.TransactionStatus.SUCCEEDED);
                    transaction.setMessage("Thanh toán thành công");

                    // Tính expiresAt dựa vào durationDays
                    ZonedDateTime expiresAt = order.getStartedAt().plusDays(pack.getDurationDays());
                    order.setExpiresAt(expiresAt);

                    // Kích hoạt premium cho user
                    User user = userRepository.findById(order.getUserId())
                            .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));
                    user.setIsPremium(true);
                    userRepository.save(user);

                    log.info("✅ Payment SUCCESS for order {} - Updated from Return URL", order.getId());
                } else {
                    // ❌ Thanh toán thất bại
                    order.setStatus(Order.OrderStatus.CANCELED);
                    transaction.setStatus(Transaction.TransactionStatus.FAILED);
                    transaction.setMessage("Thanh toán thất bại: " + responseCode);

                    log.warn("❌ Payment FAILED for order {} with code {} - Updated from Return URL",
                            order.getId(), responseCode);
                }

                // Lưu DB
                orderRepository.save(order);
                transactionRepository.save(transaction);

            } else {
                log.info("ℹ️ Order already processed by IPN callback: {}", order.getStatus());
            }

            // 11. Build response
            response.put("success", isSuccess);
            response.put("responseCode", responseCode);
            response.put("message", isSuccess ? "Thanh toán thành công" : getErrorMessage(responseCode));
            response.put("code", isSuccess ? "SUCCESS" : "PAYMENT_FAILED");

            // Thông tin đơn hàng
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

            // Thông tin giao dịch
            Map<String, Object> txnInfo = new LinkedHashMap<>();
            txnInfo.put("txnRef", txnRef);
            txnInfo.put("transactionNo", transactionNo);
            txnInfo.put("bankCode", bankCode);
            txnInfo.put("cardType", cardType);
            txnInfo.put("payDate", payDate);
            txnInfo.put("payDateFormatted", formatPayDate(payDate));
            txnInfo.put("amount", vnpAmount / 100);

            if (transaction != null && transaction.getId() != null) {
                txnInfo.put("transactionId", transaction.getId());
                txnInfo.put("transactionStatus", transaction.getStatus().name());
                txnInfo.put("provider", transaction.getProvider());
            }

            response.put("transaction", txnInfo);

            // Thông tin user
            User user = userRepository.findById(order.getUserId()).orElse(null);
            if (user != null) {
                Map<String, Object> userInfo = new LinkedHashMap<>();
                userInfo.put("userId", user.getId());
                userInfo.put("email", user.getEmail());
                userInfo.put("fullName", user.getFullName());
                userInfo.put("isPremium", user.getIsPremium());
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
     * Format pay date từ yyyyMMddHHmmss sang dd/MM/yyyy HH:mm:ss
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
     * Map response code từ VNPay sang message tiếng Việt
     */
    private String getErrorMessage(String responseCode) {
        Map<String, String> errorMessages = new HashMap<>();
        errorMessages.put("00", "Giao dịch thành công");
        errorMessages.put("07", "Trừ tiền thành công. Giao dịch bị nghi ngờ (liên quan tới lừa đảo, giao dịch bất thường)");
        errorMessages.put("09", "Giao dịch không thành công do: Thẻ/Tài khoản của khách hàng chưa đăng ký dịch vụ InternetBanking tại ngân hàng");
        errorMessages.put("10", "Giao dịch không thành công do: Khách hàng xác thực thông tin thẻ/tài khoản không đúng quá 3 lần");
        errorMessages.put("11", "Giao dịch không thành công do: Đã hết hạn chờ thanh toán. Xin quý khách vui lòng thực hiện lại giao dịch");
        errorMessages.put("12", "Giao dịch không thành công do: Thẻ/Tài khoản của khách hàng bị khóa");
        errorMessages.put("13", "Giao dịch không thành công do Quý khách nhập sai mật khẩu xác thực giao dịch (OTP)");
        errorMessages.put("24", "Giao dịch không thành công do: Khách hàng hủy giao dịch");
        errorMessages.put("51", "Giao dịch không thành công do: Tài khoản của quý khách không đủ số dư để thực hiện giao dịch");
        errorMessages.put("65", "Giao dịch không thành công do: Tài khoản của Quý khách đã vượt quá hạn mức giao dịch trong ngày");
        errorMessages.put("75", "Ngân hàng thanh toán đang bảo trì");
        errorMessages.put("79", "Giao dịch không thành công do: KH nhập sai mật khẩu thanh toán quá số lần quy định");
        errorMessages.put("99", "Các lỗi khác (Lỗi không xác định)");

        return errorMessages.getOrDefault(responseCode, "Lỗi không xác định (Code: " + responseCode + ")");
    }

    /**
     * Lấy danh sách order của user hiện tại
     */

    public List<OrderDTO> getMyOrders() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String email = auth.getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        List<Order> orders = orderRepository.findByUserIdOrderByCreatedAtDesc(user.getId());

        // ✅ Convert và thêm packName
        return orders.stream().map(order -> {
            OrderDTO dto = OrderDTO.fromEntity(order);

            // Lấy thông tin pack để gán packName
            studyPackRepository.findById(order.getPackId())
                    .ifPresent(pack -> dto.setPackName(pack.getName()));

            return dto;
        }).collect(Collectors.toList());
    }

    /**
     * Utility method để loại bỏ dấu tiếng Việt theo quy định VNPay
     */
    private String removeVietnameseDiacritics(String text) {
        if (text == null) return "";
        String normalized = java.text.Normalizer.normalize(text, java.text.Normalizer.Form.NFD);
        return normalized.replaceAll("[\\p{InCombiningDiacriticalMarks}]", "")
                .replaceAll("[^a-zA-Z0-9\\s]", "")
                .trim();
    }
}