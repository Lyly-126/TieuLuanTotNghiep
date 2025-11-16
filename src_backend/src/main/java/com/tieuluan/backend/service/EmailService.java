package com.tieuluan.backend.service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${app.mail.from}")
    private String fromEmail;

    public void sendOtpEmail(String toEmail, String otpCode) throws MessagingException {
        MimeMessage message = mailSender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

        helper.setFrom(fromEmail);
        helper.setTo(toEmail);
        helper.setSubject("Mã xác thực tài khoản của bạn");

        String htmlContent = buildOtpEmailTemplate(otpCode);
        helper.setText(htmlContent, true);

        mailSender.send(message);
    }

    private String buildOtpEmailTemplate(String otpCode) {
        return """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <style>
                    body { font-family: Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 0; }
                    .container { max-width: 600px; margin: 40px auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
                    .header { text-align: center; color: #333; }
                    .otp-box { background: #f8f9fa; border: 2px dashed #007bff; border-radius: 8px; padding: 20px; margin: 30px 0; text-align: center; }
                    .otp-code { font-size: 36px; font-weight: bold; color: #007bff; letter-spacing: 8px; }
                    .footer { text-align: center; color: #666; font-size: 14px; margin-top: 30px; }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>Xác thực tài khoản</h1>
                    </div>
                    <p>Xin chào,</p>
                    <p>Cảm ơn bạn đã đăng ký tài khoản. Vui lòng sử dụng mã OTP bên dưới để xác thực tài khoản của bạn:</p>
                    
                    <div class="otp-box">
                        <div class="otp-code">%s</div>
                    </div>
                    
                    <p><strong>Lưu ý:</strong></p>
                    <ul>
                        <li>Mã OTP này có hiệu lực trong <strong>5 phút</strong></li>
                        <li>Không chia sẻ mã này với bất kỳ ai</li>
                        <li>Nếu bạn không thực hiện yêu cầu này, vui lòng bỏ qua email</li>
                    </ul>
                    
                    <div class="footer">
                        <p>Trân trọng,<br>Đội ngũ hỗ trợ</p>
                    </div>
                </div>
            </body>
            </html>
            """.formatted(otpCode);
    }
}