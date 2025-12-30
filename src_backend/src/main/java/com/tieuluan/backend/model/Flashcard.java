package com.tieuluan.backend.model;

import jakarta.persistence.*;
import lombok.*;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonIgnore;

import java.time.LocalDateTime;

/**
 * Flashcard Entity
 *
 * Schema:
 * - id: Primary key
 * - userId: Người tạo flashcard
 * - word: Từ vựng (thay vì term)
 * - partOfSpeech: Loại từ tiếng Anh (noun, verb, adj...)
 * - partOfSpeechVi: Loại từ tiếng Việt (danh từ, động từ...)
 * - phonetic: Phiên âm IPA
 * - imageUrl: URL hình ảnh
 * - meaning: Nghĩa tiếng Việt
 * - categoryId: ID category
 * - ttsUrl: URL file audio TTS
 * - createdAt: Thời gian tạo
 */
@Entity
@Table(name = "flashcards")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class Flashcard {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // ✅ Quan hệ với User (người tạo flashcard)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "\"userId\"", referencedColumnName = "id")
    @JsonIgnore
    private User user;

    @Column(name = "word", nullable = false)
    private String word;

    @Column(name = "\"partOfSpeech\"")
    private String partOfSpeech;

    @Column(name = "\"partOfSpeechVi\"")
    private String partOfSpeechVi;

    @Column(name = "phonetic")
    private String phonetic;

    @Column(name = "\"imageUrl\"")
    private String imageUrl;

    @Column(name = "meaning", nullable = false, columnDefinition = "TEXT")
    private String meaning;

    // ✅ Quan hệ với Category
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "\"categoryId\"", referencedColumnName = "id")
    @JsonIgnore
    private Category category;

    @Column(name = "\"ttsUrl\"")
    private String ttsUrl;

    @Column(name = "\"createdAt\"")
    private LocalDateTime createdAt;

    // ============ Transient Getters cho JSON ============

    @Transient
    public Long getUserId() {
        return user != null ? user.getId() : null;
    }

    @Transient
    public Long getCategoryId() {
        return category != null ? category.getId() : null;
    }

    // ============ PrePersist ============

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
    }

    // ============ Constructors ============

    public Flashcard(String word, String meaning) {
        this.word = word;
        this.meaning = meaning;
    }

    public Flashcard(String word, String partOfSpeech, String partOfSpeechVi,
                     String phonetic, String imageUrl, String meaning,
                     Category category, User user, String ttsUrl) {
        this.word = word;
        this.partOfSpeech = partOfSpeech;
        this.partOfSpeechVi = partOfSpeechVi;
        this.phonetic = phonetic;
        this.imageUrl = imageUrl;
        this.meaning = meaning;
        this.category = category;
        this.user = user;
        this.ttsUrl = ttsUrl;
    }

    @Override
    public String toString() {
        return "Flashcard{" +
                "id=" + id +
                ", userId=" + getUserId() +
                ", word='" + word + '\'' +
                ", partOfSpeech='" + partOfSpeech + '\'' +
                ", partOfSpeechVi='" + partOfSpeechVi + '\'' +
                ", phonetic='" + phonetic + '\'' +
                ", meaning='" + meaning + '\'' +
                ", categoryId=" + getCategoryId() +
                ", createdAt=" + createdAt +
                '}';
    }
}