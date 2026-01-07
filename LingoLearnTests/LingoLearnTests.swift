//
//  LingoLearnTests.swift
//  LingoLearnTests
//
//  Created by charles qin on 12/14/25.
//

import Foundation
import Testing
@testable import LingoLearn

// MARK: - SM-2 Algorithm Tests

struct SM2ServiceTests {
    let sm2Service = SM2Service.shared

    // MARK: - First Review Tests

    @Test func firstReviewWithGoodQuality() async throws {
        let result = sm2Service.calculateNextReview(
            currentEF: 2.5,
            currentInterval: 0,
            currentReps: 0,
            quality: 4 // Good
        )

        #expect(result.interval == 1, "First review should have 1-day interval")
        #expect(result.repetitions == 1, "Repetitions should increment to 1")
        #expect(result.easeFactor >= 1.3, "Ease factor should not go below minimum")
    }

    @Test func firstReviewWithEasyQuality() async throws {
        let result = sm2Service.calculateNextReview(
            currentEF: 2.5,
            currentInterval: 0,
            currentReps: 0,
            quality: 5 // Easy
        )

        #expect(result.interval == 1, "First review should have 1-day interval")
        #expect(result.repetitions == 1, "Repetitions should increment to 1")
        #expect(result.easeFactor > 2.5, "Easy quality should increase ease factor")
    }

    @Test func firstReviewWithPoorQuality() async throws {
        let result = sm2Service.calculateNextReview(
            currentEF: 2.5,
            currentInterval: 0,
            currentReps: 0,
            quality: 0 // Complete blackout
        )

        #expect(result.interval == 1, "Failed review should reset to 1-day interval")
        #expect(result.repetitions == 0, "Repetitions should reset to 0")
        #expect(result.easeFactor >= 1.3, "Ease factor should not go below minimum")
    }

    // MARK: - Second Review Tests

    @Test func secondReviewWithGoodQuality() async throws {
        let result = sm2Service.calculateNextReview(
            currentEF: 2.5,
            currentInterval: 1,
            currentReps: 1,
            quality: 4 // Good
        )

        #expect(result.interval == 6, "Second successful review should have 6-day interval")
        #expect(result.repetitions == 2, "Repetitions should increment to 2")
    }

    // MARK: - Subsequent Review Tests

    @Test func thirdReviewIntervalCalculation() async throws {
        let result = sm2Service.calculateNextReview(
            currentEF: 2.5,
            currentInterval: 6,
            currentReps: 2,
            quality: 4 // Good
        )

        #expect(result.interval == 15, "Third review: 6 * 2.5 = 15 days")
        #expect(result.repetitions == 3, "Repetitions should increment to 3")
    }

    @Test func subsequentReviewWithHighEaseFactor() async throws {
        let result = sm2Service.calculateNextReview(
            currentEF: 3.0,
            currentInterval: 10,
            currentReps: 3,
            quality: 5 // Easy
        )

        #expect(result.interval == 30, "10 * 3.0 = 30 days")
        #expect(result.easeFactor > 3.0, "Easy rating should increase EF")
    }

    // MARK: - Ease Factor Tests

    @Test func easeFactorDecreasesOnHardReview() async throws {
        let initialEF = 2.5
        let result = sm2Service.calculateNextReview(
            currentEF: initialEF,
            currentInterval: 6,
            currentReps: 2,
            quality: 3 // Hard but correct
        )

        #expect(result.easeFactor < initialEF, "Hard review should decrease ease factor")
        #expect(result.easeFactor >= 1.3, "Ease factor should not go below minimum")
    }

    @Test func easeFactorIncreasesOnEasyReview() async throws {
        let initialEF = 2.5
        let result = sm2Service.calculateNextReview(
            currentEF: initialEF,
            currentInterval: 6,
            currentReps: 2,
            quality: 5 // Easy
        )

        #expect(result.easeFactor > initialEF, "Easy review should increase ease factor")
    }

