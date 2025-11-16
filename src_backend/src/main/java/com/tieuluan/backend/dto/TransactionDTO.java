package com.tieuluan.backend.dto;

import com.tieuluan.backend.model.Transaction;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.ZonedDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TransactionDTO {
    private Long id;
    private Long orderId;
    private BigDecimal amount;
    private String provider;
    private String method;
    private String providerTxnId;
    private String status;
    private String message;
    private ZonedDateTime createdAt;

    public static TransactionDTO fromEntity(Transaction transaction) {
        TransactionDTO dto = new TransactionDTO();
        dto.setId(transaction.getId());
        dto.setOrderId(transaction.getOrderId());
        dto.setAmount(transaction.getAmount());
        dto.setProvider(transaction.getProvider());
        dto.setMethod(transaction.getMethod());
        dto.setProviderTxnId(transaction.getProviderTxnId());
        dto.setStatus(transaction.getStatus().name());
        dto.setMessage(transaction.getMessage());
        dto.setCreatedAt(transaction.getCreatedAt());
        return dto;
    }
}
