package com.tieuluan.backend.controller;

import com.tieuluan.backend.service.DictionaryService;
import com.tieuluan.backend.service.DictionaryService.DictionaryLookupResult;
import com.tieuluan.backend.service.DictionaryService.DictionaryStats;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Controller cho Dictionary API
 *
 * Endpoints:
 * - GET /api/dictionary/lookup?word=hello      → Tra từ
 * - GET /api/dictionary/suggest?prefix=hel    → Gợi ý autocomplete
 * - GET /api/dictionary/search?keyword=bank   → Tìm kiếm
 * - GET /api/dictionary/exists?word=hello     → Kiểm tra tồn tại
 * - GET /api/dictionary/stats                 → Thống kê
 */
@Slf4j
@RestController
@RequestMapping("/api/dictionary")
@RequiredArgsConstructor
public class DictionaryController {

    private final DictionaryService dictionaryService;

    /**
     * Tra cứu từ - trả về đầy đủ thông tin
     * GET /api/dictionary/lookup?word=hello
     */
    @GetMapping("/lookup")
    public ResponseEntity<DictionaryLookupResult> lookup(@RequestParam String word) {
        log.info("📖 API: Lookup word '{}'", word);
        DictionaryLookupResult result = dictionaryService.lookup(word);
        return ResponseEntity.ok(result);
    }

    /**
     * Gợi ý từ khi đang gõ (autocomplete)
     * GET /api/dictionary/suggest?prefix=hel
     */
    @GetMapping("/suggest")
    public ResponseEntity<List<String>> suggest(@RequestParam String prefix) {
        log.info("🔍 API: Suggest words with prefix '{}'", prefix);
        List<String> suggestions = dictionaryService.suggest(prefix);
        return ResponseEntity.ok(suggestions);
    }

    /**
     * Tìm kiếm từ chứa keyword
     * GET /api/dictionary/search?keyword=bank
     */
    @GetMapping("/search")
    public ResponseEntity<List<DictionaryLookupResult>> search(@RequestParam String keyword) {
        log.info("🔎 API: Search words containing '{}'", keyword);
        List<DictionaryLookupResult> results = dictionaryService.search(keyword);
        return ResponseEntity.ok(results);
    }

    /**
     * Kiểm tra từ có tồn tại trong từ điển không
     * GET /api/dictionary/exists?word=hello
     */
    @GetMapping("/exists")
    public ResponseEntity<Map<String, Object>> exists(@RequestParam String word) {
        log.info("❓ API: Check if word '{}' exists", word);
        boolean exists = dictionaryService.exists(word);
        return ResponseEntity.ok(Map.of(
                "word", word,
                "exists", exists
        ));
    }

    /**
     * Lấy thống kê từ điển
     * GET /api/dictionary/stats
     */
    @GetMapping("/stats")
    public ResponseEntity<DictionaryStats> getStats() {
        log.info("📊 API: Get dictionary stats");
        DictionaryStats stats = dictionaryService.getStats();
        return ResponseEntity.ok(stats);
    }

    /**
     * Tra cứu batch nhiều từ cùng lúc
     * POST /api/dictionary/batch-lookup
     * Body: ["hello", "world", "apple"]
     */
    @PostMapping("/batch-lookup")
    public ResponseEntity<List<DictionaryLookupResult>> batchLookup(@RequestBody List<String> words) {
        log.info("📚 API: Batch lookup {} words", words.size());
        List<DictionaryLookupResult> results = words.stream()
                .map(dictionaryService::lookup)
                .toList();
        return ResponseEntity.ok(results);
    }
}