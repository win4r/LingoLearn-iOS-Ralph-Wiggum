//
//  NotificationService.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import Foundation
import UserNotifications
import Combine

/// Notification action identifiers
enum NotificationAction: String {
    case startLearning = "START_LEARNING_ACTION"
    case quickReview = "QUICK_REVIEW_ACTION"
}

/// Notification category identifiers
enum NotificationCategory: String {
    case dailyReminder = "DAILY_REMINDER_CATEGORY"
}

class NotificationService: NSObject {
    static let shared = NotificationService()

    private let notificationIdentifier = "daily_reminder"

    /// Published action that was tapped (observed by views)
    @Published var pendingAction: NotificationAction?

    private override init() {
        super.init()
    }

    /// Setup notification categories with actions
    func setupCategories() {
        let startLearningAction = UNNotificationAction(
            identifier: NotificationAction.startLearning.rawValue,
            title: "开始学习",
            options: [.foreground]
        )

        let quickReviewAction = UNNotificationAction(
            identifier: NotificationAction.quickReview.rawValue,
            title: "快速复习",
            options: [.foreground]
        )

        let dailyReminderCategory = UNNotificationCategory(
            identifier: NotificationCategory.dailyReminder.rawValue,
            actions: [startLearningAction, quickReviewAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([dailyReminderCategory])
        UNUserNotificationCenter.current().delegate = self
    }

    /// Request notification permission from user
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            AppLogger.logError("Failed to request notification permission", error: error, category: AppLogger.notifications)
            return false
        }
    }

    /// Schedule a daily repeating notification at the specified time
    func scheduleDaily(at time: Date) async {
        // First, cancel any existing notifications
        cancelAll()

        // Extract hour and minute from the date
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "LingoLearn"
        content.body = "该学习单词了！保持每日学习习惯"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = NotificationCategory.dailyReminder.rawValue

        // Create trigger for daily repeating notification
        var dateComponents = DateComponents()
        dateComponents.hour = components.hour
        dateComponents.minute = components.minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        // Create request
        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )

        // Add notification request
        do {
            try await UNUserNotificationCenter.current().add(request)
            AppLogger.logDebug("Daily notification scheduled for \(components.hour ?? 0):\(components.minute ?? 0)", category: AppLogger.notifications)
        } catch {
            AppLogger.logError("Failed to schedule notification", error: error, category: AppLogger.notifications)
        }
    }

    /// Cancel all pending notifications
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().setBadgeCount(0)
    }

    /// Check current notification settings
    func checkSettings() async -> UNNotificationSettings {
        return await UNUserNotificationCenter.current().notificationSettings()
    }

    /// Send an immediate notification (for testing or achievement unlocks)
    func sendImmediateNotification(title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            AppLogger.logError("Failed to send immediate notification", error: error, category: AppLogger.notifications)
        }
    }

    /// Clear any pending action
    func clearPendingAction() {
        pendingAction = nil
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle notification action response
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier

        // Clear badge
        center.setBadgeCount(0)

        // Handle action based on identifier
        switch actionIdentifier {
        case NotificationAction.startLearning.rawValue:
            AppLogger.logDebug("User tapped Start Learning action", category: AppLogger.notifications)
            pendingAction = .startLearning
            HapticManager.shared.impact()

        case NotificationAction.quickReview.rawValue:
            AppLogger.logDebug("User tapped Quick Review action", category: AppLogger.notifications)
            pendingAction = .quickReview
            HapticManager.shared.impact()

        case UNNotificationDefaultActionIdentifier:
            // User tapped on notification itself (not an action button)
            AppLogger.logDebug("User tapped notification", category: AppLogger.notifications)
            pendingAction = .startLearning // Default to learning mode

        default:
            break
        }

        completionHandler()
    }
}
