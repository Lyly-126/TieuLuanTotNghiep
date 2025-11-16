package com.tieuluan.backend.util;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.*;

/**
 * VNPay Utility Class - THEO ĐẤT TRANG TÀI LIỆU OFFICIAL VNPay
 * https://sandbox.vnpayment.vn/apis/docs/thanh-toan-pay/pay.html
 */
public class VNPayUtil {

    /**
     * Tính HMAC SHA512 - GIỐNG HỆT CODE MẪU VNPay
     */
    public static String hmacSHA512(final String key, final String data) {
        try {
            if (key == null || data == null) {
                throw new NullPointerException();
            }
            final Mac hmac512 = Mac.getInstance("HmacSHA512");
            byte[] hmacKeyBytes = key.getBytes(StandardCharsets.UTF_8);
            final SecretKeySpec secretKey = new SecretKeySpec(hmacKeyBytes, "HmacSHA512");
            hmac512.init(secretKey);
            byte[] dataBytes = data.getBytes(StandardCharsets.UTF_8);
            byte[] result = hmac512.doFinal(dataBytes);
            StringBuilder sb = new StringBuilder(2 * result.length);
            for (byte b : result) {
                sb.append(String.format("%02x", b & 0xff));
            }
            return sb.toString();

        } catch (Exception ex) {
            return "";
        }
    }

    /**
     * Build hashData và query string THEO ĐÚNG CODE MẪU VNPay trong tài liệu
     * Quan trọng: Cả hashData và query đều encode dữ liệu
     */
    public static Map<String, String> buildHashDataAndQuery(Map<String, String> params) {
        // Sort params theo alphabet - BẮNG BUỘC theo VNPay spec
        List<String> fieldNames = new ArrayList<>(params.keySet());
        Collections.sort(fieldNames);

        StringBuilder hashData = new StringBuilder();
        StringBuilder query = new StringBuilder();
        Iterator<String> itr = fieldNames.iterator();

        while (itr.hasNext()) {
            String fieldName = itr.next();
            String fieldValue = params.get(fieldName);

            if ((fieldValue != null) && (fieldValue.length() > 0)) {
                try {
                    // Build hash data - ENCODE cả key và value như code mẫu VNPay
                    hashData.append(URLEncoder.encode(fieldName, StandardCharsets.UTF_8.toString()));
                    hashData.append('=');
                    hashData.append(URLEncoder.encode(fieldValue, StandardCharsets.UTF_8.toString()));

                    // Build query - ENCODE cả key và value như code mẫu VNPay
                    query.append(URLEncoder.encode(fieldName, StandardCharsets.UTF_8.toString()));
                    query.append('=');
                    query.append(URLEncoder.encode(fieldValue, StandardCharsets.UTF_8.toString()));

                    if (itr.hasNext()) {
                        query.append('&');
                        hashData.append('&');
                    }
                } catch (Exception e) {
                    // Ignore encoding errors
                }
            }
        }

        Map<String, String> result = new HashMap<>();
        result.put("hashData", hashData.toString());
        result.put("queryUrl", query.toString());
        return result;
    }

    /**
     * Generate random number - GIỐNG Code mẫu VNPay
     */
    public static String getRandomNumber(int len) {
        Random rnd = new Random();
        String chars = "0123456789";
        StringBuilder sb = new StringBuilder(len);
        for (int i = 0; i < len; i++) {
            sb.append(chars.charAt(rnd.nextInt(chars.length())));
        }
        return sb.toString();
    }

    /**
     * Get IP Address - GIỐNG Code mẫu VNPay
     */
    public static String getIpAddress(String xForwardedFor, String remoteAddr) {
        String ipAddress;
        try {
            if (xForwardedFor == null || xForwardedFor.isEmpty()) {
                ipAddress = remoteAddr;
            } else {
                ipAddress = xForwardedFor.split(",")[0].trim();
            }
        } catch (Exception e) {
            ipAddress = "Invalid IP:" + e.getMessage();
        }
        return ipAddress;
    }
}