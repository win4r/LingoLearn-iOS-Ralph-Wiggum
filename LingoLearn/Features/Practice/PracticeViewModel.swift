//
//  PracticeViewModel.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI
import SwiftData

struct TestQuestion {
    let word: Word
    let options: [String]
    let correctAnswer: String
    let statement: String?
    let correctBoolAnswer: Bool?

    init(word: Word, options: [String], correctAnswer: String, statement: String? = nil, correctBoolAnswer: Bool? = nil) {
        self.word = word
        self.options = options
        self.correctAnswer = correctAnswer
        self.statement = statement
        self.correctBoolAnswer = correctBoolAnswer
    }
}

struct WrongAnswer {
    let word: Word
    let userAnswer: String
    let correctAnswer: String
}

struct MultiSelectQuestion {
    let word: Word
    let options: [String]
    let correctAnswers: Set<String>
}

@Observable
class PracticeViewModel {
    var questions: [TestQuestion] = []
    var multiSelectQuestions: [MultiSelectQuestion] = []
    var currentQuestionIndex = 0
    var correctAnswers = 0
    var wrongAnswers: [WrongAnswer] = []
    var timeRemaining: Double = AppConstants.Practice.defaultTimeLimit
    var isTimerRunning = false
    var testCompleted = false
    var sessionStartTime: Date?
    var questionTimeLimit: Double = AppConstants.Practice.defaultTimeLimit

    // Multi-select scoring
    var multiSelectScore: Double = 0
    var multiSelectFullCorrect = 0
    var multiSelectPartialCorrect = 0
    var multiSelectZeroScore = 0

    private var timer: Timer?
    private var allWords: [Word] = []

