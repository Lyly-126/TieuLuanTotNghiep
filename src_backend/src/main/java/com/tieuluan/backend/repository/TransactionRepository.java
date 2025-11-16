package com.tieuluan.backend.repository;

import com.tieuluan.backend.model.Transaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, Long> {
    List<Transaction> findByOrderId(Long orderId);
    Optional<Transaction> findByProviderTxnId(String providerTxnId);
}