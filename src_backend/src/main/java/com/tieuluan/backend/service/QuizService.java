package com.tieuluan.backend.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tieuluan.backend.dto.QuizDTO;
import com.tieuluan.backend.dto.QuizDTO.*;
import com.tieuluan.backend.model.Flashcard;
import com.tieuluan.backend.model.QuizResult;
import com.tieuluan.backend.model.User;
import com.tieuluan.backend.model.Category;
import com.tieuluan.backend.model.StudyProgress;
import com.tieuluan.backend.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.Period;
import java.time.temporal.WeekFields;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 🎯 QuizService - Service chính cho chức năng Quiz/Test
 *
 * Features:
 * - Tự động điều chỉnh độ khó theo tuổi user
 * - Sinh câu hỏi đa dạng: trắc nghiệm, điền khuyết, nghe, đọc, viết
 * - Theo dõi tiến trình và cập nhật study progress
 * - Thống kê kết quả theo kỹ năng
 */
@Service
public class QuizService {

    @Autowired
    private QuizResultRepository quizResultRepository;

    @Autowired
    private FlashcardRepository flashcardRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private CategoryRepository categoryRepository;

    @Autowired
    private StudyProgressRepository studyProgressRepository;

    @Autowired
    private ObjectMapper objectMapper;

    private final Random random = new Random();

    // ===== CONSTANTS =====

    private static final int DEFAULT_QUESTIONS = 10;
    private static final int MIN_QUESTIONS = 5;
    private static final int MAX_QUESTIONS = 50;
    private static final int DEFAULT_TIME_LIMIT = 0; // Không giới hạn

    // ===== GENERATE QUIZ =====

    /**
     * 🎲 Sinh quiz mới cho user
     */
    public QuizResponse generateQuiz(Integer userId, GenerateQuizRequest request) {
        // 1. Lấy thông tin user và tính tuổi
        User user = userRepository.findById(userId.longValue())
                .orElseThrow(() -> new RuntimeException("User không tồn tại"));

        int userAge = calculateAge(user.getDob());
        UserAgeGroup ageGroup = UserAgeGroup.fromAge(userAge);

        // 2. Xác định độ khó
        QuizResult.DifficultyLevel difficulty = request.getDifficulty();
        if (difficulty == null || difficulty == QuizResult.DifficultyLevel.AUTO) {
            difficulty = getDifficultyByAge(userAge);
        }

        // 3. Lấy thông tin category
        Category category = categoryRepository.findById(Long.valueOf(request.getCategoryId()))
                .orElseThrow(() -> new RuntimeException("Category không tồn tại"));

        // 4. Lấy flashcards của category
        List<Flashcard> allFlashcards = flashcardRepository.findByCategoryId(request.getCategoryId().longValue());
        if (allFlashcards.isEmpty()) {
            throw new RuntimeException("Category chưa có flashcard nào");
        }

        // 5. Số câu hỏi
        int numQuestions = request.getNumberOfQuestions() != null
                ? Math.min(Math.max(request.getNumberOfQuestions(), MIN_QUESTIONS),
                Math.min(MAX_QUESTIONS, allFlashcards.size()))
                : Math.min(DEFAULT_QUESTIONS, allFlashcards.size());

        // 6. Chọn ngẫu nhiên flashcards
        Collections.shuffle(allFlashcards);
        List<Flashcard> selectedFlashcards = allFlashcards.subList(0, numQuestions);

        // 7. Sinh câu hỏi theo loại và độ khó
        QuizResult.QuizType quizType = request.getQuizType() != null
                ? request.getQuizType()
                : QuizResult.QuizType.MIXED;

        List<QuizQuestionDTO> questions = generateQuestions(
                selectedFlashcards,
                allFlashcards,
                quizType,
                difficulty,
                ageGroup,
                request.getSkillFocus(),
                request.getIncludeImages()
        );

        // 8. Build response
        return QuizResponse.builder()
                .categoryId(request.getCategoryId())
                .categoryName(category.getName())
                .quizType(quizType)
                .difficulty(difficulty)
                .totalQuestions(questions.size())
                .timeLimitSeconds(request.getTimeLimitSeconds() != null
                        ? request.getTimeLimitSeconds() : DEFAULT_TIME_LIMIT)
                .questions(questions)
                .userAgeGroup(ageGroup)
                .build();
    }

