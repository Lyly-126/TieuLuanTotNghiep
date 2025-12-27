package com.tieuluan.backend.controller;

import com.tieuluan.backend.model.Category;
import com.tieuluan.backend.model.Flashcard;
import com.tieuluan.backend.model.User;
import com.tieuluan.backend.repository.CategoryRepository;
import com.tieuluan.backend.repository.UserRepository;
import com.tieuluan.backend.service.FlashcardService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/flashcards")
@RequiredArgsConstructor
public class FlashcardController {

    private final FlashcardService flashcardService;
    private final CategoryRepository categoryRepository;
    private final UserRepository userRepository;

    // ==================== HELPER METHODS ====================

    private User getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || auth.getName() == null) {
            throw new RuntimeException("Không tìm thấy thông tin đăng nhập");
        }
        String email = auth.getName();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy user"));
    }

    private boolean isAdmin(User user) {
        return user.getRole() == User.UserRole.ADMIN;
    }

    /**
     * ✅ Check xem user có quyền TẠO flashcard không (check role)
     */
    private boolean canCreateFlashcard(User user) {
        User.UserRole role = user.getRole();
        return role == User.UserRole.ADMIN ||
                role == User.UserRole.TEACHER ||
                role == User.UserRole.PREMIUM_USER;
    }

    /**
     * ✅ Check xem user có phải CHỦ NHÂN của category không
     */
    private boolean isOwnerOfCategory(User user, Category category) {
        if (isAdmin(user)) return true;  // Admin có quyền với tất cả
        return category.getOwnerUserId() != null &&
                category.getOwnerUserId().equals(user.getId());
    }

    // ==================== PUBLIC ENDPOINTS ====================

    @GetMapping
    public ResponseEntity<List<Flashcard>> getAllFlashcards() {
        return ResponseEntity.ok(flashcardService.getAllFlashcards());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Flashcard> getFlashcardById(@PathVariable Long id) {
        Flashcard flashcard = flashcardService.getFlashcardById(id);
        return flashcard != null ? ResponseEntity.ok(flashcard) : ResponseEntity.notFound().build();
    }

    @GetMapping("/category/{categoryId}")
    public ResponseEntity<List<Flashcard>> getFlashcardsByCategory(@PathVariable Long categoryId) {
        return ResponseEntity.ok(flashcardService.getFlashcardsByCategory(categoryId));
    }

    @GetMapping("/random")
    public ResponseEntity<List<Flashcard>> getRandomFlashcards(@RequestParam(defaultValue = "20") int limit) {
        return ResponseEntity.ok(flashcardService.getRandomFlashcards(limit));
    }

    @GetMapping("/search")
    public ResponseEntity<List<Flashcard>> searchFlashcards(@RequestParam String q) {
        return ResponseEntity.ok(flashcardService.searchFlashcards(q));
    }

    // ==================== USER CRUD ====================

    /**
     * ✅ Tạo flashcard
     * - Check role: ADMIN/TEACHER/PREMIUM mới được tạo
     * - Check ownership: Phải là CHỦ NHÂN của category
     */
    @PostMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> createFlashcard(@RequestBody Map<String, Object> payload) {
        try {
            User currentUser = getCurrentUser();

            // ✅ Check role
            if (!canCreateFlashcard(currentUser)) {
                return ResponseEntity.status(403)
                        .body(Map.of("message", "Bạn cần nâng cấp tài khoản để tạo flashcard"));
            }

            // Validate
            if (payload.get("term") == null || payload.get("meaning") == null) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "term và meaning là bắt buộc"));
            }
            if (payload.get("categoryId") == null) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "categoryId là bắt buộc"));
            }

            Long categoryId = Long.valueOf(payload.get("categoryId").toString());
            Category category = categoryRepository.findById(categoryId)
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy category"));

            // ✅ Check ownership: Phải là CHỦ NHÂN của category
            if (!isOwnerOfCategory(currentUser, category)) {
                return ResponseEntity.status(403)
                        .body(Map.of("message", "Bạn không phải chủ nhân của học phần này"));
            }

            // Tạo flashcard
            Flashcard flashcard = new Flashcard();
            flashcard.setTerm((String) payload.get("term"));
            flashcard.setMeaning((String) payload.get("meaning"));
            flashcard.setPartOfSpeech((String) payload.get("partOfSpeech"));
            flashcard.setPhonetic((String) payload.get("phonetic"));
            flashcard.setImageUrl((String) payload.get("imageUrl"));
            flashcard.setTtsUrl((String) payload.get("ttsUrl"));
            flashcard.setCategory(category);

            Flashcard created = flashcardService.createFlashcard(flashcard);
            log.info("✅ User {} created flashcard in category {}", currentUser.getEmail(), categoryId);
            return ResponseEntity.status(201).body(created);

        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * ✅ Cập nhật flashcard
     * - Check role: ADMIN/TEACHER/PREMIUM
     * - Check ownership: Phải là CHỦ NHÂN của category chứa flashcard
     */
    @PutMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> updateFlashcard(@PathVariable Long id, @RequestBody Map<String, Object> payload) {
        try {
            User currentUser = getCurrentUser();

            // ✅ Check role
            if (!canCreateFlashcard(currentUser)) {
                return ResponseEntity.status(403)
                        .body(Map.of("message", "Bạn cần nâng cấp tài khoản để sửa flashcard"));
            }

            Flashcard flashcard = flashcardService.getFlashcardById(id);
            if (flashcard == null) {
                return ResponseEntity.notFound().build();
            }

            // ✅ Check ownership
            Category category = flashcard.getCategory();
            if (category != null && !isOwnerOfCategory(currentUser, category)) {
                return ResponseEntity.status(403)
                        .body(Map.of("message", "Bạn không phải chủ nhân của học phần này"));
            }

            // Update
            if (payload.containsKey("term")) flashcard.setTerm((String) payload.get("term"));
            if (payload.containsKey("meaning")) flashcard.setMeaning((String) payload.get("meaning"));
            if (payload.containsKey("partOfSpeech")) flashcard.setPartOfSpeech((String) payload.get("partOfSpeech"));
            if (payload.containsKey("phonetic")) flashcard.setPhonetic((String) payload.get("phonetic"));
            if (payload.containsKey("imageUrl")) flashcard.setImageUrl((String) payload.get("imageUrl"));
            if (payload.containsKey("ttsUrl")) flashcard.setTtsUrl((String) payload.get("ttsUrl"));

            Flashcard updated = flashcardService.updateFlashcard(flashcard);
            log.info("✅ User {} updated flashcard {}", currentUser.getEmail(), id);
            return ResponseEntity.ok(updated);

        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * ✅ Xóa flashcard
     * - Check role: ADMIN/TEACHER/PREMIUM
     * - Check ownership: Phải là CHỦ NHÂN của category chứa flashcard
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> deleteFlashcard(@PathVariable Long id) {
        try {
            User currentUser = getCurrentUser();

            // ✅ Check role
            if (!canCreateFlashcard(currentUser)) {
                return ResponseEntity.status(403)
                        .body(Map.of("message", "Bạn cần nâng cấp tài khoản để xóa flashcard"));
            }

            Flashcard flashcard = flashcardService.getFlashcardById(id);
            if (flashcard == null) {
                return ResponseEntity.notFound().build();
            }

            // ✅ Check ownership
            Category category = flashcard.getCategory();
            if (category != null && !isOwnerOfCategory(currentUser, category)) {
                return ResponseEntity.status(403)
                        .body(Map.of("message", "Bạn không phải chủ nhân của học phần này"));
            }

            flashcardService.deleteFlashcard(id);
            log.info("✅ User {} deleted flashcard {}", currentUser.getEmail(), id);
            return ResponseEntity.ok(Map.of("message", "Đã xóa flashcard thành công"));

        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    // ==================== ADMIN ONLY ====================

    @GetMapping("/admin/stats")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getFlashcardStats() {
        return ResponseEntity.ok(flashcardService.getFlashcardStats());
    }
}