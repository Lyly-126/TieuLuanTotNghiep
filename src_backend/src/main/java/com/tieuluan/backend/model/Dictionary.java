package com.tieuluan.backend.model;

import jakarta.persistence.*;
import lombok.*;

/**
 * Dictionary Entity - Bảng từ điển offline từ Wiktionary
 * Dùng để tra cứu nhanh thay vì gọi AI
 */
@Entity
@Table(name = "dictionary")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Dictionary {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "word", unique = true)
    private String word;

    @Column(name = "part_of_speech")
    private String partOfSpeech;

    @Column(name = "part_of_speech_vi")
    private String partOfSpeechVi;

    @Column(name = "phonetic")
    private String phonetic;

    @Column(name = "definitions", columnDefinition = "TEXT")
    private String definitions;

    @Column(name = "meanings", columnDefinition = "TEXT")
    private String meanings;

    @Column(name = "source")
    private String source;

    @Override
    public String toString() {
        return "Dictionary{" +
                "id=" + id +
                ", word='" + word + '\'' +
                ", partOfSpeech='" + partOfSpeech + '\'' +
                ", phonetic='" + phonetic + '\'' +
                ", meanings='" + meanings + '\'' +
                '}';
    }
}