    /**
     * 📝 Sinh danh sách câu hỏi
     */
    private List<QuizQuestionDTO> generateQuestions(
            List<Flashcard> selectedFlashcards,
            List<Flashcard> allFlashcards,
            QuizResult.QuizType quizType,
            QuizResult.DifficultyLevel difficulty,
            UserAgeGroup ageGroup,
            List<String> skillFocus,
            Boolean includeImages) {

        List<QuizQuestionDTO> questions = new ArrayList<>();

        // Xác định các loại câu hỏi sẽ dùng
        List<String> questionTypes = getQuestionTypesForDifficulty(quizType, difficulty, ageGroup);

        // Xác định các kỹ năng focus
        List<String> skills = skillFocus != null && !skillFocus.isEmpty()
                ? skillFocus
                : Arrays.asList("LISTENING", "READING", "WRITING");

        for (int i = 0; i < selectedFlashcards.size(); i++) {
            Flashcard flashcard = selectedFlashcards.get(i);

            // Chọn loại câu hỏi ngẫu nhiên
            String qType = questionTypes.get(random.nextInt(questionTypes.size()));

            // Chọn kỹ năng ngẫu nhiên
            String skill = skills.get(random.nextInt(skills.size()));

            // Sinh câu hỏi theo loại
            QuizQuestionDTO question = generateSingleQuestion(
                    i, flashcard, allFlashcards, qType, skill, difficulty, ageGroup, includeImages
            );

            questions.add(question);
        }

        return questions;
    }

    /**
     * 🎯 Sinh một câu hỏi đơn
     */
    private QuizQuestionDTO generateSingleQuestion(
            int index,
            Flashcard flashcard,
            List<Flashcard> allFlashcards,
            String questionType,
            String skillType,
            QuizResult.DifficultyLevel difficulty,
            UserAgeGroup ageGroup,
            Boolean includeImages) {

        QuizQuestionDTO.QuizQuestionDTOBuilder builder = QuizQuestionDTO.builder()
                .index(index)
                .flashcardId(flashcard.getId().intValue())
                .questionType(questionType)
                .skillType(skillType)
                .word(flashcard.getWord())
                .meaning(flashcard.getMeaning())
                .phonetic(flashcard.getPhonetic())
                .points(getPointsForDifficulty(difficulty));

        // Thêm hình ảnh nếu có và được cho phép
        if (Boolean.TRUE.equals(includeImages) && flashcard.getImageUrl() != null) {
            builder.imageUrl(flashcard.getImageUrl());
        }

        // Thêm audio nếu là câu nghe
        if ("LISTENING".equals(skillType) && flashcard.getTtsUrl() != null) {
            builder.audioUrl(flashcard.getTtsUrl());
        }

        // Sinh nội dung câu hỏi theo loại
        switch (questionType) {
            case "MULTIPLE_CHOICE_EN_VI":
                return buildMultipleChoiceEnVi(builder, flashcard, allFlashcards, ageGroup);

            case "MULTIPLE_CHOICE_VI_EN":
                return buildMultipleChoiceViEn(builder, flashcard, allFlashcards, ageGroup);

            case "FILL_BLANK":
                return buildFillBlank(builder, flashcard, difficulty);

            case "LISTENING_CHOICE":
                return buildListeningChoice(builder, flashcard, allFlashcards);

            case "LISTENING_WRITE":
                return buildListeningWrite(builder, flashcard);

            case "IMAGE_WORD":
                return buildImageWord(builder, flashcard, allFlashcards);

            case "TRUE_FALSE":
                return buildTrueFalse(builder, flashcard, allFlashcards);

            case "TYPING":
                return buildTyping(builder, flashcard, difficulty);

            case "ARRANGE_LETTERS":
                return buildArrangeLetters(builder, flashcard);

            default:
                return buildMultipleChoiceEnVi(builder, flashcard, allFlashcards, ageGroup);
        }
    }

    // ===== CÁC LOẠI CÂU HỎI =====

    /**
     * Trắc nghiệm: Tiếng Anh -> Tiếng Việt
     */
    private QuizQuestionDTO buildMultipleChoiceEnVi(
            QuizQuestionDTO.QuizQuestionDTOBuilder builder,
            Flashcard flashcard,
            List<Flashcard> allFlashcards,
            UserAgeGroup ageGroup) {

        String question = ageGroup == UserAgeGroup.KIDS
                ? "\"" + flashcard.getWord() + "\" nghĩa là gì? 🤔"
                : "Từ \"" + flashcard.getWord() + "\" có nghĩa là:";

        List<String> options = generateOptions(flashcard.getMeaning(),
                allFlashcards.stream().map(Flashcard::getMeaning).collect(Collectors.toList()), 4);

        return builder
                .question(question)
                .options(options)
                .correctAnswer(flashcard.getMeaning())
                .hint(flashcard.getPartOfSpeechVi())
                .build();
    }

