import Foundation
import SwiftData

enum WordCategory: String, Codable, CaseIterable {
    case cet4 = "CET-4"
    case cet6 = "CET-6"
}

enum MasteryLevel: String, Codable, CaseIterable {
    case new = "New"
    case learning = "Learning"
    case reviewing = "Reviewing"
    case mastered = "Mastered"
}

@Model
final class Word {
    @Attribute(.unique) var id: UUID
    var english: String
    var chinese: String
    var phonetic: String
    var partOfSpeech: String
    var exampleSentence: String
    var exampleTranslation: String
    var category: WordCategory
    var difficulty: Int

    // SM-2 Algorithm Fields
    var easeFactor: Double = 2.5
    var interval: Int = 0
    var repetitions: Int = 0
    var nextReviewDate: Date?

    // User Interaction
    var isFavorite: Bool = false
    var masteryLevel: MasteryLevel = MasteryLevel.new
    var timesStudied: Int = 0
    var timesCorrect: Int = 0
    var lastStudiedDate: Date?
    var dateAdded: Date

    // Personal Notes
    var personalNote: String = ""

    init(english: String, chinese: String, phonetic: String, partOfSpeech: String,
         exampleSentence: String, exampleTranslation: String, category: WordCategory, difficulty: Int) {
        self.id = UUID()
        self.english = english
        self.chinese = chinese
        self.phonetic = phonetic
        self.partOfSpeech = partOfSpeech
        self.exampleSentence = exampleSentence
        self.exampleTranslation = exampleTranslation
        self.category = category
        self.difficulty = difficulty
        self.dateAdded = Date()
    }
}
