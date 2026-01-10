package com.tieuluan.backend.service;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.*;
import com.tieuluan.backend.model.Category;
import com.tieuluan.backend.model.CategoryReminder;
import com.tieuluan.backend.repository.CategoryRepository;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class FirebaseNotificationService {

    private final CategoryReminderService categoryReminderService;
    private final CategoryRepository categoryRepository;

    @Value("${firebase.credentials.path:firebase-service-account.json}")
    private String firebaseCredentialsPath;

    @Value("${firebase.enabled:false}")
    private boolean firebaseEnabled;

    private boolean initialized = false;

    @PostConstruct
    public void initialize() {
        if (!firebaseEnabled) {
            log.info("🔕 Firebase is disabled");
            return;
        }

        try {
            ClassPathResource resource = new ClassPathResource(firebaseCredentialsPath);
            InputStream serviceAccount = resource.getInputStream();

            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .build();

            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseApp.initializeApp(options);
            }
            initialized = true;
            log.info("✅ Firebase initialized successfully");
        } catch (IOException e) {
            log.error("❌ Failed to initialize Firebase: {}", e.getMessage());
        }
    }

    // ==================== SEND NOTIFICATION ====================

    public boolean sendNotification(String fcmToken, String title, String body, Map<String, String> data) {
        if (!initialized || !firebaseEnabled || fcmToken == null || fcmToken.isEmpty()) {
            return false;
        }

        try {
            Message.Builder builder = Message.builder()
                    .setToken(fcmToken)
                    .setNotification(Notification.builder()
                            .setTitle(title)
                            .setBody(body)
                            .build())
                    .setAndroidConfig(AndroidConfig.builder()
                            .setNotification(AndroidNotification.builder()
                                    .setIcon("ic_notification")
                                    .setColor("#4CAF50")
                                    .setSound("default")
                                    .setChannelId("study_reminders")
                                    .build())
                            .setPriority(AndroidConfig.Priority.HIGH)
                            .build())
                    .setApnsConfig(ApnsConfig.builder()
                            .setAps(Aps.builder()
                                    .setSound("default")
                                    .setBadge(1)
                                    .build())
                            .build());

            if (data != null) {
                builder.putAllData(data);
            }

            FirebaseMessaging.getInstance().send(builder.build());
            return true;
        } catch (FirebaseMessagingException e) {
            log.error("❌ Send notification failed: {}", e.getMessage());
            return false;
        }
    }

    public boolean sendCategoryReminder(String fcmToken, Long categoryId, String categoryName, String customMessage) {
        String title = "📚 Đến giờ học " + categoryName + "!";
        String body = customMessage != null && !customMessage.isEmpty()
                ? customMessage
                : "Hãy dành ít phút ôn tập \"" + categoryName + "\" nhé!";

        Map<String, String> data = new HashMap<>();
        data.put("type", "CATEGORY_REMINDER");
        data.put("categoryId", String.valueOf(categoryId));
        data.put("categoryName", categoryName);
        data.put("action", "OPEN_CATEGORY");
        data.put("click_action", "FLUTTER_NOTIFICATION_CLICK");

        return sendNotification(fcmToken, title, body, data);
    }

    public boolean sendTestNotification(String fcmToken) {
        return sendNotification(fcmToken, "🧪 Test", "Firebase đã hoạt động!",
                Map.of("type", "TEST"));
    }

    // ==================== SCHEDULED JOB ====================

    @Scheduled(cron = "0 * * * * *") // Mỗi phút
    public void sendScheduledReminders() {
        if (!initialized || !firebaseEnabled) return;

        try {
            // Lấy reminders cần gửi (đã có fcmToken trong entity)
            List<CategoryReminder> reminders = categoryReminderService.getRemindersToSendNow();

            int sent = 0;
            for (CategoryReminder r : reminders) {
                // fcmToken lấy trực tiếp từ CategoryReminder
                if (r.getFcmToken() != null && !r.getFcmToken().isEmpty()) {
                    Category cat = categoryRepository.findById(r.getCategoryId()).orElse(null);
                    String categoryName = cat != null ? cat.getName() : "Unknown";

                    boolean ok = sendCategoryReminder(
                            r.getFcmToken(),
                            r.getCategoryId(),
                            categoryName,
                            r.getCustomMessage()
                    );
                    if (ok) sent++;
                }
            }

            if (sent > 0) {
                log.info("✅ Sent {} reminders", sent);
            }
        } catch (Exception e) {
            log.error("❌ Scheduled reminder error: {}", e.getMessage());
        }
    }

    public boolean isInitialized() {
        return initialized && firebaseEnabled;
    }
}