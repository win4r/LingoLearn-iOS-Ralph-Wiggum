//
//  AppLogger.swift
//  LingoLearn
//
//  Centralized logging utility using OSLog for better debugging
//

import Foundation
import OSLog

/// Centralized logging utility for the app
enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.lingolearn"

    // Category-specific loggers
    static let general = Logger(subsystem: subsystem, category: "general")
    static let learning = Logger(subsystem: subsystem, category: "learning")
    static let data = Logger(subsystem: subsystem, category: "data")
    static let notifications = Logger(subsystem: subsystem, category: "notifications")
    static let achievements = Logger(subsystem: subsystem, category: "achievements")

    /// Log an error with context
    static func logError(_ message: String, error: Error? = nil, category: Logger = general) {
        if let error = error {
            category.error("\(message): \(error.localizedDescription)")
        } else {
            category.error("\(message)")
        }
    }

    /// Log debug info (only in DEBUG builds)
    static func logDebug(_ message: String, category: Logger = general) {
        #if DEBUG
        category.debug("\(message)")
        #endif
    }

    /// Log info
    static func logInfo(_ message: String, category: Logger = general) {
        category.info("\(message)")
    }

    /// Log warning
    static func logWarning(_ message: String, category: Logger = general) {
        category.warning("\(message)")
    }
}
