package com.tieuluan.backend.dto;

import com.tieuluan.backend.model.Order;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.ZonedDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class OrderDTO {
    private Long id;
    private Long userId;
    private Long packId;
    private String packName;
    private BigDecimal priceAtPurchase;
    private String status;
    private ZonedDateTime startedAt;
    private ZonedDateTime expiresAt;
    private ZonedDateTime createdAt;

    public static OrderDTO fromEntity(Order order) {
        OrderDTO dto = new OrderDTO();
        dto.setId(order.getId());
        dto.setUserId(order.getUserId());
        dto.setPackId(order.getPackId());
        dto.setPriceAtPurchase(order.getPriceAtPurchase());
        dto.setStatus(order.getStatus().name());
        dto.setStartedAt(order.getStartedAt());
        dto.setExpiresAt(order.getExpiresAt());
        dto.setCreatedAt(order.getCreatedAt());
        return dto;
    }

    // Inner classes
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreateRequest {
        private Long packId;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class VNPayPaymentResponse {
        private String paymentUrl;
        private Long orderId;
        private String message;
    }
}