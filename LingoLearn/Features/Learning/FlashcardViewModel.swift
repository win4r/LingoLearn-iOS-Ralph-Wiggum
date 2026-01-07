//
//  FlashcardViewModel.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import Foundation
import SwiftData
import SwiftUI

enum LearningMode {
    case learning  // New words
    case review    // Words due for review
}

// Stores the previous state of a word before it was updated
private struct WordStateSnapshot {
    let wordId: UUID
    let easeFactor: Double
    let interval: Int
    let repetitions: Int
    let nextReviewDate: Date?
    let timesStudied: Int
    let timesCorrect: Int
    let lastStudiedDate: Date?
    let masteryLevel: MasteryLevel
    let direction: SwipeDirection
}

@Observable
class FlashcardViewModel {
    var currentWords: [Word] = []
    var currentIndex: Int = 0
    var sessionStats = SessionStats()
    var showSummary = false
    var newlyUnlockedAchievements: [Achievement] = []
    var dailyGoalJustReached = false
    var isLoading = true
    var errorMessage: String?
    var showMasteryCelebration = false
    var masteredWordEnglish: String = ""

    private var modelContext: ModelContext
    private let mode: LearningMode
    private let categoryFilter: WordCategory?
    private var sessionStartTime: Date = Date()
    private var history: [WordStateSnapshot] = []

    var canGoBack: Bool {
        currentIndex > 0 && !history.isEmpty
    }

    var currentWord: Word? {
        guard currentIndex < currentWords.count else { return nil }
        return currentWords[currentIndex]
    }

    var hasMoreCards: Bool {
        currentIndex < currentWords.count
    }

    init(modelContext: ModelContext, mode: LearningMode, categoryFilter: WordCategory? = nil) {
        self.modelContext = modelContext
        self.mode = mode
        self.categoryFilter = categoryFilter
        self.sessionStartTime = Date()
        loadWords()
    }

    private func loadWords() {
        isLoading = true
        errorMessage = nil
        do {
            switch mode {
            case .learning:
                // Learning mode: Optimized with two targeted queries
                let minTimes = AppConstants.Learning.minTimesStudiedForLearning
                let sessionLimit = AppConstants.Learning.cardsPerSession

                // Query 1: Words that haven't been studied enough times
                var newWordsDescriptor = FetchDescriptor<Word>(
                    predicate: #Predicate { word in
                        word.timesStudied < minTimes
                    },
                    sortBy: [SortDescriptor(\.lastStudiedDate, order: .forward)]
                )
                newWordsDescriptor.fetchLimit = sessionLimit

                let newWords = try modelContext.fetch(newWordsDescriptor)

                // Query 2: Words with low mastery
                // SwiftData predicates don't support enum rawValue access, so fetch and filter in memory
                var lowMasteryDescriptor = FetchDescriptor<Word>(
                    predicate: #Predicate { word in
                        word.timesStudied >= minTimes
                    },
                    sortBy: [SortDescriptor(\.lastStudiedDate, order: .forward)]
                )

                let potentialLowMastery = try modelContext.fetch(lowMasteryDescriptor)
                let lowMasteryWords = potentialLowMastery.filter {
                    $0.masteryLevel == .new || $0.masteryLevel == .learning
                }.prefix(sessionLimit)

                // Combine and sort, keeping only what we need
                var combinedWords = (newWords + Array(lowMasteryWords))
                    .sorted { ($0.lastStudiedDate ?? .distantPast) < ($1.lastStudiedDate ?? .distantPast) }

                // Apply category filter if specified
                if let category = categoryFilter {
                    combinedWords = combinedWords.filter { $0.category == category }
                }

                currentWords = Array(combinedWords.prefix(sessionLimit))

            case .review:
                // Review mode: Use predicate for date comparison (already optimized)
                let today = Date()
                var descriptor = FetchDescriptor<Word>(
                    predicate: #Predicate { word in
                        word.nextReviewDate != nil && word.nextReviewDate! <= today
                    },
                    sortBy: [SortDescriptor(\.nextReviewDate, order: .forward)]
                )
                descriptor.fetchLimit = AppConstants.Learning.cardsPerSession * 2 // Fetch more to filter
                var reviewWords = try modelContext.fetch(descriptor)

