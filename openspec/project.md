# Project Context

## Purpose

LingoLearn is an iOS vocabulary learning app designed to help Chinese students master English vocabulary for standardized tests (CET-4 and CET-6). The app uses the SM-2 spaced repetition algorithm to optimize retention and features gamification elements including streaks, achievements, and progress tracking to keep users engaged.

### Core Goals
- Efficient vocabulary acquisition through scientifically-proven spaced repetition
- Engaging learning experience with flashcards, multiple practice modes, and achievements
- Progress tracking with visual charts and statistics
- Offline-first design with local data persistence

## Tech Stack

- **Language:** Swift 5.9+
- **Platform:** iOS 26.0+
- **UI Framework:** SwiftUI
- **Data Persistence:** SwiftData
- **Charts:** Swift Charts
- **Text-to-Speech:** AVSpeechSynthesizer
- **Haptics:** UIFeedbackGenerator
- **Local Notifications:** UNUserNotificationCenter
- **Testing:** Swift Testing (unit tests), XCTest (UI tests)
- **Build System:** Xcode / xcodebuild

## Project Conventions

### Code Style

**Imports:**
- Group imports by framework, sorted alphabetically within groups
- Standard library first, then third-party, then project imports
```swift
import Foundation
import SwiftUI
import SwiftData
```

**Formatting:**
- 4 spaces for indentation (no tabs)
- Maximum line length: 120 characters
- Trailing commas in arrays/dictionaries
- Opening braces on same line as declaration
- Blank lines between function implementations

**Naming Conventions:**
- Types/Classes/Enums: PascalCase (`HomeViewModel`, `WordCategory`)
- Variables/Properties: camelCase (`currentStreak`, `userStats`)
- Methods: camelCase starting with verb (`calculateNextReview`, `fetchWords`)
- Booleans: prefixes like `isEnabled`, `hasStarted`, `shouldAnimate`
- Acronyms: capitalize both letters (`URL`, `JSON`, `SM2Service`)

**SwiftData:**
- Use `#Predicate` with enum values captured in local variables:
```swift
let mastered = MasteryLevel.mastered
let predicate = #Predicate<Word> { $0.masteryLevel == mastered }
```
- Mark models with `@Model` and `final class`
- Use `@Attribute(.unique)` for unique identifiers

### Architecture Patterns

**MVVM + Repository Pattern:**
```
Views (SwiftUI) → ViewModels (@Observable) → Services/Repositories → SwiftData (ModelContext)
```

**Directory Structure:**
```
LingoLearn/
├── LingoLearnApp.swift          # App entry, ModelContainer setup
├── ContentView.swift            # TabView navigation (6 tabs)
├── Models/                      # SwiftData @Model entities
├── Core/
│   ├── Theme/                   # Color definitions
│   ├── Extensions/              # Date, Color, View extensions
│   ├── Utilities/               # HapticManager, AppLogger
│   └── Components/              # Reusable UI components
├── Services/                    # Business logic services (singletons)
├── Features/                    # Feature modules (Home, Learning, Practice, etc.)
└── Resources/Words/             # JSON vocabulary data files
```

**Services Pattern:**
- Use shared singleton instances for services
```swift
class SM2Service {
    static let shared = SM2Service()
    private init() {}
}
```

### Testing Strategy

- **Framework:** Swift Testing (`@Test`, `#expect`)
- **Test Location:** `LingoLearnTests/` directory
- **Naming:** `methodName_stateUnderTest_expectedResult`
- **Organization:** Group tests with struct and `// MARK:` sections

**Run Tests:**
```bash
xcodebuild -project LingoLearn.xcodeproj -scheme LingoLearn -destination 'platform=iOS Simulator,name=iPhone 17' test
```

**Run Single Test:**
```bash
xcodebuild -project LingoLearn.xcodeproj -scheme LingoLearn -destination 'platform=iOS Simulator,name=iPhone 17' test -only-testing:LingoLearnTests/LingoLearnTests/SM2ServiceTests/firstReviewWithGoodQuality
```

### Git Workflow

- Feature branches for new development
- Commit messages should be concise and descriptive
- Never commit commented-out code

## Domain Context

### SM-2 Spaced Repetition Algorithm
The app implements the SuperMemo SM-2 algorithm for scheduling word reviews:
- **Ease Factor (EF):** Starts at 2.5, minimum 1.3, adjusts based on response quality
- **Quality Rating:** 0-5 scale (0-2 = incorrect, 3 = hard, 4 = good, 5 = easy)
- **Intervals:** First review after 1 day, second after 6 days, then `interval * EF`

### Mastery Levels
Words progress through four mastery levels:
1. **New:** Never studied
2. **Learning:** Currently being learned (repetitions < 3)
3. **Reviewing:** In review cycle (interval >= 21 days)
4. **Mastered:** Well-learned (interval >= 30 days)

### Vocabulary Categories
- **CET-4:** College English Test Band 4 (~300 words)
- **CET-6:** College English Test Band 6 (~200 words)

### Key Features
1. **Flashcard Learning:** 3D flip animations, swipe gestures for responses
2. **Practice Modes:** Multiple choice, true/false, fill-in-blank, listening tests
3. **Progress Tracking:** Line charts, calendar heatmap, mastery pie chart
4. **Achievements:** 8 achievement types with unlock animations
5. **Streaks:** Daily study streak tracking with freeze protection
6. **Notifications:** Study reminders with quick-action support

## Important Constraints

- **Offline-First:** All data stored locally via SwiftData; no backend required
- **iOS 26.0+:** Minimum deployment target
- **Localization:** Primary UI language is Simplified Chinese
- **Accessibility:** Support for VoiceOver and Dynamic Type where applicable

## External Dependencies

The app uses only Apple first-party frameworks with no external package dependencies:
- **SwiftUI:** User interface
- **SwiftData:** Data persistence
- **Swift Charts:** Progress visualization
- **AVFoundation:** Text-to-speech (AVSpeechSynthesizer)
- **UserNotifications:** Local notification scheduling
- **UIKit:** Haptic feedback (UIFeedbackGenerator)

## Design Tokens

### Colors
- **Primary Blue:** `#0EA5E9`
- **Accent Teal:** `#14B8A6`
- **Success Green:** `#10B981`
- **Error Red:** `#EF4444`
- **Warning Orange:** `#F59E0B`
