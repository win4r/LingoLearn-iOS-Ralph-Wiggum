//
//  SettingsViewModel.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import Foundation
import SwiftData
import Observation
import UIKit

@Observable
class SettingsViewModel {
    private let modelContext: ModelContext
    private var settings: UserSettings?

    // Settings properties
    var dailyGoal: Int = 20 {
        didSet { saveSettings() }
    }

    var reminderEnabled: Bool = false {
        didSet { saveSettings() }
    }

    var reminderTime: Date = {
        var components = DateComponents()
        components.hour = 20
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }() {
        didSet { saveSettings() }
    }

    var soundEnabled: Bool = true {
        didSet {
            saveSettings()
            SoundService.shared.isEnabled = soundEnabled
        }
    }

    var hapticsEnabled: Bool = true {
        didSet {
            saveSettings()
            HapticManager.shared.isEnabled = hapticsEnabled
        }
    }

    var autoPlayPronunciation: Bool = true {
        didSet { saveSettings() }
    }

    var speechRate: SpeechRate = .normal {
        didSet { saveSettings() }
    }

    var appearanceMode: AppearanceMode = .system {
        didSet {
            saveSettings()
            applyAppearanceMode()
        }
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadSettings() {
        let descriptor = FetchDescriptor<UserSettings>()
        if let existingSettings = try? modelContext.fetch(descriptor).first {
            settings = existingSettings
            dailyGoal = existingSettings.dailyGoal
            reminderEnabled = existingSettings.reminderEnabled
            reminderTime = existingSettings.reminderTime
            soundEnabled = existingSettings.soundEnabled
            hapticsEnabled = existingSettings.hapticsEnabled
            autoPlayPronunciation = existingSettings.autoPlayPronunciation
            speechRate = existingSettings.speechRate
            appearanceMode = existingSettings.appearanceMode
        } else {
            // Create default settings
            let newSettings = UserSettings(
                dailyGoal: 20,
                reminderEnabled: false,
                reminderTime: reminderTime,
                soundEnabled: true,
                hapticsEnabled: true,
                autoPlayPronunciation: true,
                appearanceMode: .system
            )
            modelContext.insert(newSettings)
            settings = newSettings
            try? modelContext.save()
        }

        applyAppearanceMode()
        HapticManager.shared.isEnabled = hapticsEnabled
        SoundService.shared.isEnabled = soundEnabled
    }

    private func saveSettings() {
        guard let settings = settings else { return }

        settings.dailyGoal = dailyGoal
        settings.reminderEnabled = reminderEnabled
        settings.reminderTime = reminderTime
        settings.soundEnabled = soundEnabled
        settings.hapticsEnabled = hapticsEnabled
        settings.autoPlayPronunciation = autoPlayPronunciation
        settings.speechRate = speechRate
        settings.appearanceMode = appearanceMode

        try? modelContext.save()
    }

    func handleReminderToggle(_ enabled: Bool) async {
        if enabled {
            let granted = await NotificationService.shared.requestPermission()
            if granted {
                await scheduleReminder()
            } else {
                // Revert toggle if permission denied
                reminderEnabled = false
            }
        } else {
            NotificationService.shared.cancelAll()
        }
    }

    func scheduleReminder() async {
        guard reminderEnabled else { return }
        await NotificationService.shared.scheduleDaily(at: reminderTime)
    }

    private func applyAppearanceMode() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }

        switch appearanceMode {
        case .system:
            window.overrideUserInterfaceStyle = .unspecified
        case .light:
            window.overrideUserInterfaceStyle = .light
        case .dark:
            window.overrideUserInterfaceStyle = .dark
        }
    }

    func resetProgress() {
        // Delete all DailyProgress records
        let progressDescriptor = FetchDescriptor<DailyProgress>()
        if let progressRecords = try? modelContext.fetch(progressDescriptor) {
            for record in progressRecords {
                modelContext.delete(record)
            }
        }

        // Reset UserStats
        let statsDescriptor = FetchDescriptor<UserStats>()
        if let stats = try? modelContext.fetch(statsDescriptor).first {
            stats.currentStreak = 0
            stats.longestStreak = 0
            stats.lastStudyDate = nil
            stats.totalWordsLearned = 0
            stats.totalStudyTime = 0
            stats.unlockedAchievements = []
        }

        try? modelContext.save()
    }
}
