package com.tieuluan.backend.service;

import com.tieuluan.backend.model.Flashcard;
import com.tieuluan.backend.repository.FlashcardRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Transactional
public class FlashcardService {

    private final FlashcardRepository flashcardRepository;

    // ==================== READ OPERATIONS ====================

    /**
     * Lấy tất cả flashcards
     */
    public List<Flashcard> getAllFlashcards() {
        return flashcardRepository.findAll();
    }

    /**
     * Lấy flashcard theo ID
     */
    public Flashcard getFlashcardById(Long id) {
        Optional<Flashcard> flashcard = flashcardRepository.findById(id);
        return flashcard.orElse(null);
    }

    /**
     * Lấy flashcards theo category ID
     */
    public List<Flashcard> getFlashcardsByCategory(Long categoryId) {
        return flashcardRepository.findByCategoryId(categoryId);
    }

    /**
     * Lấy flashcards ngẫu nhiên
     */
    public List<Flashcard> getRandomFlashcards(int limit) {
        return flashcardRepository.findRandomByCategoryId(null, limit);
    }

    /**
     * Tìm kiếm flashcards theo từ khóa
     */
    public List<Flashcard> searchFlashcards(String keyword) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return getAllFlashcards();
        }
        return flashcardRepository.searchByKeyword(keyword.trim());
    }

    // ==================== WRITE OPERATIONS ====================

    /**
     * Tạo flashcard mới
     */
    public Flashcard createFlashcard(Flashcard flashcard) {
        // ✅ Validate - dùng getWord() thay vì getTerm()
        if (flashcard.getWord() == null || flashcard.getWord().trim().isEmpty()) {
            throw new IllegalArgumentException("Word không được để trống");
        }
        if (flashcard.getMeaning() == null || flashcard.getMeaning().trim().isEmpty()) {
            throw new IllegalArgumentException("Meaning không được để trống");
        }

        // Trim whitespace
        flashcard.setWord(flashcard.getWord().trim());
        flashcard.setMeaning(flashcard.getMeaning().trim());

        if (flashcard.getPartOfSpeech() != null) {
            flashcard.setPartOfSpeech(flashcard.getPartOfSpeech().trim());
        }
        if (flashcard.getPartOfSpeechVi() != null) {
            flashcard.setPartOfSpeechVi(flashcard.getPartOfSpeechVi().trim());
        }
        if (flashcard.getPhonetic() != null) {
            flashcard.setPhonetic(flashcard.getPhonetic().trim());
        }

        return flashcardRepository.save(flashcard);
    }

    /**
     * Cập nhật flashcard
     */
    public Flashcard updateFlashcard(Flashcard flashcard) {
        if (flashcard.getId() == null) {
            throw new IllegalArgumentException("ID không được để trống khi cập nhật");
        }

        if (!flashcardRepository.existsById(flashcard.getId())) {
            throw new IllegalArgumentException("Flashcard không tồn tại");
        }

        // ✅ Validate - dùng getWord() thay vì getTerm()
        if (flashcard.getWord() == null || flashcard.getWord().trim().isEmpty()) {
            throw new IllegalArgumentException("Word không được để trống");
        }
        if (flashcard.getMeaning() == null || flashcard.getMeaning().trim().isEmpty()) {
            throw new IllegalArgumentException("Meaning không được để trống");
        }

        // Trim whitespace
        flashcard.setWord(flashcard.getWord().trim());
        flashcard.setMeaning(flashcard.getMeaning().trim());

        if (flashcard.getPartOfSpeech() != null) {
            flashcard.setPartOfSpeech(flashcard.getPartOfSpeech().trim());
        }
        if (flashcard.getPartOfSpeechVi() != null) {
            flashcard.setPartOfSpeechVi(flashcard.getPartOfSpeechVi().trim());
        }
        if (flashcard.getPhonetic() != null) {
            flashcard.setPhonetic(flashcard.getPhonetic().trim());
        }

        return flashcardRepository.save(flashcard);
    }

    /**
     * Xóa flashcard
     */
    public boolean deleteFlashcard(Long id) {
        if (!flashcardRepository.existsById(id)) {
            return false;
        }
        flashcardRepository.deleteById(id);
        return true;
    }

    // ==================== STATISTICS ====================

    /**
     * Lấy thống kê flashcards
     */
    public Map<String, Object> getFlashcardStats() {
        Map<String, Object> stats = new HashMap<>();

        // Tổng số flashcards
        long totalFlashcards = flashcardRepository.count();
        stats.put("totalFlashcards", totalFlashcards);

        return stats;
    }

    /**
     * Kiểm tra flashcard có tồn tại không
     */
    public boolean existsById(Long id) {
        return flashcardRepository.existsById(id);
    }

    /**
     * Đếm tổng số flashcards
     */
    public long getTotalCount() {
        return flashcardRepository.count();
    }
}