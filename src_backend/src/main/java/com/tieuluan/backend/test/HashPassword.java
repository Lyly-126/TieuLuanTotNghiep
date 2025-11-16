package com.tieuluan.backend.test;
import org.mindrot.jbcrypt.BCrypt;
import java.util.Scanner;

public class HashPassword {
    // Cost mặc định (10–14 là hợp lý). Cứ để 12 cho nhanh-gọn-an-toàn.
    private static final int COST = 12;

    public static void main(String[] args) {
        String raw = null;

        // Ưu tiên lấy từ tham số dòng lệnh
        if (args.length > 0 && args[0] != null && !args[0].isBlank()) {
            raw = args[0];
        } else {
            // Không có tham số thì đọc từ stdin (có hiển thị ký tự)
            System.out.print("Nhap mat khau: ");
            Scanner sc = new Scanner(System.in);
            raw = sc.nextLine();
        }

        if (raw == null || raw.isBlank()) {
            System.err.println("Mat khau khong duoc rong.");
            System.exit(1);
        }

        String salt = BCrypt.gensalt(COST);
        String hashed = BCrypt.hashpw(raw, salt);
        System.out.println("Mat khau da hash: " + hashed);
    }
}