    /**
     * Trắc nghiệm: Tiếng Việt -> Tiếng Anh
     */
    private QuizQuestionDTO buildMultipleChoiceViEn(
            QuizQuestionDTO.QuizQuestionDTOBuilder builder,
            Flashcard flashcard,
            List<Flashcard> allFlashcards,
            UserAgeGroup ageGroup) {

        String question = ageGroup == UserAgeGroup.KIDS
                ? "\"" + flashcard.getMeaning() + "\" trong tiếng Anh là gì? 🇬🇧"
                : "\"" + flashcard.getMeaning() + "\" dịch sang tiếng Anh là:";

        List<String> options = generateOptions(flashcard.getWord(),
                allFlashcards.stream().map(Flashcard::getWord).collect(Collectors.toList()), 4);

        return builder
                .question(question)
                .options(options)
                .correctAnswer(flashcard.getWord())
                .hint(flashcard.getPhonetic())
                .build();
    }

    /**
     * Điền khuyết
     */
    private QuizQuestionDTO buildFillBlank(
            QuizQuestionDTO.QuizQuestionDTOBuilder builder,
            Flashcard flashcard,
            QuizResult.DifficultyLevel difficulty) {

        String word = flashcard.getWord();
        String blankedWord = createBlankedWord(word, difficulty);

        String question = "Điền vào chỗ trống: " + blankedWord + "\n(Nghĩa: " + flashcard.getMeaning() + ")";

        return builder
                .question(question)
                .correctAnswer(word.toLowerCase())
                .hint("Từ có " + word.length() + " chữ cái")
                .build();
    }

    /**
     * Nghe và chọn đáp án
     */
    private QuizQuestionDTO buildListeningChoice(
            QuizQuestionDTO.QuizQuestionDTOBuilder builder,
            Flashcard flashcard,
            List<Flashcard> allFlashcards) {

        List<String> options = generateOptions(flashcard.getWord(),
                allFlashcards.stream().map(Flashcard::getWord).collect(Collectors.toList()), 4);

        return builder
                .question("🎧 Nghe và chọn từ đúng:")
                .audioUrl(flashcard.getTtsUrl())
                .options(options)
                .correctAnswer(flashcard.getWord())
                .build();
    }

    /**
     * Nghe và viết
     */
    private QuizQuestionDTO buildListeningWrite(
            QuizQuestionDTO.QuizQuestionDTOBuilder builder,
            Flashcard flashcard) {

        return builder
                .question("🎧 Nghe và viết lại từ bạn nghe được:")
                .audioUrl(flashcard.getTtsUrl())
                .correctAnswer(flashcard.getWord().toLowerCase())
                .hint("Từ có " + flashcard.getWord().length() + " chữ cái")
                .build();
    }

    /**
     * Nhìn hình đoán từ
     */
    private QuizQuestionDTO buildImageWord(
            QuizQuestionDTO.QuizQuestionDTOBuilder builder,
            Flashcard flashcard,
            List<Flashcard> allFlashcards) {

        List<String> options = generateOptions(flashcard.getWord(),
                allFlashcards.stream().map(Flashcard::getWord).collect(Collectors.toList()), 4);

        return builder
                .question("🖼️ Nhìn hình và chọn từ đúng:")
                .imageUrl(flashcard.getImageUrl())
                .options(options)
                .correctAnswer(flashcard.getWord())
                .build();
    }

