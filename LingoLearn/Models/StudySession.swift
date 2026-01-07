import Foundation
import SwiftData

enum SessionType: String, Codable, CaseIterable {
    case learning = "Learning"
    case review = "Review"
    case practice = "Practice"
    case multipleChoice = "Multiple Choice"
    case fillInBlank = "Fill in Blank"
    case listening = "Listening"
    case trueFalse = "True/False"
    case multiSelect = "Multi-Select"
}

@Model
final class StudySession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var sessionType: SessionType
    var wordsStudied: Int
    var wordsCorrect: Int
    var wordsIncorrect: Int
    var duration: TimeInterval // in seconds
    var completed: Bool

    init(sessionType: SessionType, wordsStudied: Int = 0, wordsCorrect: Int = 0,
         wordsIncorrect: Int = 0, duration: TimeInterval = 0, completed: Bool = false) {
        self.id = UUID()
        self.date = Date()
        self.sessionType = sessionType
        self.wordsStudied = wordsStudied
        self.wordsCorrect = wordsCorrect
        self.wordsIncorrect = wordsIncorrect
        self.duration = duration
        self.completed = completed
    }
}
