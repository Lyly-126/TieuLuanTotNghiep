package com.tieuluan.backend.service;

import com.tieuluan.backend.model.Flashcard;
import com.tieuluan.backend.repository.FlashcardRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
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
        PageRequest pageRequest = PageRequest.of(0, limit);
        return flashcardRepository.findRandomFlashcards(pageRequest);
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

    /**
     * Lấy flashcards theo danh sách IDs
     */
    public List<Flashcard> getFlashcardsByIds(List<Long> ids) {
        return flashcardRepository.findByIdIn(ids);
    }

    /**
     * Lấy flashcards có TTS URL
     */
    public List<Flashcard> getFlashcardsWithTtsUrl() {
        return flashcardRepository.findFlashcardsWithTtsUrl();
    }

    /**
     * Lấy flashcards theo part of speech
     */
    public List<Flashcard> getFlashcardsByPartOfSpeech(String partOfSpeech) {
        return flashcardRepository.findByPartOfSpeech(partOfSpeech);
    }

    /**
     * Lấy flashcards có hình ảnh
     */
    public List<Flashcard> getFlashcardsWithImages() {
        return flashcardRepository.findFlashcardsWithImages();
    }

    // ==================== WRITE OPERATIONS ====================

    /**
     * Tạo flashcard mới
     */
    public Flashcard createFlashcard(Flashcard flashcard) {
        // Validate dữ liệu bắt buộc
        if (flashcard.getTerm() == null || flashcard.getTerm().trim().isEmpty()) {
            throw new IllegalArgumentException("Term không được để trống");
        }
        if (flashcard.getMeaning() == null || flashcard.getMeaning().trim().isEmpty()) {
            throw new IllegalArgumentException("Meaning không được để trống");
        }

        // Trim whitespace
        flashcard.setTerm(flashcard.getTerm().trim());
        flashcard.setMeaning(flashcard.getMeaning().trim());

        if (flashcard.getPartOfSpeech() != null) {
            flashcard.setPartOfSpeech(flashcard.getPartOfSpeech().trim());
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

        // Kiểm tra flashcard có tồn tại không
        if (!flashcardRepository.existsById(flashcard.getId())) {
            throw new IllegalArgumentException("Flashcard không tồn tại");
        }

        // Validate dữ liệu bắt buộc
        if (flashcard.getTerm() == null || flashcard.getTerm().trim().isEmpty()) {
            throw new IllegalArgumentException("Term không được để trống");
        }
        if (flashcard.getMeaning() == null || flashcard.getMeaning().trim().isEmpty()) {
            throw new IllegalArgumentException("Meaning không được để trống");
        }

        // Trim whitespace
        flashcard.setTerm(flashcard.getTerm().trim());
        flashcard.setMeaning(flashcard.getMeaning().trim());

        if (flashcard.getPartOfSpeech() != null) {
            flashcard.setPartOfSpeech(flashcard.getPartOfSpeech().trim());
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

    /**
     * Xóa nhiều flashcards
     */
    public int deleteFlashcards(List<Long> ids) {
        List<Flashcard> flashcardsToDelete = flashcardRepository.findByIdIn(ids);
        flashcardRepository.deleteAll(flashcardsToDelete);
        return flashcardsToDelete.size();
    }

    // ==================== STATISTICS ====================

    /**
     * Lấy thống kê flashcards
     */
    public Map<String, Object> getFlashcardStats() {
        Map<String, Object> stats = new HashMap<>();

        // Tổng số flashcards
        Long totalFlashcards = flashcardRepository.countTotalFlashcards();
        stats.put("totalFlashcards", totalFlashcards);

        // Số flashcards có TTS URL
        Long flashcardsWithTts = (long) flashcardRepository.findFlashcardsWithTtsUrl().size();
        stats.put("flashcardsWithTts", flashcardsWithTts);

        // Số flashcards có hình ảnh
        Long flashcardsWithImages = (long) flashcardRepository.findFlashcardsWithImages().size();
        stats.put("flashcardsWithImages", flashcardsWithImages);

        // Phân bố theo category
        List<Object[]> categoryStats = flashcardRepository.countFlashcardsByCategory();
        Map<String, Long> categoryDistribution = new HashMap<>();
        for (Object[] row : categoryStats) {
            Long categoryId = (Long) row[0];
            Long count = (Long) row[1];
            categoryDistribution.put(categoryId != null ? categoryId.toString() : "uncategorized", count);
        }
        stats.put("categoryDistribution", categoryDistribution);

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