    /**
     * Câu hỏi Đúng/Sai
     */
    private QuizQuestionDTO buildTrueFalse(
            QuizQuestionDTO.QuizQuestionDTOBuilder builder,
            Flashcard flashcard,
            List<Flashcard> allFlashcards) {

        boolean isTrue = random.nextBoolean();
        String shownMeaning;

        if (isTrue) {
            shownMeaning = flashcard.getMeaning();
        } else {
            // Lấy nghĩa sai từ flashcard khác
            List<Flashcard> others = allFlashcards.stream()
                    .filter(f -> !f.getId().equals(flashcard.getId()))
                    .collect(Collectors.toList());
            if (!others.isEmpty()) {
                shownMeaning = others.get(random.nextInt(others.size())).getMeaning();
            } else {
                shownMeaning = flashcard.getMeaning();
                isTrue = true;
            }
        }

        String question = "\"" + flashcard.getWord() + "\" có nghĩa là \"" + shownMeaning + "\".\nĐúng hay Sai?";

        return builder
                .question(question)
                .options(Arrays.asList("Đúng ✓", "Sai ✗"))
                .correctAnswer(isTrue ? "Đúng ✓" : "Sai ✗")
                .build();
    }

    /**
     * Viết từ (typing)
     */
    private QuizQuestionDTO buildTyping(
            QuizQuestionDTO.QuizQuestionDTOBuilder builder,
            Flashcard flashcard,
            QuizResult.DifficultyLevel difficulty) {

        String question = "✍️ Viết từ tiếng Anh có nghĩa: \"" + flashcard.getMeaning() + "\"";

        String hint = difficulty == QuizResult.DifficultyLevel.KIDS
                ? "Chữ cái đầu: " + flashcard.getWord().substring(0, 1).toUpperCase()
                : "Từ có " + flashcard.getWord().length() + " chữ cái";

        return builder
                .question(question)
                .correctAnswer(flashcard.getWord().toLowerCase())
                .hint(hint)
                .build();
    }

    /**
     * Sắp xếp chữ cái
     */
    private QuizQuestionDTO buildArrangeLetters(
            QuizQuestionDTO.QuizQuestionDTOBuilder builder,
            Flashcard flashcard) {

        String word = flashcard.getWord();
        List<Character> letters = new ArrayList<>();
        for (char c : word.toCharArray()) {
            letters.add(c);
        }
        Collections.shuffle(letters);
        String scrambled = letters.stream()
                .map(String::valueOf)
                .collect(Collectors.joining(" "));

        String question = "🔤 Sắp xếp các chữ cái thành từ đúng:\n" + scrambled.toUpperCase() +
                "\n(Nghĩa: " + flashcard.getMeaning() + ")";

        return builder
                .question(question)
                .correctAnswer(word.toLowerCase())
                .hint("Từ bắt đầu bằng chữ: " + word.substring(0, 1).toUpperCase())
                .build();
    }

    // ===== SUBMIT & CALCULATE RESULTS =====

