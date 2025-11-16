package com.tieuluan.backend.util;

import java.text.Normalizer;
import java.util.regex.Pattern;

public class VNPayTextUtil {

    /**
     * Chuẩn hóa vnp_OrderInfo theo quy tắc của VNPAY.
     * 1. Bỏ dấu tiếng Việt.
     * 2. Thay thế dấu cách và các ký tự đặc biệt bằng dấu gạch ngang "-".
     * 3. Xóa các dấu gạch ngang liền kề.
     * 4. Xóa dấu gạch ngang ở đầu/cuối chuỗi.
     */
    public static String normalizeOrderInfo(String s) {
        if (s == null) return "";

        // 1. Bỏ dấu tiếng Việt
        String noAccent = Normalizer.normalize(s, Normalizer.Form.NFD);
        Pattern pattern = Pattern.compile("\\p{InCombiningDiacriticalMarks}+");
        noAccent = pattern.matcher(noAccent).replaceAll("");

        // 2. Thay thế dấu cách VÀ các ký tự không phải chữ/số
        //    bằng dấu gạch ngang "-"
        //    [^A-Za-z0-9] -> Bất cứ thứ gì KHÔNG phải chữ/số
        String cleaned = noAccent.replaceAll("[^A-Za-z0-9]", "-");

        // 3. Xóa các dấu gạch ngang liền kề (ví dụ: "a---b" -> "a-b")
        cleaned = cleaned.replaceAll("-+", "-");

        // 4. Xóa dấu gạch ngang ở đầu/cuối chuỗi (nếu có)
        cleaned = cleaned.replaceAll("^-|-$", "");

        return cleaned;
    }
}