    @Test func easeFactorNeverBelowMinimum() async throws {
        // Multiple poor reviews to push EF down
        var ef = 2.5
        var interval = 1
        var reps = 0

        for _ in 0..<10 {
            let result = sm2Service.calculateNextReview(
                currentEF: ef,
                currentInterval: interval,
                currentReps: reps,
                quality: 0 // Complete blackout
            )
            ef = result.easeFactor
            interval = result.interval
            reps = result.repetitions
        }

        #expect(ef >= 1.3, "Ease factor should never go below 1.3")
    }

    // MARK: - Reset on Failure Tests

    @Test func resetOnFailureAfterMultipleSuccesses() async throws {
        let result = sm2Service.calculateNextReview(
            currentEF: 2.8,
            currentInterval: 30,
            currentReps: 5,
            quality: 2 // Incorrect
        )

        #expect(result.interval == 1, "Failed review should reset interval to 1")
        #expect(result.repetitions == 0, "Failed review should reset repetitions to 0")
    }

    // MARK: - Quality Threshold Tests

    @Test func qualityThresholdBehavior() async throws {
        // Quality 2 (below threshold) should fail
        let failResult = sm2Service.calculateNextReview(
            currentEF: 2.5,
            currentInterval: 6,
            currentReps: 2,
            quality: 2
        )
        #expect(failResult.repetitions == 0, "Quality 2 should reset repetitions")

        // Quality 3 (at threshold) should pass
        let passResult = sm2Service.calculateNextReview(
            currentEF: 2.5,
            currentInterval: 6,
            currentReps: 2,
            quality: 3
        )
        #expect(passResult.repetitions == 3, "Quality 3 should increment repetitions")
    }

    // MARK: - Next Review Date Tests

    @Test func nextReviewDateIsInFuture() async throws {
        let result = sm2Service.calculateNextReview(
            currentEF: 2.5,
            currentInterval: 0,
            currentReps: 0,
            quality: 4
        )

        #expect(result.nextReviewDate > Date(), "Next review date should be in the future")
    }
}

// MARK: - Mastery Level Tests

struct MasteryLevelTests {

    @Test func masteryLevelOrder() async throws {
        // Verify mastery levels can be compared logically
        let levels: [MasteryLevel] = [.new, .learning, .reviewing, .mastered]

        #expect(levels[0] == .new, "First level should be new")
        #expect(levels[3] == .mastered, "Last level should be mastered")
    }
}

// MARK: - Session Stats Tests

struct SessionStatsTests {

    @Test func accuracyCalculation() async throws {
        var stats = SessionStats()
        stats.totalReviewed = 10
        stats.knownCount = 8
        stats.unknownCount = 2

        #expect(stats.accuracy == 0.8, "Accuracy should be 80%")
    }

    @Test func accuracyWithNoReviews() async throws {
        let stats = SessionStats()

        #expect(stats.accuracy == 0, "Accuracy should be 0 with no reviews")
    }

    @Test func perfectAccuracy() async throws {
        var stats = SessionStats()
        stats.totalReviewed = 20
        stats.knownCount = 20
        stats.unknownCount = 0

        #expect(stats.accuracy == 1.0, "Perfect session should have 100% accuracy")
    }
}

// MARK: - Achievement Tests

struct AchievementTests {

    @Test func achievementLookupById() async throws {
        let firstWord = Achievement.byId("first_word")
        #expect(firstWord != nil, "Should find first_word achievement")
        #expect(firstWord?.title == "初次学习", "Title should match")

        let invalid = Achievement.byId("invalid_id")
        #expect(invalid == nil, "Should return nil for invalid ID")
    }

    @Test func allAchievementsHaveUniqueIds() async throws {
        let ids = Achievement.all.map { $0.id }
        let uniqueIds = Set(ids)

        #expect(ids.count == uniqueIds.count, "All achievement IDs should be unique")
    }

    @Test func allAchievementsHaveRequiredFields() async throws {
        for achievement in Achievement.all {
            #expect(!achievement.id.isEmpty, "ID should not be empty")
            #expect(!achievement.title.isEmpty, "Title should not be empty")
            #expect(!achievement.description.isEmpty, "Description should not be empty")
            #expect(!achievement.iconName.isEmpty, "Icon name should not be empty")
        }
    }
}
