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
}

struct WrongAnswer {
    let word: Word
    let userAnswer: String
    let correctAnswer: String
}

@Observable
class PracticeViewModel {
    var questions: [TestQuestion] = []
    var currentQuestionIndex = 0
    var correctAnswers = 0
    var wrongAnswers: [WrongAnswer] = []
    var timeRemaining: Double = AppConstants.Practice.defaultTimeLimit
    var isTimerRunning = false
    var testCompleted = false
    var sessionStartTime: Date?
    var questionTimeLimit: Double = AppConstants.Practice.defaultTimeLimit

    private var timer: Timer?
    private var allWords: [Word] = []

    var currentQuestion: TestQuestion? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }

    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentQuestionIndex) / Double(questions.count)
    }

    var totalQuestions: Int {
        questions.count
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

        if currentQuestionIndex >= questions.count {
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
        let session = StudySession(
            sessionType: sessionType,
            wordsStudied: questions.count,
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
        currentQuestionIndex = 0
        correctAnswers = 0
        wrongAnswers = []
        timeRemaining = questionTimeLimit
        isTimerRunning = false
        testCompleted = false
        sessionStartTime = nil
        stopTimer()
    }

    deinit {
        stopTimer()
    }
}
