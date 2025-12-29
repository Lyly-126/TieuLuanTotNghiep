package com.tieuluan.backend.service;

import com.tieuluan.backend.model.Dictionary;
import com.tieuluan.backend.repository.DictionaryRepository;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Service tra cứu từ điển offline
 * Thay thế việc gọi Gemini AI cho định nghĩa từ
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DictionaryService {

    private final DictionaryRepository dictionaryRepository;

    /**
     * Tra cứu từ vựng - trả về đầy đủ thông tin
     */
    public DictionaryLookupResult lookup(String word) {
        log.info("📖 Looking up word: '{}'", word);

        if (word == null || word.trim().isEmpty()) {
            return DictionaryLookupResult.notFound(word, "Từ không được để trống");
        }

        String cleanWord = word.trim().toLowerCase();

        Optional<Dictionary> dictOpt = dictionaryRepository.findByWordIgnoreCase(cleanWord);

        if (dictOpt.isPresent()) {
            Dictionary dict = dictOpt.get();
            log.info("✅ Found word '{}' in dictionary", cleanWord);

            return DictionaryLookupResult.builder()
                    .found(true)
                    .word(dict.getWord())
                    .partOfSpeech(dict.getPartOfSpeech())
                    .partOfSpeechVi(dict.getPartOfSpeechVi())
                    .phonetic(dict.getPhonetic())
                    .definitions(dict.getDefinitions())
                    .meanings(dict.getMeanings())
                    .source(dict.getSource())
                    .build();
        } else {
            log.warn("⚠️ Word '{}' not found in dictionary", cleanWord);
            return DictionaryLookupResult.notFound(cleanWord, "Từ không có trong từ điển");
        }
    }

    /**
     * Gợi ý từ khi người dùng đang gõ (autocomplete)
     */
    public List<String> suggest(String prefix) {
        if (prefix == null || prefix.trim().length() < 2) {
            return List.of();
        }

        String cleanPrefix = prefix.trim().toLowerCase();
        log.info("🔍 Suggesting words starting with: '{}'", cleanPrefix);

        List<Dictionary> results = dictionaryRepository.findByWordStartingWith(cleanPrefix);

        return results.stream()
                .map(Dictionary::getWord)
                .collect(Collectors.toList());
    }

    /**
     * Tìm kiếm từ chứa keyword
     */
    public List<DictionaryLookupResult> search(String keyword) {
        if (keyword == null || keyword.trim().length() < 2) {
            return List.of();
        }

        String cleanKeyword = keyword.trim().toLowerCase();
        log.info("🔎 Searching words containing: '{}'", cleanKeyword);

        List<Dictionary> results = dictionaryRepository.findByWordContaining(cleanKeyword);

        return results.stream()
                .map(dict -> DictionaryLookupResult.builder()
                        .found(true)
                        .word(dict.getWord())
                        .partOfSpeech(dict.getPartOfSpeech())
                        .partOfSpeechVi(dict.getPartOfSpeechVi())
                        .phonetic(dict.getPhonetic())
                        .definitions(dict.getDefinitions())
                        .meanings(dict.getMeanings())
                        .source(dict.getSource())
                        .build())
                .collect(Collectors.toList());
    }

    /**
     * Kiểm tra từ có tồn tại trong từ điển không
     */
    public boolean exists(String word) {
        if (word == null || word.trim().isEmpty()) {
            return false;
        }
        return dictionaryRepository.existsByWord(word.trim());
    }

    /**
     * Lấy thống kê từ điển
     */
    public DictionaryStats getStats() {
        long totalWords = dictionaryRepository.countAll();
        return new DictionaryStats(totalWords);
    }

    // ================== DTOs ==================

    @Data
    @lombok.Builder
    public static class DictionaryLookupResult {
        private boolean found;
        private String word;
        private String partOfSpeech;      // noun, verb, adjective...
        private String partOfSpeechVi;    // danh từ, động từ...
        private String phonetic;          // /ˈbæŋk/
        private String definitions;       // English definition
        private String meanings;          // Vietnamese meaning
        private String source;            // vi+en, en, vi
        private String errorMessage;

        public static DictionaryLookupResult notFound(String word, String message) {
            return DictionaryLookupResult.builder()
                    .found(false)
                    .word(word)
                    .errorMessage(message)
                    .build();
        }
    }

    @Data
    @lombok.AllArgsConstructor
    public static class DictionaryStats {
        private long totalWords;
    }
}