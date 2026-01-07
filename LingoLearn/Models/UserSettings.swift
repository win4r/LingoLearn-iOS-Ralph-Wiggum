import Foundation
import SwiftData

enum AppearanceMode: String, Codable, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
}

enum SpeechRate: String, Codable, CaseIterable {
    case slow = "Slow"
    case normal = "Normal"
    case fast = "Fast"

    var rate: Float {
        switch self {
        case .slow: return 0.35
        case .normal: return 0.5
        case .fast: return 0.6
        }
    }

    var displayName: String {
        switch self {
        case .slow: return "慢速"
        case .normal: return "正常"
        case .fast: return "快速"
        }
    }
}

@Model
final class UserSettings {
    @Attribute(.unique) var id: UUID
    var dailyGoal: Int // 10-100, default 20
    var reminderEnabled: Bool
    var reminderTime: Date
    var soundEnabled: Bool
    var hapticsEnabled: Bool
    var autoPlayPronunciation: Bool
    var speechRate: SpeechRate
    var appearanceMode: AppearanceMode
    var questionTimeLimit: Int // seconds per question, default 15
    var hasCompletedOnboarding: Bool
    var streakFreezes: Int // Available streak freezes
    var lastStreakFreezeUsed: Date? // Last date a freeze was used

    init(dailyGoal: Int = 20, reminderEnabled: Bool = false, reminderTime: Date = Date(),
         soundEnabled: Bool = true, hapticsEnabled: Bool = true,
         autoPlayPronunciation: Bool = true, speechRate: SpeechRate = .normal,
         appearanceMode: AppearanceMode = .system,
         questionTimeLimit: Int = 15, hasCompletedOnboarding: Bool = false,
         streakFreezes: Int = 2, lastStreakFreezeUsed: Date? = nil) {
        self.id = UUID()
        self.dailyGoal = min(100, max(10, dailyGoal)) // Clamp between 10-100
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.soundEnabled = soundEnabled
        self.hapticsEnabled = hapticsEnabled
        self.autoPlayPronunciation = autoPlayPronunciation
        self.speechRate = speechRate
        self.appearanceMode = appearanceMode
        self.questionTimeLimit = questionTimeLimit
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.streakFreezes = streakFreezes
        self.lastStreakFreezeUsed = lastStreakFreezeUsed
    }
}