    var currentQuestion: TestQuestion? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }

    var currentMultiSelectQuestion: MultiSelectQuestion? {
        guard currentQuestionIndex < multiSelectQuestions.count else { return nil }
        return multiSelectQuestions[currentQuestionIndex]
    }

    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentQuestionIndex) / Double(questions.count)
    }

    var totalQuestions: Int {
        questions.isEmpty ? multiSelectQuestions.count : questions.count
    }

    var accuracy: Double {
        let total = correctAnswers + wrongAnswers.count
        guard total > 0 else { return 0 }
        return Double(correctAnswers) / Double(total) * 100
    }

    func setupTest(words: [Word], testType: SessionType, timeLimit: Double = AppConstants.Practice.defaultTimeLimit) {
        self.allWords = words
        self.questionTimeLimit = timeLimit
        self.timeRemaining = timeLimit
        self.sessionStartTime = Date()

        switch testType {
        case .multipleChoice:
            generateMultipleChoiceQuestions(from: words)
        case .fillInBlank:
            generateFillInBlankQuestions(from: words)
        case .listening:
            generateListeningQuestions(from: words)
        case .trueFalse:
            generateTrueFalseQuestions(from: words)
        case .multiSelect:
            generateMultiSelectQuestions(from: words)
        default:
            break
        }
    }

    private func generateMultipleChoiceQuestions(from words: [Word]) {
        questions = words.map { word in
            let correctAnswer = word.chinese
            var options = [correctAnswer]

            // Generate random distractors
            let otherWords = words.filter { $0.english != word.english }
            let distractors = otherWords.shuffled().prefix(AppConstants.Practice.distractorCount).map { $0.chinese }
            options.append(contentsOf: distractors)

            // Shuffle options
            options.shuffle()

            return TestQuestion(word: word, options: options, correctAnswer: correctAnswer)
        }
    }

    private func generateFillInBlankQuestions(from words: [Word]) {
        questions = words.map { word in
            TestQuestion(word: word, options: [], correctAnswer: word.english.lowercased())
        }
    }

    private func generateListeningQuestions(from words: [Word]) {
        questions = words.map { word in
            let correctAnswer = word.english
            var options = [correctAnswer]

            // Generate random distractors
            let otherWords = words.filter { $0.english != word.english }
            let distractors = otherWords.shuffled().prefix(AppConstants.Practice.distractorCount).map { $0.english }
            options.append(contentsOf: distractors)

            // Shuffle options
            options.shuffle()

            return TestQuestion(word: word, options: options, correctAnswer: correctAnswer)
        }
    }

    private func generateTrueFalseQuestions(from words: [Word]) {
        questions = words.map { word in
            let isCorrectTranslation = Bool.random()
            let statement: String
            let correctBoolAnswer: Bool

            if isCorrectTranslation {
                statement = "\(word.english) / \(word.chinese)"
                correctBoolAnswer = true
            } else {
                let wrongWord = words.filter { $0.english != word.english }.randomElement() ?? word
                statement = "\(word.english) / \(wrongWord.chinese)"
                correctBoolAnswer = false
            }

            return TestQuestion(
                word: word,
                options: ["True", "False"],
                correctAnswer: correctBoolAnswer ? "True" : "False",
                statement: statement,
                correctBoolAnswer: correctBoolAnswer
            )
        }
    }

    private func generateMultiSelectQuestions(from words: [Word]) {
        multiSelectQuestions = words.map { word in
            let correctAnswer = word.chinese
            var correctAnswers: Set<String> = [correctAnswer]

            // Add 1-2 additional "correct" answers by including synonymous translations
            // For simplicity, we'll treat the main translation as the only true correct answer
            // and simulate multiple correct by splitting if the translation contains multiple meanings
            let chineseParts = correctAnswer.components(separatedBy: CharacterSet(charactersIn: ";；,，"))
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            if chineseParts.count > 1 {
                // Word has multiple meanings, use them as separate correct answers
                correctAnswers = Set(chineseParts.prefix(3))
            }

            // Generate distractors from other words
            let otherWords = words.filter { $0.english != word.english }
            let distractorWords = otherWords.shuffled().prefix(6 - correctAnswers.count)
            let distractors = distractorWords.map { $0.chinese }

            // Combine and shuffle all options
            var allOptions = Array(correctAnswers) + distractors
            allOptions.shuffle()

            return MultiSelectQuestion(
                word: word,
                options: allOptions,
                correctAnswers: correctAnswers
            )
        }
    }

    /// Submit multi-select answer and calculate partial credit score
    /// Returns: (score, isFullyCorrect)
    func submitMultiSelectAnswer(selectedAnswers: Set<String>) -> (score: Double, isFullyCorrect: Bool) {
        stopTimer()

        guard let question = currentMultiSelectQuestion else { return (0, false) }

        let correctSelected = selectedAnswers.intersection(question.correctAnswers).count
        let incorrectSelected = selectedAnswers.subtracting(question.correctAnswers).count
        let totalCorrect = question.correctAnswers.count

        // Partial credit formula: max(0, (correctSelected - incorrectSelected)) / totalCorrect
        let rawScore = Double(correctSelected - incorrectSelected)
        let score = max(0, rawScore) / Double(totalCorrect)

        multiSelectScore += score

        let isFullyCorrect = correctSelected == totalCorrect && incorrectSelected == 0

        if isFullyCorrect {
            multiSelectFullCorrect += 1
            correctAnswers += 1
            SoundService.shared.playSuccess()
        } else if score > 0 {
            multiSelectPartialCorrect += 1
            SoundService.shared.playTap()
        } else {
            multiSelectZeroScore += 1
            wrongAnswers.append(WrongAnswer(
                word: question.word,
                userAnswer: Array(selectedAnswers).joined(separator: ", "),
                correctAnswer: Array(question.correctAnswers).joined(separator: ", ")
            ))
            SoundService.shared.playError()
        }

        return (score, isFullyCorrect)
    }

    func startTimer() {
        timeRemaining = questionTimeLimit
        isTimerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: AppConstants.Practice.timerInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.timeRemaining -= AppConstants.Practice.timerInterval
            if self.timeRemaining <= 0 {
                self.stopTimer()
                // Auto-submit wrong answer when time runs out
                self.submitAnswer("")
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
    }

    func submitAnswer(_ answer: String) {
        stopTimer()

        guard let question = currentQuestion else { return }

        let isCorrect: Bool
        if question.options.isEmpty {
            // Fill in blank - case insensitive comparison
            isCorrect = answer.lowercased().trimmingCharacters(in: .whitespaces) == question.correctAnswer
        } else {
            // Multiple choice or listening
            isCorrect = answer == question.correctAnswer
        }

        if isCorrect {
            correctAnswers += 1
            SoundService.shared.playSuccess()
        } else {
            wrongAnswers.append(WrongAnswer(
                word: question.word,
                userAnswer: answer,
                correctAnswer: question.correctAnswer
            ))
            SoundService.shared.playError()
        }
    }

    func nextQuestion() {
        currentQuestionIndex += 1

        let total = questions.isEmpty ? multiSelectQuestions.count : questions.count
        if currentQuestionIndex >= total {
            completeTest()
        } else {
            startTimer()
        }
    }

    func completeTest() {
        stopTimer()
        testCompleted = true
        SoundService.shared.playComplete()
    }

    func saveSession(modelContext: ModelContext, sessionType: SessionType) {
        guard let startTime = sessionStartTime else { return }

        let duration = Date().timeIntervalSince(startTime)
        let wordsCount = questions.isEmpty ? multiSelectQuestions.count : questions.count
        let session = StudySession(
            sessionType: sessionType,
            wordsStudied: wordsCount,
            wordsCorrect: correctAnswers,
            wordsIncorrect: wrongAnswers.count,
            duration: duration,
            completed: true
        )

        modelContext.insert(session)
        try? modelContext.save()
    }

    func reset() {
        questions = []
        multiSelectQuestions = []
        currentQuestionIndex = 0
        correctAnswers = 0
        wrongAnswers = []
        timeRemaining = questionTimeLimit
        isTimerRunning = false
        testCompleted = false
        sessionStartTime = nil
        multiSelectScore = 0
        multiSelectFullCorrect = 0
        multiSelectPartialCorrect = 0
        multiSelectZeroScore = 0
        stopTimer()
    }

    deinit {
        stopTimer()
    }
}
