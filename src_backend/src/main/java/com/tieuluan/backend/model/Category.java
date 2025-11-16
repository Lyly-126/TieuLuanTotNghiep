package com.tieuluan.backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.util.List;

@Getter
@Setter
@AllArgsConstructor
@Entity
@Table(name = "categories")
public class Category {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "name", nullable = false, length = 100)
    private String name;

    // Quan hệ một-nhiều với Flashcard (mỗi category có thể có nhiều flashcard)
    @OneToMany(mappedBy = "category", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Flashcard> flashcards;

    // Constructors, getters, setters
    public Category() {
    }

    public Category(String name) {
        this.name = name;
    }
}
