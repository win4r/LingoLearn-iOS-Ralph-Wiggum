//
//  AppConstants.swift
//  LingoLearn
//
//  Constants for app-wide configuration values
//

import Foundation

enum AppConstants {

    // MARK: - Learning Session
    enum Learning {
        /// Maximum number of cards per learning session
        static let cardsPerSession = 20

        /// Minimum times studied to consider a word as being actively learned
        static let minTimesStudiedForLearning = 3

        /// Times studied threshold for reviewing status
        static let timesStudiedForReviewing = 10

        /// Times studied threshold for mastered status
        static let timesStudiedForMastered = 20

        /// Accuracy threshold for reviewing status (75%)
        static let accuracyForReviewing: Double = 0.75

        /// Accuracy threshold for mastered status (90%)
        static let accuracyForMastered: Double = 0.90
    }

    // MARK: - Practice Tests
    enum Practice {
        /// Default time limit per question in seconds
        static let defaultTimeLimit: Double = 15.0

        /// Timer tick interval in seconds
        static let timerInterval: Double = 0.1

        /// Number of distractor options for multiple choice
        static let distractorCount = 3
    }

    // MARK: - Speech
    enum Speech {
        /// Speech rate for language learning (0.0 - 1.0)
        static let learningRate: Float = 0.5

        /// Default language code
        static let defaultLanguage = "en-US"
    }

    // MARK: - SM-2 Algorithm
    enum SM2 {
        /// Minimum ease factor
        static let minEaseFactor: Double = 1.3

        /// Default ease factor for new words
        static let defaultEaseFactor: Double = 2.5

        /// Quality threshold for correct answer (>= 3 is acceptable)
        static let correctThreshold = 3

        /// Quality rating for unknown word (Complete blackout - 0)
        static let unknownQuality = 0

        /// Quality rating for hard recall (Correct but with difficulty - 3)
        static let hardQuality = 3

        /// Quality rating for known word (Good recall - 4)
        static let knownQuality = 4

        /// Quality rating for easy word (Perfect/instant recall - 5)
        static let easyQuality = 5

        /// Initial interval in days for first review
        static let firstInterval = 1

        /// Interval in days after first successful review
        static let secondInterval = 6
    }

    // MARK: - User Settings
    enum Settings {
        /// Minimum daily goal
        static let minDailyGoal = 10

        /// Maximum daily goal
        static let maxDailyGoal = 100

        /// Default daily goal
        static let defaultDailyGoal = 20
    }

    // MARK: - Animation
    enum Animation {
        /// Standard spring damping for UI animations
        static let springDamping: Double = 0.7

        /// Standard animation duration
        static let standardDuration: Double = 0.3

        /// Card flip animation duration
        static let flipDuration: Double = 0.5
    }

    // MARK: - Data
    enum Data {
        /// UserDefaults key for seeding status
        static let hasSeededDataKey = "hasSeededWordData"

        /// Seconds per day (for date calculations)
        static let secondsPerDay: TimeInterval = 86400
    }

    // MARK: - Chart
    enum Chart {
        /// Default period in days for progress charts
        static let defaultPeriod = 7

        /// Extended period option in days
        static let extendedPeriod = 30
    }
}