    /**
     * 📊 Submit quiz và tính kết quả
     */
    @Transactional
    public QuizResultResponse submitQuiz(Integer userId, SubmitQuizRequest request) {
        // 1. Tính điểm
        int correct = 0, wrong = 0, skipped = 0;
        int listeningCorrect = 0, listeningTotal = 0;
        int readingCorrect = 0, readingTotal = 0;
        int writingCorrect = 0, writingTotal = 0;

        List<QuestionResultDTO> questionResults = new ArrayList<>();

        for (QuestionAnswerDTO answer : request.getAnswers()) {
            boolean isCorrect = checkAnswer(answer.getUserAnswer(), answer.getCorrectAnswer());
            answer.setIsCorrect(isCorrect);

            if (answer.getUserAnswer() == null || answer.getUserAnswer().trim().isEmpty()) {
                skipped++;
            } else if (isCorrect) {
                correct++;
            } else {
                wrong++;
            }

            // Phân loại theo kỹ năng
            String skill = answer.getSkillType();
            if ("LISTENING".equals(skill)) {
                listeningTotal++;
                if (isCorrect) listeningCorrect++;
            } else if ("READING".equals(skill)) {
                readingTotal++;
                if (isCorrect) readingCorrect++;
            } else if ("WRITING".equals(skill)) {
                writingTotal++;
                if (isCorrect) writingCorrect++;
            }

            // Update study progress
            if (answer.getFlashcardId() != null) {
                updateStudyProgress(userId, answer.getFlashcardId(), request.getCategoryId(), isCorrect);
            }

            // Add to results
            questionResults.add(QuestionResultDTO.builder()
                    .index(answer.getQuestionIndex())
                    .flashcardId(answer.getFlashcardId())
                    .questionType(answer.getQuestionType())
                    .skillType(answer.getSkillType())
                    .userAnswer(answer.getUserAnswer())
                    .correctAnswer(answer.getCorrectAnswer())
                    .isCorrect(isCorrect)
                    .timeSpent(answer.getTimeSpentSeconds())
                    .build());
        }

        // 2. Tính điểm phần trăm
        int total = request.getAnswers().size();
        double score = total > 0 ? (double) correct * 100 / total : 0;

        // 3. Tính điểm theo kỹ năng
        Double listeningScore = listeningTotal > 0 ? (double) listeningCorrect * 100 / listeningTotal : null;
        Double readingScore = readingTotal > 0 ? (double) readingCorrect * 100 / readingTotal : null;
        Double writingScore = writingTotal > 0 ? (double) writingCorrect * 100 / writingTotal : null;

        // 4. Lưu kết quả
        QuizResult result = QuizResult.builder()
                .userId(userId)
                .categoryId(request.getCategoryId())
                .quizType(request.getQuizType())
                .difficultyLevel(request.getDifficulty())
                .totalQuestions(total)
                .correctAnswers(correct)
                .wrongAnswers(wrong)
                .skippedQuestions(skipped)
                .score(score)
                .timeSpentSeconds(request.getTotalTimeSeconds())
                .listeningScore(listeningScore)
                .readingScore(readingScore)
                .writingScore(writingScore)
                .completedAt(LocalDateTime.now())
                .build();

        // Lưu chi tiết dưới dạng JSON
        try {
            result.setDetailsJson(objectMapper.writeValueAsString(questionResults));
        } catch (JsonProcessingException e) {
            // Ignore
        }

        QuizResult savedResult = quizResultRepository.save(result);

        // 5. Lấy điểm lần trước để so sánh
        Double previousScore = null;
        Double improvement = null;

        List<QuizResult> previousResults = quizResultRepository
                .findByUserIdAndCategoryIdOrderByCompletedAtDesc(userId, request.getCategoryId());
        if (previousResults.size() > 1) {
            previousScore = previousResults.get(1).getScore();
            improvement = score - previousScore;
        }

        // 6. Sinh đề xuất
        List<String> recommendations = generateRecommendations(score, listeningScore, readingScore, writingScore);

        // 7. Lấy tên category
        String categoryName = categoryRepository.findById(Long.valueOf(request.getCategoryId()))
                .map(Category::getName).orElse("");

        // 8. Build response
        return QuizResultResponse.builder()
                .resultId(savedResult.getId())
                .categoryId(request.getCategoryId())
                .categoryName(categoryName)
                .quizType(request.getQuizType())
                .difficulty(request.getDifficulty())
                .totalQuestions(total)
                .correctAnswers(correct)
                .wrongAnswers(wrong)
                .skippedQuestions(skipped)
                .score(Math.round(score * 10.0) / 10.0)
                .totalTimeSeconds(request.getTotalTimeSeconds())
                .passed(score >= 60)
                .grade(savedResult.getGrade())
                .skillScores(SkillScoreDTO.builder()
                        .listeningScore(listeningScore)
                        .listeningCorrect(listeningCorrect)
                        .listeningTotal(listeningTotal)
                        .readingScore(readingScore)
                        .readingCorrect(readingCorrect)
                        .readingTotal(readingTotal)
                        .writingScore(writingScore)
                        .writingCorrect(writingCorrect)
                        .writingTotal(writingTotal)
                        .build())
                .questionResults(questionResults)
                .previousScore(previousScore)
                .improvement(improvement)
                .recommendations(recommendations)
                .completedAt(savedResult.getCompletedAt())
                .build();
    }

    // ===== STATISTICS =====

