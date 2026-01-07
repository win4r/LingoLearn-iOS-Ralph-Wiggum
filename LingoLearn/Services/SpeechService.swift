//
//  SpeechService.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import AVFoundation
import Foundation
import Combine

class SpeechService: NSObject, ObservableObject {
    static let shared = SpeechService()

    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Speak text using AVSpeechSynthesizer
    /// - Parameters:
    ///   - text: The text to speak
    ///   - language: Language code (default: "en-US")
    ///   - rate: Speech rate (default uses AppConstants value)
    func speak(text: String, language: String = AppConstants.Speech.defaultLanguage, rate: Float? = nil) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate ?? AppConstants.Speech.learningRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        synthesizer.speak(utterance)
        isSpeaking = true
    }

    /// Stop current speech
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
}

extension SpeechService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
}
