//
//  HomeViewModel.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
class HomeViewModel {
    var todayProgress: DailyProgress?
    var userStats: UserStats?
    var userSettings: UserSettings?
    var wordsDueForReview: Int = 0
    var progressPercentage: Double = 0.0
    var studiedDates: [Date] = []

    // Milestone celebration
    var showMilestoneCelebration: Bool = false
    var currentMilestone: Int = 0

    private static let milestones = [7, 30, 100, 365]
    private static let celebratedMilestonesKey = "celebratedMilestones"

    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadData()
    }

    func loadData() {
        loadTodayProgress()
        loadUserStats()
        loadUserSettings()
        calculateWordsDue()
        calculateProgress()
        loadStudiedDates()
        checkForMilestone()
    }

    private func loadTodayProgress() {
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyProgress>(
            predicate: #Predicate { $0.date == today }
        )

        do {
            let results = try modelContext.fetch(descriptor)
            todayProgress = results.first

            // Create today's progress if it doesn't exist
            if todayProgress == nil {
                let newProgress = DailyProgress(
                    date: today,
                    wordsLearned: 0,
                    wordsReviewed: 0,
                    totalStudyTime: 0,
                    sessionsCompleted: 0,
                    accuracy: 0.0
                )
                modelContext.insert(newProgress)
                try? modelContext.save()
                todayProgress = newProgress
            }
        } catch {
            AppLogger.logError("Failed to load today's progress", error: error, category: AppLogger.data)
        }
    }

    private func loadUserStats() {
        let descriptor = FetchDescriptor<UserStats>()

        do {
            let results = try modelContext.fetch(descriptor)
            userStats = results.first

            // Create user stats if they don't exist
            if userStats == nil {
                let newStats = UserStats(
                    currentStreak: 0,
                    longestStreak: 0,
                    lastStudyDate: nil,
                    totalWordsLearned: 0,
                    totalStudyTime: 0,
                    unlockedAchievements: []
                )
                modelContext.insert(newStats)
                try? modelContext.save()
                userStats = newStats
            }
        } catch {
            AppLogger.logError("Failed to load user stats", error: error, category: AppLogger.data)
        }
    }

    private func loadUserSettings() {
        let descriptor = FetchDescriptor<UserSettings>()

        do {
            let results = try modelContext.fetch(descriptor)
            userSettings = results.first

            // Create user settings if they don't exist
            if userSettings == nil {
                let newSettings = UserSettings()
                modelContext.insert(newSettings)
                try? modelContext.save()
                userSettings = newSettings
            }
        } catch {
            AppLogger.logError("Failed to load user settings", error: error, category: AppLogger.data)
        }
    }

    private func calculateWordsDue() {
        let today = Date()
        let descriptor = FetchDescriptor<Word>(
            predicate: #Predicate { word in
                word.nextReviewDate != nil && word.nextReviewDate! <= today
            }
        )

        do {
            let results = try modelContext.fetch(descriptor)
            wordsDueForReview = results.count
        } catch {
            AppLogger.logError("Failed to calculate words due", error: error, category: AppLogger.data)
            wordsDueForReview = 0
        }
    }

    private func calculateProgress() {
        guard let todayProgress = todayProgress,
              let dailyGoal = userSettings?.dailyGoal,
              dailyGoal > 0 else {
            progressPercentage = 0.0
            return
        }

        let totalStudied = todayProgress.wordsLearned + todayProgress.wordsReviewed
        progressPercentage = min(Double(totalStudied) / Double(dailyGoal), 1.0)
    }

    private func loadStudiedDates() {
        // Get dates from the last 7 days where study activity occurred
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: Date())) ?? Date()

        let descriptor = FetchDescriptor<DailyProgress>(
            predicate: #Predicate { progress in
                progress.date >= sevenDaysAgo && (progress.wordsLearned > 0 || progress.wordsReviewed > 0)
            }
        )

        do {
            let results = try modelContext.fetch(descriptor)
            studiedDates = results.map { $0.date }
        } catch {
            AppLogger.logError("Failed to load studied dates", error: error, category: AppLogger.data)
            studiedDates = []
        }
    }

    func refresh() {
        loadData()
    }

    // MARK: - Milestone Detection

    private func checkForMilestone() {
        guard let currentStreak = userStats?.currentStreak, currentStreak > 0 else { return }

        // Get previously celebrated milestones
        let celebratedMilestones = UserDefaults.standard.array(forKey: Self.celebratedMilestonesKey) as? [Int] ?? []

        // Check if current streak matches a milestone that hasn't been celebrated
        for milestone in Self.milestones {
            if currentStreak == milestone && !celebratedMilestones.contains(milestone) {
                currentMilestone = milestone
                showMilestoneCelebration = true
                markMilestoneAsCelebrated(milestone)
                break
            }
        }
    }

    private func markMilestoneAsCelebrated(_ milestone: Int) {
        var celebratedMilestones = UserDefaults.standard.array(forKey: Self.celebratedMilestonesKey) as? [Int] ?? []
        celebratedMilestones.append(milestone)
        UserDefaults.standard.set(celebratedMilestones, forKey: Self.celebratedMilestonesKey)
    }

    func dismissMilestoneCelebration() {
        showMilestoneCelebration = false
    }
}