    /**
     * 📈 Lấy thống kê quiz của user
     */
    public UserQuizStatsDTO getUserQuizStats(Integer userId) {
        Integer totalQuizzes = quizResultRepository.countByUserId(userId);
        Integer totalQuestions = quizResultRepository.getTotalQuestions(userId);
        Integer totalCorrect = quizResultRepository.getTotalCorrectAnswers(userId);
        Double averageScore = quizResultRepository.getAverageScoreByUser(userId);
        Integer passedQuizzes = quizResultRepository.countPassedQuizzes(userId);

        // Điểm theo kỹ năng
        Double avgListening = quizResultRepository.getAverageListeningScore(userId);
        Double avgReading = quizResultRepository.getAverageReadingScore(userId);
        Double avgWriting = quizResultRepository.getAverageWritingScore(userId);

        // Theo thời gian
        Integer quizzesToday = quizResultRepository.countQuizzesToday(userId, LocalDateTime.now());
        LocalDateTime startOfWeek = LocalDateTime.now().with(WeekFields.ISO.dayOfWeek(), 1).toLocalDate().atStartOfDay();
        Integer quizzesThisWeek = quizResultRepository.countQuizzesThisWeek(userId, startOfWeek);

        // Lịch sử gần nhất
        List<QuizResult> recentResults = quizResultRepository.findTop10ByUserIdOrderByCompletedAtDesc(userId);
        List<QuizHistoryItemDTO> history = recentResults.stream()
                .map(r -> QuizHistoryItemDTO.builder()
                        .resultId(r.getId())
                        .categoryId(r.getCategoryId())
                        .categoryName(getCategoryName(r.getCategoryId()))
                        .quizType(r.getQuizType())
                        .score(r.getScore())
                        .correctAnswers(r.getCorrectAnswers())
                        .totalQuestions(r.getTotalQuestions())
                        .passed(r.isPassed())
                        .grade(r.getGrade())
                        .completedAt(r.getCompletedAt())
                        .build())
                .collect(Collectors.toList());

        double accuracy = totalQuestions != null && totalQuestions > 0
                ? (double) totalCorrect * 100 / totalQuestions : 0;

        return UserQuizStatsDTO.builder()
                .userId(userId)
                .totalQuizzes(totalQuizzes != null ? totalQuizzes : 0)
                .totalQuestions(totalQuestions != null ? totalQuestions : 0)
                .totalCorrect(totalCorrect != null ? totalCorrect : 0)
                .overallAccuracy(Math.round(accuracy * 10.0) / 10.0)
                .averageScore(averageScore != null ? Math.round(averageScore * 10.0) / 10.0 : 0.0)
                .passedQuizzes(passedQuizzes != null ? passedQuizzes : 0)
                .failedQuizzes((totalQuizzes != null ? totalQuizzes : 0) - (passedQuizzes != null ? passedQuizzes : 0))
                .avgListeningScore(avgListening)
                .avgReadingScore(avgReading)
                .avgWritingScore(avgWriting)
                .quizzesToday(quizzesToday != null ? quizzesToday : 0)
                .quizzesThisWeek(quizzesThisWeek != null ? quizzesThisWeek : 0)
                .recentHistory(history)
                .build();
    }

    /**
     * 📊 Lấy thống kê quiz cho category
     */
    public CategoryQuizStatsDTO getCategoryQuizStats(Integer userId, Integer categoryId) {
        List<QuizResult> results = quizResultRepository
                .findByUserIdAndCategoryIdOrderByCompletedAtDesc(userId, categoryId);

        if (results.isEmpty()) {
            return CategoryQuizStatsDTO.builder()
                    .categoryId(categoryId)
                    .categoryName(getCategoryName(categoryId))
                    .totalAttempts(0)
                    .build();
        }

        double avgScore = results.stream()
                .mapToDouble(QuizResult::getScore)
                .average()
                .orElse(0);

        double maxScore = results.stream()
                .mapToDouble(QuizResult::getScore)
                .max()
                .orElse(0);

        long passCount = results.stream()
                .filter(QuizResult::isPassed)
                .count();

        // Skill averages
        double avgListening = results.stream()
                .filter(r -> r.getListeningScore() != null)
                .mapToDouble(QuizResult::getListeningScore)
                .average().orElse(0);
        double avgReading = results.stream()
                .filter(r -> r.getReadingScore() != null)
                .mapToDouble(QuizResult::getReadingScore)
                .average().orElse(0);
        double avgWriting = results.stream()
                .filter(r -> r.getWritingScore() != null)
                .mapToDouble(QuizResult::getWritingScore)
                .average().orElse(0);

        return CategoryQuizStatsDTO.builder()
                .categoryId(categoryId)
                .categoryName(getCategoryName(categoryId))
                .totalAttempts(results.size())
                .averageScore(Math.round(avgScore * 10.0) / 10.0)
                .highestScore(Math.round(maxScore * 10.0) / 10.0)
                .latestScore(results.get(0).getScore())
                .passCount((int) passCount)
                .passRate(Math.round((double) passCount * 100 / results.size() * 10.0) / 10.0)
                .lastAttemptAt(results.get(0).getCompletedAt())
                .averageSkillScores(SkillScoreDTO.builder()
                        .listeningScore(avgListening > 0 ? avgListening : null)
                        .readingScore(avgReading > 0 ? avgReading : null)
                        .writingScore(avgWriting > 0 ? avgWriting : null)
                        .build())
                .build();
    }

