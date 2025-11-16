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

            // 2. Tạo params để verify - loại bỏ vnp_SecureHash và vnp_SecureHashType
            Map<String, String> signParams = new HashMap<>();
            for (Map.Entry<String, String> entry : params.entrySet()) {
                String key = entry.getKey();
                if (key.startsWith("vnp_")
                        && !key.equals("vnp_SecureHash")
                        && !key.equals("vnp_SecureHashType")) {
                    signParams.put(key, entry.getValue());
                }
            }

            // 3. Tính lại chữ ký theo specification VNPay
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

            // 6. Tìm order bằng TxnRef (orderId)
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

            // Lưu raw payload để debug
            Map<String, Object> rawPayload = new HashMap<>();
            params.forEach((k, v) -> rawPayload.put(k, v));
            txn.setRawPayload(rawPayload);

            // 10. Xử lý kết quả - ưu tiên vnp_ResponseCode theo spec VNPay
            String finalCode = responseCode != null ? responseCode : transactionStatus;
            if ("00".equals(finalCode)) {
                // Thanh toán thành công
                order.setStatus(Order.OrderStatus.PAID);
                txn.setStatus(Transaction.TransactionStatus.SUCCEEDED);
                txn.setMessage("Thanh toán thành công");

                // Cập nhật user thành premium
                User user = userRepository.findById(order.getUserId())
                        .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));
                user.setIsPremium(true);
                userRepository.save(user);

                log.info("Payment SUCCESS for order {}", order.getId());
            } else {
                // Thanh toán thất bại
                order.setStatus(Order.OrderStatus.CANCELED);
                txn.setStatus(Transaction.TransactionStatus.FAILED);
                txn.setMessage("Thanh toán thất bại: " + finalCode);

                log.warn("Payment FAILED for order {} with code {}", order.getId(), finalCode);
            }

            // 11. Lưu DB
            orderRepository.save(order);
            transactionRepository.save(txn);

            // 12. Trả về success cho VNPay THEO FORMAT JSON
            response.put("RspCode", "00");
            response.put("Message", "Confirm Success");

            log.info("IPN processed successfully");
            return response;

        } catch (Exception e) {
            log.error("Error processing IPN", e);
            response.put("RspCode", "99");
            response.put("Message", "Unknown error: " + e.getMessage());
            return response;
        }
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
        return orders.stream().map(OrderDTO::fromEntity).toList();
    }

    /**
     * Utility method để loại bỏ dấu tiếng Việt theo quy định VNPay
     */
    private String removeVietnameseDiacritics(String text) {
        if (text == null) return "";
        String normalized = java.text.Normalizer.normalize(text, java.text.Normalizer.Form.NFD);
        return normalized.replaceAll("[\\p{InCombiningDiacriticalMarks}]", "")
                .replaceAll("[^a-zA-Z0-9\\s]", "") // Chỉ giữ chữ, số và dấu cách
                .trim();
    }
}