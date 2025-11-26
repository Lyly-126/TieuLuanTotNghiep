package com.tieuluan.backend.controller;

import com.google.gson.Gson;
import com.tieuluan.backend.dto.OrderDTO;
import com.tieuluan.backend.service.PaymentService;
import com.tieuluan.backend.util.VNPayUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.ZonedDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Slf4j
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
    public ResponseEntity<?> createOrder(@RequestBody OrderDTO.CreateRequest request) {
        try {
            OrderDTO order = paymentService.createOrder(request.getPackId());
            return ResponseEntity.ok(order);
        } catch (RuntimeException e) {
            log.error("Error creating order: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * Tạo URL thanh toán VNPay
     */
    @PostMapping("/vnpay/create")
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
     * ⚠️ ĐÂY LÀ METHOD QUAN TRỌNG - Dùng để confirm thanh toán
     */
    @RequestMapping(
            value = "/vnpay/callback",
            method = {RequestMethod.GET, RequestMethod.POST}
    )
    public ResponseEntity<?> vnpayCallback(@RequestParam Map<String, String> params) {
        try {
            log.info("========================================");
            log.info("🔔 VNPAY IPN CALLBACK RECEIVED!");
            log.info("Time: {}", ZonedDateTime.now());
            log.info("Params: {}", params);
            log.info("========================================");
            // ✅ GỌI handleVNPayCallback thay vì handleVNPayReturn
            Map<String, String> response = paymentService.handleVNPayCallback(params);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error processing VNPay callback: {}", e.getMessage());
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
     * URL này sẽ được mở trong browser, sau đó Flutter sẽ parse kết quả
     */
    @GetMapping("/vnpay/return")
    public ResponseEntity<String> vnpayReturn(@RequestParam Map<String, String> params) {
        try {
            log.info("=== USER RETURNED FROM VNPAY (NGROK) ===");

            // Xử lý return URL
            Map<String, Object> response = paymentService.handleVNPayReturn(params);

            // Lấy thông tin
            boolean success = (boolean) response.getOrDefault("success", false);
            String message = (String) response.getOrDefault("message", "");
            String responseCode = (String) response.getOrDefault("responseCode", "");

            log.info("Payment result: {} ({})", success ? "SUCCESS ✅" : "FAILED ❌", responseCode);

            // Tạo HTML response để hiển thị trong browser
            String html = buildReturnHtml(success, message, response);

            return ResponseEntity.ok()
                    .header("Content-Type", "text/html; charset=UTF-8")
                    .body(html);

        } catch (Exception e) {
            log.error("❌ Error processing return URL", e);

            String errorHtml = buildErrorHtml(e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .header("Content-Type", "text/html; charset=UTF-8")
                    .body(errorHtml);
        }
    }

    /**
     * Build HTML để hiển thị kết quả thanh toán trong browser
     */
    private String buildReturnHtml(boolean success, String message, Map<String, Object> data) {
        String statusIcon = success ? "✅" : "❌";
        String statusColor = success ? "#10b981" : "#ef4444";
        String statusText = success ? "Thanh toán thành công" : "Thanh toán thất bại";

        StringBuilder html = new StringBuilder();
        html.append("<!DOCTYPE html>");
        html.append("<html lang='vi'>");
        html.append("<head>");
        html.append("<meta charset='UTF-8'>");
        html.append("<meta name='viewport' content='width=device-width, initial-scale=1.0'>");
        html.append("<title>Kết quả thanh toán</title>");
        html.append("<style>");
        html.append("* { margin: 0; padding: 0; box-sizing: border-box; }");
        html.append("body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; ");
        html.append("background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); ");
        html.append("min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 20px; }");
        html.append(".container { background: white; border-radius: 20px; padding: 40px; max-width: 500px; width: 100%; box-shadow: 0 20px 60px rgba(0,0,0,0.3); }");
        html.append(".icon { font-size: 80px; text-align: center; margin-bottom: 20px; }");
        html.append(".title { font-size: 24px; font-weight: bold; text-align: center; color: " + statusColor + "; margin-bottom: 10px; }");
        html.append(".message { text-align: center; color: #666; margin-bottom: 30px; line-height: 1.5; }");
        html.append(".info-box { background: #f9fafb; border-radius: 12px; padding: 20px; margin-bottom: 20px; }");
        html.append(".info-row { display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #e5e7eb; }");
        html.append(".info-row:last-child { border-bottom: none; }");
        html.append(".info-label { color: #6b7280; font-size: 14px; }");
        html.append(".info-value { color: #111827; font-weight: 600; font-size: 14px; text-align: right; }");
        html.append(".btn { display: block; width: 100%; padding: 16px; background: " + statusColor + "; ");
        html.append("color: white; text-align: center; border-radius: 12px; text-decoration: none; ");
        html.append("font-weight: 600; margin-top: 20px; transition: transform 0.2s; }");
        html.append(".btn:hover { transform: translateY(-2px); }");
        html.append(".json-data { display: none; }");
        html.append("</style>");
        html.append("</head>");
        html.append("<body>");
        html.append("<div class='container'>");
        html.append("<div class='icon'>").append(statusIcon).append("</div>");
        html.append("<div class='title'>").append(statusText).append("</div>");
        html.append("<div class='message'>").append(message).append("</div>");

        // Thông tin đơn hàng
        if (data.containsKey("order")) {
            @SuppressWarnings("unchecked")
            Map<String, Object> order = (Map<String, Object>) data.get("order");
            html.append("<div class='info-box'>");
            html.append("<div class='info-row'><span class='info-label'>Mã đơn hàng</span><span class='info-value'>#").append(order.get("orderId")).append("</span></div>");
            html.append("<div class='info-row'><span class='info-label'>Gói dịch vụ</span><span class='info-value'>").append(order.get("packName")).append("</span></div>");
            html.append("<div class='info-row'><span class='info-label'>Số tiền</span><span class='info-value'>").append(order.get("amount")).append(" VNĐ</span></div>");
            if (order.containsKey("expiresAt")) {
                html.append("<div class='info-row'><span class='info-label'>Hạn sử dụng</span><span class='info-value'>").append(formatDate(order.get("expiresAt").toString())).append("</span></div>");
            }
            html.append("</div>");
        }

        // Thông tin giao dịch
        if (data.containsKey("transaction")) {
            @SuppressWarnings("unchecked")
            Map<String, Object> txn = (Map<String, Object>) data.get("transaction");
            html.append("<div class='info-box'>");
            html.append("<div class='info-row'><span class='info-label'>Mã GD VNPay</span><span class='info-value'>").append(txn.getOrDefault("transactionNo", "N/A")).append("</span></div>");
            html.append("<div class='info-row'><span class='info-label'>Ngân hàng</span><span class='info-value'>").append(txn.getOrDefault("bankCode", "N/A")).append("</span></div>");
            if (txn.containsKey("payDateFormatted")) {
                html.append("<div class='info-row'><span class='info-label'>Thời gian</span><span class='info-value'>").append(txn.get("payDateFormatted")).append("</span></div>");
            }
            html.append("</div>");
        }

        html.append("<a href='#' class='btn' onclick='closeWindow()'>Đóng cửa sổ này</a>");

        // Embed JSON data để Flutter có thể parse
        html.append("<div class='json-data' id='payment-result-data'>");
        html.append(new Gson().toJson(data));
        html.append("</div>");

        html.append("<script>");
        html.append("function closeWindow() { ");
        html.append("  if (window.opener) { window.close(); } ");
        html.append("  else { window.location.href = 'about:blank'; window.close(); }");
        html.append("}");
        html.append("setTimeout(() => { closeWindow(); }, 5000);"); // Auto close sau 5s
        html.append("</script>");

        html.append("</div>");
        html.append("</body>");
        html.append("</html>");

        return html.toString();
    }

    /**
     * Build HTML cho trường hợp lỗi
     */
    private String buildErrorHtml(String errorMessage) {
        return "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Lỗi</title></head>" +
                "<body style='font-family: Arial; padding: 40px; text-align: center;'>" +
                "<h1 style='color: #ef4444;'>❌ Lỗi xử lý thanh toán</h1>" +
                "<p style='color: #666; margin: 20px 0;'>" + errorMessage + "</p>" +
                "<button onclick='window.close()' style='padding: 12px 24px; background: #ef4444; color: white; border: none; border-radius: 8px; cursor: pointer;'>Đóng cửa sổ</button>" +
                "</body></html>";
    }

    /**
     * Format date string
     */
    private String formatDate(String dateStr) {
        try {
            java.time.ZonedDateTime date = java.time.ZonedDateTime.parse(dateStr);
            return String.format("%02d/%02d/%d",
                    date.getDayOfMonth(),
                    date.getMonthValue(),
                    date.getYear());
        } catch (Exception e) {
            return dateStr;
        }
    }

    /**
     * Lấy danh sách order của user
     */
    @GetMapping("/my-orders")
    public ResponseEntity<?> getMyOrders() {
        try {
            List<OrderDTO> orders = paymentService.getMyOrders();
            return ResponseEntity.ok(orders);
        } catch (RuntimeException e) {
            log.error("Error getting orders: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }
}