    /**
     * 📜 Lấy lịch sử quiz của user
     */
    public List<QuizHistoryItemDTO> getQuizHistory(Integer userId, Integer limit) {
        List<QuizResult> results;
        if (limit != null && limit > 0) {
            results = quizResultRepository.findTop10ByUserIdOrderByCompletedAtDesc(userId);
        } else {
            results = quizResultRepository.findByUserIdOrderByCompletedAtDesc(userId);
        }

        return results.stream()
                .map(r -> QuizHistoryItemDTO.builder()
                        .resultId(r.getId())
                        .categoryId(r.getCategoryId())
                        .categoryName(getCategoryName(r.getCategoryId()))
                        .quizType(r.getQuizType())
                        .score(r.getScore())
                        .correctAnswers(r.getCorrectAnswers())
                        .totalQuestions(r.getTotalQuestions())
                        .passed(r.isPassed())
                        .grade(r.getGrade())
                        .completedAt(r.getCompletedAt())
                        .build())
                .collect(Collectors.toList());
    }

    // ===== HELPER METHODS =====

    /**
     * Tính tuổi từ ngày sinh
     */
    private int calculateAge(LocalDate dob) {
        if (dob == null) return 18; // Mặc định adult
        return Period.between(dob, LocalDate.now()).getYears();
    }

    /**
     * Xác định độ khó theo tuổi
     */
    private QuizResult.DifficultyLevel getDifficultyByAge(int age) {
        if (age < 12) return QuizResult.DifficultyLevel.KIDS;
        if (age < 18) return QuizResult.DifficultyLevel.TEEN;
        return QuizResult.DifficultyLevel.ADULT;
    }

    /**
     * Lấy các loại câu hỏi phù hợp với độ khó
     */
    private List<String> getQuestionTypesForDifficulty(
            QuizResult.QuizType quizType,
            QuizResult.DifficultyLevel difficulty,
            UserAgeGroup ageGroup) {

        if (quizType != QuizResult.QuizType.MIXED) {
            // Nếu chọn loại cụ thể, chỉ dùng loại đó
            return switch (quizType) {
                case MULTIPLE_CHOICE -> Arrays.asList("MULTIPLE_CHOICE_EN_VI", "MULTIPLE_CHOICE_VI_EN");
                case FILL_BLANK -> Arrays.asList("FILL_BLANK");
                case LISTENING -> Arrays.asList("LISTENING_CHOICE", "LISTENING_WRITE");
                case WRITING -> Arrays.asList("TYPING", "FILL_BLANK");
                case IMAGE_WORD -> Arrays.asList("IMAGE_WORD");
                case TRUE_FALSE -> Arrays.asList("TRUE_FALSE");
                case MATCHING -> Arrays.asList("MULTIPLE_CHOICE_EN_VI", "MULTIPLE_CHOICE_VI_EN");
                default -> getDefaultQuestionTypes(difficulty);
            };
        }

        return getDefaultQuestionTypes(difficulty);
    }

    /**
     * Lấy loại câu hỏi mặc định theo độ khó
     */
    private List<String> getDefaultQuestionTypes(QuizResult.DifficultyLevel difficulty) {
        return switch (difficulty) {
            case KIDS -> Arrays.asList(
                    "MULTIPLE_CHOICE_EN_VI",
                    "MULTIPLE_CHOICE_VI_EN",
                    "IMAGE_WORD",
                    "TRUE_FALSE",
                    "ARRANGE_LETTERS"
            );
            case TEEN -> Arrays.asList(
                    "MULTIPLE_CHOICE_EN_VI",
                    "MULTIPLE_CHOICE_VI_EN",
                    "FILL_BLANK",
                    "LISTENING_CHOICE",
                    "TRUE_FALSE",
                    "TYPING"
            );
            case ADULT -> Arrays.asList(
                    "MULTIPLE_CHOICE_EN_VI",
                    "MULTIPLE_CHOICE_VI_EN",
                    "FILL_BLANK",
                    "LISTENING_CHOICE",
                    "LISTENING_WRITE",
                    "TYPING"
            );
            default -> Arrays.asList("MULTIPLE_CHOICE_EN_VI", "MULTIPLE_CHOICE_VI_EN");
        };
    }

