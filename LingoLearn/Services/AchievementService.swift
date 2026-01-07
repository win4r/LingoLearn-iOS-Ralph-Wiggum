//
//  AchievementService.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import Foundation
import SwiftData

struct Achievement: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let iconName: String

    static let all: [Achievement] = [
        Achievement(
            id: "first_word",
            title: "初次学习",
            description: "学习第一个单词",
            iconName: "star.fill"
        ),
        Achievement(
            id: "streak_7",
            title: "坚持一周",
            description: "连续学习7天",
            iconName: "flame.fill"
        ),
        Achievement(
            id: "streak_30",
            title: "月度达人",
            description: "连续学习30天",
            iconName: "flame.circle.fill"
        ),
        Achievement(
            id: "words_100",
            title: "百词斩",
            description: "掌握100个单词",
            iconName: "100.circle.fill"
        ),
        Achievement(
            id: "words_500",
            title: "词汇达人",
            description: "掌握500个单词",
            iconName: "star.circle.fill"
        ),
        Achievement(
            id: "perfect_session",
            title: "完美练习",
            description: "一次练习全部正确",
            iconName: "checkmark.seal.fill"
        ),
        Achievement(
            id: "night_owl",
            title: "夜猫子",
            description: "晚上10点后学习",
            iconName: "moon.fill"
        ),
        Achievement(
            id: "early_bird",
            title: "早起鸟",
            description: "早上6点前学习",
            iconName: "sunrise.fill"
        )
    ]

    static func byId(_ id: String) -> Achievement? {
        all.first { $0.id == id }
    }
}

class AchievementService {
    static let shared = AchievementService()

    private init() {}

    /// Check conditions and return newly unlocked achievements
    func checkAndUnlock(stats: UserStats, modelContext: ModelContext) -> [Achievement] {
        var newlyUnlocked: [Achievement] = []
        let currentUnlocked = Set(stats.unlockedAchievements)

        // Check each achievement
        for achievement in Achievement.all {
            // Skip if already unlocked
            if currentUnlocked.contains(achievement.id) {
                continue
            }

            // Check unlock conditions
            if shouldUnlock(achievement: achievement, stats: stats, modelContext: modelContext) {
                stats.unlockedAchievements.append(achievement.id)
                newlyUnlocked.append(achievement)
            }
        }

        // Save if there are new achievements
        if !newlyUnlocked.isEmpty {
            try? modelContext.save()
            SoundService.shared.playLevelUp()
        }

        return newlyUnlocked
    }

    /// Check specific achievement for a session (e.g., perfect score, time of day)
    func checkSessionAchievements(
        isPerfect: Bool,
        studyTime: Date,
        stats: UserStats,
        modelContext: ModelContext
    ) -> [Achievement] {
        var newlyUnlocked: [Achievement] = []
        let currentUnlocked = Set(stats.unlockedAchievements)

        // Perfect session
        if isPerfect && !currentUnlocked.contains("perfect_session") {
            if let achievement = Achievement.byId("perfect_session") {
                stats.unlockedAchievements.append(achievement.id)
                newlyUnlocked.append(achievement)
            }
        }

        // Time-based achievements
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: studyTime)

        // Night owl (after 10 PM)
        if hour >= 22 && !currentUnlocked.contains("night_owl") {
            if let achievement = Achievement.byId("night_owl") {
                stats.unlockedAchievements.append(achievement.id)
                newlyUnlocked.append(achievement)
            }
        }

        // Early bird (before 6 AM)
        if hour < 6 && !currentUnlocked.contains("early_bird") {
            if let achievement = Achievement.byId("early_bird") {
                stats.unlockedAchievements.append(achievement.id)
                newlyUnlocked.append(achievement)
            }
        }

        if !newlyUnlocked.isEmpty {
            try? modelContext.save()
            SoundService.shared.playLevelUp()
        }

        return newlyUnlocked
    }

    private func shouldUnlock(
        achievement: Achievement,
        stats: UserStats,
        modelContext: ModelContext
    ) -> Bool {
        switch achievement.id {
        case "first_word":
            return stats.totalWordsLearned >= 1

        case "streak_7":
            return stats.currentStreak >= 7

        case "streak_30":
            return stats.currentStreak >= 30

        case "words_100":
            return getMasteredWordCount(modelContext: modelContext) >= 100

        case "words_500":
            return getMasteredWordCount(modelContext: modelContext) >= 500

        default:
            // Session-based achievements are checked separately
            return false
        }
    }

    private func getMasteredWordCount(modelContext: ModelContext) -> Int {
        // Fetch all and filter in memory (SwiftData #Predicate doesn't support enum comparisons)
        let descriptor = FetchDescriptor<Word>()
        guard let words = try? modelContext.fetch(descriptor) else { return 0 }
        return words.filter { $0.masteryLevel == .mastered }.count
    }
}
