//
//  SoundService.swift
//  LingoLearn
//
//  Sound effects service for app interactions
//

import AudioToolbox
import AVFoundation
import UIKit

/// Sound effects available in the app
enum SoundEffect {
    case success      // Correct answer, card mastered
    case error        // Wrong answer
    case swipeRight   // Swipe known
    case swipeLeft    // Swipe unknown
    case complete     // Session complete
    case levelUp      // Achievement unlocked
    case tap          // General tap
    case flip         // Card flip

    var systemSoundID: SystemSoundID {
        switch self {
        case .success:
            return 1025  // Positive acknowledgement
        case .error:
            return 1073  // Error/alert
        case .swipeRight:
            return 1104  // Swipe sound
        case .swipeLeft:
            return 1105  // Different swipe sound
        case .complete:
            return 1075  // Completion fanfare
        case .levelUp:
            return 1026  // Level up/achievement
        case .tap:
            return 1104  // Light tap
        case .flip:
            return 1306  // Card flip
        }
    }
}

@MainActor
class SoundService {
    static let shared = SoundService()

    var isEnabled: Bool = true

    private init() {}

    /// Play a sound effect
    func play(_ effect: SoundEffect) {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(effect.systemSoundID)
    }

    /// Play success sound
    func playSuccess() {
        play(.success)
    }

    /// Play error sound
    func playError() {
        play(.error)
    }

    /// Play swipe right (known) sound
    func playSwipeRight() {
        play(.swipeRight)
    }

    /// Play swipe left (unknown) sound
    func playSwipeLeft() {
        play(.swipeLeft)
    }

    /// Play completion sound
    func playComplete() {
        play(.complete)
    }

    /// Play level up/achievement sound
    func playLevelUp() {
        play(.levelUp)
    }

    /// Play general tap sound
    func playTap() {
        play(.tap)
    }

    /// Play card flip sound
    func playFlip() {
        play(.flip)
    }
}