    /**
     * Điểm theo độ khó
     */
    private int getPointsForDifficulty(QuizResult.DifficultyLevel difficulty) {
        return switch (difficulty) {
            case KIDS -> 10;
            case TEEN -> 15;
            case ADULT -> 20;
            default -> 10;
        };
    }

    /**
     * Sinh các đáp án (1 đúng + N-1 sai)
     */
    private List<String> generateOptions(String correctAnswer, List<String> pool, int count) {
        Set<String> options = new LinkedHashSet<>();
        options.add(correctAnswer);

        List<String> shuffledPool = new ArrayList<>(pool);
        Collections.shuffle(shuffledPool);

        for (String option : shuffledPool) {
            if (!option.equals(correctAnswer)) {
                options.add(option);
            }
            if (options.size() >= count) break;
        }

        // Nếu không đủ options, thêm placeholder
        while (options.size() < count) {
            options.add("Đáp án " + options.size());
        }

        List<String> result = new ArrayList<>(options);
        Collections.shuffle(result);
        return result;
    }

    /**
     * Tạo từ bị che (fill blank)
     */
    private String createBlankedWord(String word, QuizResult.DifficultyLevel difficulty) {
        if (word.length() <= 2) return "_ ".repeat(word.length()).trim();

        int hideCount;
        switch (difficulty) {
            case KIDS:
                hideCount = word.length() / 3; // Che ít
                break;
            case TEEN:
                hideCount = word.length() / 2; // Che nửa
                break;
            default:
                hideCount = (int) (word.length() * 0.7); // Che nhiều
        }

        char[] chars = word.toCharArray();
        Set<Integer> hideIndices = new HashSet<>();

        while (hideIndices.size() < hideCount) {
            hideIndices.add(random.nextInt(word.length()));
        }

        StringBuilder result = new StringBuilder();
        for (int i = 0; i < chars.length; i++) {
            if (hideIndices.contains(i)) {
                result.append("_");
            } else {
                result.append(chars[i]);
            }
        }

        return result.toString();
    }

    /**
     * Kiểm tra đáp án
     */
    private boolean checkAnswer(String userAnswer, String correctAnswer) {
        if (userAnswer == null || correctAnswer == null) return false;
        return userAnswer.trim().toLowerCase().equals(correctAnswer.trim().toLowerCase());
    }

    /**
     * Cập nhật study progress
     */
    private void updateStudyProgress(Integer userId, Integer flashcardId, Integer categoryId, boolean isCorrect) {
        try {
            Optional<StudyProgress> existingProgress =
                    studyProgressRepository.findByUserIdAndFlashcardId(userId, flashcardId);

            StudyProgress progress;
            if (existingProgress.isPresent()) {
                progress = existingProgress.get();
            } else {
                progress = new StudyProgress(userId, flashcardId, categoryId);
            }

            if (isCorrect) {
                progress.recordCorrect();
            } else {
                progress.recordIncorrect();
            }

            studyProgressRepository.save(progress);
        } catch (Exception e) {
            // Log error but don't fail the quiz
        }
    }

    /**
     * Sinh đề xuất dựa trên kết quả
     */
    private List<String> generateRecommendations(Double score, Double listening, Double reading, Double writing) {
        List<String> recommendations = new ArrayList<>();

        if (score < 60) {
            recommendations.add("📚 Hãy ôn tập lại các từ vựng trong chủ đề này");
            recommendations.add("🔄 Làm thêm bài quiz để cải thiện");
        } else if (score < 80) {
            recommendations.add("👍 Khá tốt! Tiếp tục luyện tập để đạt điểm cao hơn");
        } else {
            recommendations.add("🎉 Xuất sắc! Bạn đã nắm vững chủ đề này");
        }

        // Đề xuất theo kỹ năng
        if (listening != null && listening < 60) {
            recommendations.add("🎧 Cần luyện nghe nhiều hơn");
        }
        if (reading != null && reading < 60) {
            recommendations.add("📖 Cần đọc và nhận diện từ nhiều hơn");
        }
        if (writing != null && writing < 60) {
            recommendations.add("✍️ Cần luyện viết và đánh vần từ");
        }

        return recommendations;
    }

    /**
     * Lấy tên category
     */
    private String getCategoryName(Integer categoryId) {
        return categoryRepository.findById(Long.valueOf(categoryId))
                .map(Category::getName)
                .orElse("Unknown");
    }
}