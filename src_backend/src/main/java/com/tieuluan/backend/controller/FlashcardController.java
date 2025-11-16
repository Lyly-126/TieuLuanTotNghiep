package com.tieuluan.backend.controller;

import com.tieuluan.backend.model.Category;
import com.tieuluan.backend.model.Flashcard;
import com.tieuluan.backend.repository.CategoryRepository;
import com.tieuluan.backend.service.FlashcardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/flashcards")
@RequiredArgsConstructor
public class FlashcardController {

    private final FlashcardService flashcardService;
    private final CategoryRepository categoryRepository; // ✅ THÊM: Cần để load Category

    // ==================== PUBLIC ENDPOINTS ====================

    /**
     * Lấy tất cả flashcards (public)
     */
    @GetMapping
    public ResponseEntity<List<Flashcard>> getAllFlashcards() {
        try {
            List<Flashcard> flashcards = flashcardService.getAllFlashcards();
            return ResponseEntity.ok(flashcards);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * Lấy flashcard theo ID
     */
    @GetMapping("/{id}")
    public ResponseEntity<Flashcard> getFlashcardById(@PathVariable Long id) {
        try {
            Flashcard flashcard = flashcardService.getFlashcardById(id);
            if (flashcard != null) {
                return ResponseEntity.ok(flashcard);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * Lấy flashcards theo category ID
     */
    @GetMapping("/category/{categoryId}")
    public ResponseEntity<List<Flashcard>> getFlashcardsByCategory(@PathVariable Long categoryId) {
        try {
            List<Flashcard> flashcards = flashcardService.getFlashcardsByCategory(categoryId);
            return ResponseEntity.ok(flashcards);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * Lấy flashcards ngẫu nhiên
     */
    @GetMapping("/random")
    public ResponseEntity<List<Flashcard>> getRandomFlashcards(
            @RequestParam(defaultValue = "20") int limit) {
        try {
            List<Flashcard> flashcards = flashcardService.getRandomFlashcards(limit);
            return ResponseEntity.ok(flashcards);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * Tìm kiếm flashcards theo từ khóa
     */
    @GetMapping("/search")
    public ResponseEntity<List<Flashcard>> searchFlashcards(@RequestParam String q) {
        try {
            List<Flashcard> flashcards = flashcardService.searchFlashcards(q);
            return ResponseEntity.ok(flashcards);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    // ==================== ADMIN ENDPOINTS ====================

    /**
     * Tạo flashcard mới (Admin only)
     */
    @PostMapping("/admin")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Flashcard> createFlashcard(@RequestBody Map<String, Object> payload) {
        try {
            Flashcard flashcard = new Flashcard();
            flashcard.setTerm((String) payload.get("term"));
            flashcard.setPartOfSpeech((String) payload.get("partOfSpeech"));
            flashcard.setPhonetic((String) payload.get("phonetic"));
            flashcard.setImageUrl((String) payload.get("imageUrl"));
            flashcard.setMeaning((String) payload.get("meaning"));
            flashcard.setTtsUrl((String) payload.get("ttsUrl"));

            // ✅ FIXED: Load Category từ DB
            if (payload.get("categoryId") != null) {
                Long categoryId = Long.valueOf(payload.get("categoryId").toString());
                Category category = categoryRepository.findById(categoryId)
                        .orElseThrow(() -> new RuntimeException("Category not found with ID: " + categoryId));
                flashcard.setCategory(category);
            }

            Flashcard createdFlashcard = flashcardService.createFlashcard(flashcard);
            return ResponseEntity.status(201).body(createdFlashcard);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    /**
     * Cập nhật flashcard (Admin only)
     */
    @PutMapping("/admin/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Flashcard> updateFlashcard(
            @PathVariable Long id,
            @RequestBody Map<String, Object> payload) {
        try {
            Flashcard existingFlashcard = flashcardService.getFlashcardById(id);
            if (existingFlashcard == null) {
                return ResponseEntity.notFound().build();
            }

            // Cập nhật các field
            if (payload.containsKey("term")) {
                existingFlashcard.setTerm((String) payload.get("term"));
            }
            if (payload.containsKey("partOfSpeech")) {
                existingFlashcard.setPartOfSpeech((String) payload.get("partOfSpeech"));
            }
            if (payload.containsKey("phonetic")) {
                existingFlashcard.setPhonetic((String) payload.get("phonetic"));
            }
            if (payload.containsKey("imageUrl")) {
                existingFlashcard.setImageUrl((String) payload.get("imageUrl"));
            }
            if (payload.containsKey("meaning")) {
                existingFlashcard.setMeaning((String) payload.get("meaning"));
            }
            if (payload.containsKey("ttsUrl")) {
                existingFlashcard.setTtsUrl((String) payload.get("ttsUrl"));
            }

            // ✅ FIXED: Load Category từ DB
            if (payload.containsKey("categoryId")) {
                Long categoryId = Long.valueOf(payload.get("categoryId").toString());
                Category category = categoryRepository.findById(categoryId)
                        .orElseThrow(() -> new RuntimeException("Category not found with ID: " + categoryId));
                existingFlashcard.setCategory(category);
            }

            Flashcard updatedFlashcard = flashcardService.updateFlashcard(existingFlashcard);
            return ResponseEntity.ok(updatedFlashcard);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * Xóa flashcard (Admin only)
     */
    @DeleteMapping("/admin/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, String>> deleteFlashcard(@PathVariable Long id) {
        try {
            boolean deleted = flashcardService.deleteFlashcard(id);
            if (deleted) {
                return ResponseEntity.ok(Map.of("message", "Flashcard đã được xóa thành công"));
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * Lấy thống kê flashcards (Admin only)
     */
    @GetMapping("/admin/stats")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getFlashcardStats() {
        try {
            Map<String, Object> stats = flashcardService.getFlashcardStats();
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }
}