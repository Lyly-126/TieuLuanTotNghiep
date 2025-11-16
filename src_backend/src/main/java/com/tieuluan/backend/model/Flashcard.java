package com.tieuluan.backend.model;

import jakarta.persistence.*;
import lombok.*;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@Entity
@Table(name = "flashcards")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Flashcard {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "term", nullable = false)
    private String term;

    @Column(name = "partOfSpeech")
    private String partOfSpeech;

    @Column(name = "phonetic")
    private String phonetic;

    @Column(name = "imageUrl")
    private String imageUrl;

    @Column(name = "meaning", nullable = false, columnDefinition = "TEXT")
    private String meaning;

    // Quan hệ với Category
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "categoryId", referencedColumnName = "id")
    @JsonIgnoreProperties({"flashcards"}) // Tránh vòng lặp JSON khi chuyển dữ liệu giữa backend và frontend
    private Category category;

    @Column(name = "ttsUrl")
    private String ttsUrl;

    // Transient field để Flutter dễ parse
    @Transient
    public Long getCategoryId() {
        return category != null ? category.getId() : null;
    }

    // Constructor với các field bắt buộc
    public Flashcard(String term, String meaning) {
        this.term = term;
        this.meaning = meaning;
    }

    // Constructor đầy đủ (không có ID)
    public Flashcard(String term, String partOfSpeech, String phonetic,
                     String imageUrl, String meaning, Category category, String ttsUrl) {
        this.term = term;
        this.partOfSpeech = partOfSpeech;
        this.phonetic = phonetic;
        this.imageUrl = imageUrl;
        this.meaning = meaning;
        this.category = category;
        this.ttsUrl = ttsUrl;
    }

    @Override
    public String toString() {
        return "Flashcard{" +
                "id=" + id +
                ", term='" + term + '\'' +
                ", partOfSpeech='" + partOfSpeech + '\'' +
                ", phonetic='" + phonetic + '\'' +
                ", imageUrl='" + imageUrl + '\'' +
                ", meaning='" + meaning + '\'' +
                ", categoryId=" + (category != null ? category.getId() : null) +
                ", ttsUrl='" + ttsUrl + '\'' +
                '}';
    }
}
