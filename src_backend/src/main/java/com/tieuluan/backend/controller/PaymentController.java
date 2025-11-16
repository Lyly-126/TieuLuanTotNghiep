package com.tieuluan.backend.controller;

import com.tieuluan.backend.dto.OrderDTO;
import com.tieuluan.backend.service.PaymentService;
import com.tieuluan.backend.util.VNPayUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/payment")
@CrossOrigin(origins = "*")
public class PaymentController {

    @Autowired
    private PaymentService paymentService;

    /**
     * Tạo order mới
     */
    @PostMapping("/create-order")
    @PreAuthorize("hasAnyRole('USER', 'ADMIN')")
    public ResponseEntity<?> createOrder(@RequestBody OrderDTO.CreateRequest request) {
        try {
            OrderDTO order = paymentService.createOrder(request.getPackId());
            return ResponseEntity.ok(order);
        } catch (RuntimeException e) {
            System.err.println("Error creating order: " + e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * Tạo URL thanh toán VNPay
     */
    @PostMapping("/vnpay/create")
    @PreAuthorize("hasAnyRole('USER', 'ADMIN')")
    public ResponseEntity<?> createVNPayPayment(
            @RequestParam Long orderId,
            @RequestHeader(value = "X-Forwarded-For", required = false) String xForwardedFor,
            @RequestHeader(value = "X-Real-IP", required = false) String xRealIp
    ) {
        try {
            // Lấy IP theo logic code mẫu Config.getIpAddress
            String ipAddress = VNPayUtil.getIpAddress(xForwardedFor, xRealIp != null ? xRealIp : "127.0.0.1");

            // Convert IPv6 localhost to IPv4
            if ("0:0:0:0:0:0:0:1".equals(ipAddress) || "::1".equals(ipAddress)) {
                ipAddress = "127.0.0.1";
            }

            OrderDTO.VNPayPaymentResponse response =
                    paymentService.createVNPayPayment(orderId, ipAddress);

            System.out.println("Created payment URL for order " + orderId);
            return ResponseEntity.ok(response);

        } catch (RuntimeException e) {
            System.err.println("Error creating payment URL for order " + orderId + ": " + e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * IPN Callback - VNPay gọi để thông báo kết quả
     */
    @RequestMapping(
            value = "/vnpay/callback",
            method = {RequestMethod.GET, RequestMethod.POST}
    )
    public ResponseEntity<?> vnpayCallback(@RequestParam Map<String, String> params) {
        try {
            System.out.println("Received VNPay IPN callback");
            Map<String, String> response = paymentService.handleVNPayCallback(params);
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            System.err.println("Error processing VNPay callback: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of(
                            "RspCode", "99",
                            "Message", "Error: " + e.getMessage()
                    ));
        }
    }

    /**
     * Return URL - User được redirect về đây sau khi thanh toán
     */
    @GetMapping("/vnpay/return")
    public ResponseEntity<?> vnpayReturn(@RequestParam Map<String, String> params) {
        try {
            System.out.println("User returned from VNPay");

            String responseCode = params.get("vnp_ResponseCode");
            String txnRef = params.get("vnp_TxnRef");
            String amount = params.get("vnp_Amount");
            String transactionNo = params.get("vnp_TransactionNo");
            String bankCode = params.get("vnp_BankCode");

            if (txnRef == null || amount == null) {
                System.err.println("Missing required params in return URL");
                Map<String, Object> error = new LinkedHashMap<>();
                error.put("success", false);
                error.put("message", "Thiếu tham số trả về từ VNPAY");
                return ResponseEntity.badRequest().body(error);
            }

            boolean isSuccess = "00".equals(responseCode);

            Map<String, Object> body = new LinkedHashMap<>();
            body.put("success", isSuccess);
            body.put("responseCode", responseCode);
            body.put("txnRef", txnRef);
            body.put("amount", Long.parseLong(amount) / 100);
            body.put("transactionNo", transactionNo);
            body.put("bankCode", bankCode);
            body.put("message", isSuccess
                    ? "Thanh toán thành công"
                    : "Thanh toán không thành công");

            System.out.println("Payment " + (isSuccess ? "SUCCESS" : "FAILED") + " for txnRef " + txnRef);

            return ResponseEntity.ok(body);

        } catch (Exception e) {
            System.err.println("Error processing return URL: " + e.getMessage());
            e.printStackTrace();
            Map<String, Object> error = new LinkedHashMap<>();
            error.put("success", false);
            error.put("message", "Lỗi xử lý kết quả: " + e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    /**
     * Lấy danh sách order của user
     */
    @GetMapping("/my-orders")
    @PreAuthorize("hasAnyRole('USER', 'ADMIN')")
    public ResponseEntity<?> getMyOrders() {
        try {
            List<OrderDTO> orders = paymentService.getMyOrders();
            return ResponseEntity.ok(orders);
        } catch (RuntimeException e) {
            System.err.println("Error getting orders: " + e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }
}