                // Apply category filter if specified
                if let category = categoryFilter {
                    reviewWords = reviewWords.filter { $0.category == category }
                }

                currentWords = Array(reviewWords.prefix(AppConstants.Learning.cardsPerSession))
            }

            AppLogger.logDebug("Loaded \(currentWords.count) words for \(mode) mode", category: AppLogger.learning)
            isLoading = false
        } catch {
            AppLogger.logError("Failed to load words", error: error, category: AppLogger.learning)
            errorMessage = "加载单词失败，请稍后重试"
            isLoading = false
        }
    }

    func handleSwipe(direction: SwipeDirection) {
        guard let word = currentWord else { return }

        // Save state before making changes (for undo)
        let snapshot = WordStateSnapshot(
            wordId: word.id,
            easeFactor: word.easeFactor,
            interval: word.interval,
            repetitions: word.repetitions,
            nextReviewDate: word.nextReviewDate,
            timesStudied: word.timesStudied,
            timesCorrect: word.timesCorrect,
            lastStudiedDate: word.lastStudiedDate,
            masteryLevel: word.masteryLevel,
            direction: direction
        )

        switch direction {
        case .right: // Know it (good recall)
            handleKnownWord(word, quality: AppConstants.SM2.knownQuality)
            sessionStats.knownCount += 1
            history.append(snapshot)
            SoundService.shared.playSwipeRight()
        case .down: // Easy (perfect/instant recall)
            handleKnownWord(word, quality: AppConstants.SM2.easyQuality)
            sessionStats.knownCount += 1
            history.append(snapshot)
            SoundService.shared.playSuccess()
        case .left: // Don't know
            handleUnknownWord(word)
            sessionStats.unknownCount += 1
            history.append(snapshot)
            SoundService.shared.playSwipeLeft()
        case .up: // Favorite
            toggleFavorite(word)
            SoundService.shared.playTap()
            return // Don't advance card for favorite
        }

        sessionStats.totalReviewed += 1
        moveToNextCard()
    }

    func goToPreviousCard() {
        guard canGoBack, let snapshot = history.popLast() else { return }

        // Find the word and restore its state
        if let word = currentWords.first(where: { $0.id == snapshot.wordId }) {
            word.easeFactor = snapshot.easeFactor
            word.interval = snapshot.interval
            word.repetitions = snapshot.repetitions
            word.nextReviewDate = snapshot.nextReviewDate
            word.timesStudied = snapshot.timesStudied
            word.timesCorrect = snapshot.timesCorrect
            word.lastStudiedDate = snapshot.lastStudiedDate
            word.masteryLevel = snapshot.masteryLevel

            // Undo session stats based on what direction was used
            switch snapshot.direction {
            case .right, .down:
                sessionStats.knownCount -= 1
            case .left:
                sessionStats.unknownCount -= 1
            case .up:
                break // Favorite doesn't affect stats
            }
            sessionStats.totalReviewed -= 1

            saveWord(word)
        }

        // Go back one card
        currentIndex -= 1
    }

    private func handleKnownWord(_ word: Word, quality: Int) {
        // Update SM-2 parameters
        let result = SM2Service.shared.calculateNextReview(
            currentEF: word.easeFactor,
            currentInterval: word.interval,
            currentReps: word.repetitions,
            quality: quality
        )

        word.easeFactor = result.easeFactor
        word.interval = result.interval
        word.repetitions = result.repetitions
        word.nextReviewDate = result.nextReviewDate

        // Update study statistics
        word.timesStudied += 1
        word.timesCorrect += 1
        word.lastStudiedDate = Date()

        // Update mastery level
        updateMasteryLevel(word)

        saveWord(word)
    }

    private func handleUnknownWord(_ word: Word) {
        // Reset SM-2 parameters for incorrect answer
        let result = SM2Service.shared.calculateNextReview(
            currentEF: word.easeFactor,
            currentInterval: word.interval,
            currentReps: word.repetitions,
            quality: AppConstants.SM2.unknownQuality
        )

        word.easeFactor = result.easeFactor
        word.interval = result.interval
        word.repetitions = result.repetitions
        word.nextReviewDate = result.nextReviewDate

        // Update study statistics
        word.timesStudied += 1
        word.lastStudiedDate = Date()

        saveWord(word)
    }

    private func toggleFavorite(_ word: Word) {
        word.isFavorite.toggle()
        saveWord(word)
    }

    private func updateMasteryLevel(_ word: Word) {
        let previousLevel = word.masteryLevel
        let accuracy = Double(word.timesCorrect) / Double(max(word.timesStudied, 1))

        if word.timesStudied >= AppConstants.Learning.timesStudiedForMastered && accuracy >= AppConstants.Learning.accuracyForMastered {
            word.masteryLevel = .mastered
        } else if word.timesStudied >= AppConstants.Learning.timesStudiedForReviewing && accuracy >= AppConstants.Learning.accuracyForReviewing {
            word.masteryLevel = .reviewing
        } else if word.timesStudied > 0 {
            word.masteryLevel = .learning
        } else {
            word.masteryLevel = .new
        }

        // Trigger celebration if word just became mastered
        if previousLevel != .mastered && word.masteryLevel == .mastered {
            masteredWordEnglish = word.english
            showMasteryCelebration = true
        }
    }

    private func saveWord(_ word: Word) {
        do {
            try modelContext.save()
        } catch {
            AppLogger.logError("Failed to save word", error: error, category: AppLogger.data)
        }
    }

    private func moveToNextCard() {
        currentIndex += 1

        if !hasMoreCards {
            // Session complete
            let sessionDuration = Date().timeIntervalSince(sessionStartTime)
            sessionStats.duration = sessionDuration
            updateDailyProgress(sessionDuration: sessionDuration)
            updateUserStats(sessionDuration: sessionDuration)
            recordStudySession(duration: sessionDuration)
            checkAchievements()
            SoundService.shared.playComplete()
            showSummary = true
        }
    }

    private func recordStudySession(duration: TimeInterval) {
        let sessionType: SessionType = mode == .learning ? .learning : .review
        let session = StudySession(
            sessionType: sessionType,
            wordsStudied: sessionStats.totalReviewed,
            wordsCorrect: sessionStats.knownCount,
            wordsIncorrect: sessionStats.unknownCount,
            duration: duration,
            completed: true
        )
        modelContext.insert(session)
        do {
            try modelContext.save()
        } catch {
            AppLogger.logError("Failed to record study session", error: error, category: AppLogger.data)
        }
    }

    private func updateDailyProgress(sessionDuration: TimeInterval) {
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyProgress>(
            predicate: #Predicate { $0.date == today }
        )

        do {
            let results = try modelContext.fetch(descriptor)
            let progress = results.first ?? {
                let newProgress = DailyProgress(
                    date: today,
                    wordsLearned: 0,
                    wordsReviewed: 0,
                    totalStudyTime: 0,
                    sessionsCompleted: 0,
                    accuracy: 0.0
                )
                modelContext.insert(newProgress)
                return newProgress
            }()

            // Get daily goal for comparison
            let settingsDescriptor = FetchDescriptor<UserSettings>()
            let dailyGoal = (try? modelContext.fetch(settingsDescriptor).first?.dailyGoal) ?? 20

            // Check if goal was not yet reached before this session
            let previousTotal = progress.wordsLearned + progress.wordsReviewed
            let wasUnderGoal = previousTotal < dailyGoal

            if mode == .learning {
                progress.wordsLearned += sessionStats.totalReviewed
            } else {
                progress.wordsReviewed += sessionStats.totalReviewed
            }

            // Check if goal was just reached
            let newTotal = progress.wordsLearned + progress.wordsReviewed
            if wasUnderGoal && newTotal >= dailyGoal {
                dailyGoalJustReached = true
            }

            progress.sessionsCompleted += 1
            progress.totalStudyTime += sessionDuration

            // Update accuracy (weighted average for multiple sessions)
            if sessionStats.totalReviewed > 0 {
                let previousWordsTotal = progress.wordsLearned + progress.wordsReviewed - sessionStats.totalReviewed
                if previousWordsTotal > 0 {
                    // Weighted average of previous accuracy and current session accuracy
                    let currentAccuracyPercent = sessionStats.accuracy * 100
                    let totalWords = previousWordsTotal + sessionStats.totalReviewed
                    progress.accuracy = (progress.accuracy * Double(previousWordsTotal) + currentAccuracyPercent * Double(sessionStats.totalReviewed)) / Double(totalWords)
                } else {
                    progress.accuracy = sessionStats.accuracy * 100
                }
            }

            try modelContext.save()
        } catch {
            AppLogger.logError("Failed to update daily progress", error: error, category: AppLogger.data)
        }
    }

    private func updateUserStats(sessionDuration: TimeInterval) {
        let descriptor = FetchDescriptor<UserStats>()

        do {
            let results = try modelContext.fetch(descriptor)
            guard let stats = results.first else { return }

            // Update total words learned
            stats.totalWordsLearned += sessionStats.knownCount

            // Update total study time
            stats.totalStudyTime += sessionDuration

            // Update streak
            let today = Calendar.current.startOfDay(for: Date())
            if let lastStudy = stats.lastStudyDate {
                let lastStudyDay = Calendar.current.startOfDay(for: lastStudy)
                let daysDifference = Calendar.current.dateComponents([.day], from: lastStudyDay, to: today).day ?? 0

                if daysDifference == 0 {
                    // Same day, no change to streak (already counted for today)
                } else if daysDifference == 1 {
                    // Consecutive day - increment streak
                    stats.currentStreak += 1
                    stats.longestStreak = max(stats.longestStreak, stats.currentStreak)
                } else {
                    // Streak broken (missed one or more days)
                    stats.currentStreak = 1
                }
            } else {
                // First study ever
                stats.currentStreak = 1
                stats.longestStreak = 1
            }

            stats.lastStudyDate = Date()

            try modelContext.save()
        } catch {
            AppLogger.logError("Failed to update user stats", error: error, category: AppLogger.data)
        }
    }

    private func checkAchievements() {
        let descriptor = FetchDescriptor<UserStats>()

        do {
            let results = try modelContext.fetch(descriptor)
            guard let stats = results.first else { return }

            // Check general achievements (streak, total words, etc.)
            var unlocked = AchievementService.shared.checkAndUnlock(stats: stats, modelContext: modelContext)

            // Check session-specific achievements (perfect score, time of day)
            let isPerfect = sessionStats.totalReviewed > 0 && sessionStats.unknownCount == 0
            let sessionAchievements = AchievementService.shared.checkSessionAchievements(
                isPerfect: isPerfect,
                studyTime: Date(),
                stats: stats,
                modelContext: modelContext
            )
            unlocked.append(contentsOf: sessionAchievements)

            newlyUnlockedAchievements = unlocked
        } catch {
            AppLogger.logError("Failed to check achievements", error: error, category: AppLogger.achievements)
        }
    }

    func reset() {
        currentIndex = 0
        sessionStats = SessionStats()
        showSummary = false
        newlyUnlockedAchievements = []
        dailyGoalJustReached = false
        history = []
        sessionStartTime = Date()
        loadWords()
    }
}

enum SwipeDirection {
    case left   // Don't know (quality 0)
    case right  // Know (quality 4)
    case up     // Favorite toggle (no quality change)
    case down   // Easy/Perfect recall (quality 5)
}

struct SessionStats {
    var totalReviewed: Int = 0
    var knownCount: Int = 0
    var unknownCount: Int = 0
    var duration: TimeInterval = 0

    var accuracy: Double {
        guard totalReviewed > 0 else { return 0 }
        return Double(knownCount) / Double(totalReviewed)
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)分\(seconds)秒"
        } else {
            return "\(seconds)秒"
        }
    }

    var wordsPerMinute: Double {
        guard duration > 0 else { return 0 }
        return Double(totalReviewed) / (duration / 60.0)
    }
}
