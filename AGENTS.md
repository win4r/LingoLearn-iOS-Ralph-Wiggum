<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

# AGENTS.md

This file provides guidance for AI agents working in the LingoLearn iOS codebase.

## Build, Lint, and Test Commands

### Build
```bash
xcodebuild -project LingoLearn.xcodeproj -scheme LingoLearn -destination 'platform=iOS Simulator,name=iPhone 17' build
```

### Run All Tests
```bash
xcodebuild -project LingoLearn.xcodeproj -scheme LingoLearn -destination 'platform=iOS Simulator,name=iPhone 17' test
```

### Run a Single Test
```bash
xcodebuild -project LingoLearn.xcodeproj -scheme LingoLearn -destination 'platform=iOS Simulator,name=iPhone 17' test -only-testing:LingoLearnTests/LingoLearnTests/SM2ServiceTests/firstReviewWithGoodQuality
```

### Run a Test Suite
```bash
xcodebuild -project LingoLearn.xcodeproj -scheme LingoLearn -destination 'platform=iOS Simulator,name=iPhone 17' test -only-testing:LingoLearnTests/LingoLearnTests/SM2ServiceTests
```

## Code Style Guidelines

### Imports
- Group imports by framework, sorted alphabetically within groups
- Place standard library imports first, then third-party, then project imports
```swift
import Foundation
import SwiftUI
import SwiftData
```

### Formatting
- Use 4 spaces for indentation (no tabs)
- Maximum line length: 120 characters
- Use trailing commas in arrays/dictionaries
- Add blank lines between function implementations and between major code blocks
- Place opening braces on the same line as declaration

### Types
- Use structs for simple data containers (favor `struct` over `class` when possible)
- Use classes for reference types needing inheritance or identity
- Use `final class` when class inheritance is not needed
- Conform to protocols using comma-separated syntax
```swift
enum WordCategory: String, Codable, CaseIterable {
    case cet4 = "CET-4"
    case cet6 = "CET-6"
}

@Model
final class Word {
    // ...
}
```

### Naming Conventions
- **Types/Classes/Enums**: PascalCase (e.g., `HomeViewModel`, `WordCategory`)
- **Variables/Constants/Properties**: camelCase (e.g., `currentStreak`, `userStats`)
- **Methods/Functions**: camelCase starting with verb (e.g., `calculateNextReview`)
- **Private/internal properties**: prefix with underscore is not used; use clear names
- **Booleans**: use descriptive prefixes like `isEnabled`, `hasStarted`, `shouldAnimate`
- **Acronyms**: capitalize both letters (e.g., `URL`, `JSON`, `SM2Service`)

### Property Declarations
- Group related properties together
- Use sensible defaults for optional types
- Place `@Attribute` annotations before properties
- Mark singleton services with `static let shared`

### Error Handling
- Use `throw`/`throws` for functions that can fail
- Use `try?` for operations where failure is acceptable
- Use `guard` for early returns with failure conditions
- Provide meaningful error messages

### SwiftUI View Guidelines
- Use `@State`, `@Binding`, `@ObservedObject`, `@Environment` appropriately
- Prefer private computed properties for view components
- Use `@ViewBuilder` for custom view builders
- Prefix preview macros with `#Preview`
- Organize large views with `// MARK:` sections

### SwiftData
- Use `#Predicate` with enum values captured in local variables:
```swift
let mastered = MasteryLevel.mastered
let predicate = #Predicate<Word> { $0.masteryLevel == mastered }
```
- Mark SwiftData models with `@Model` and `final class`
- Use `@Attribute(.unique)` for unique identifiers

### Services and Singleton Pattern
- Use shared singleton instances for services
```swift
class SM2Service {
    static let shared = SM2Service()
    private init() {}
}
```

### Testing
- Use Swift Testing framework (`@Test`, `#expect`)
- Group tests with struct and `// MARK:` sections
- Place test files in `LingoLearnTests/` directory
- Use descriptive test names following `methodName_stateUnderTest_expectedResult` pattern

### Comments
- Avoid unnecessary comments; code should be self-documenting
- Use `// MARK:` to organize code sections
- Document public APIs with doc comments when needed
- Never commit commented-out code

### Architecture
Follow MVVM + Repository pattern:
```
Views (SwiftUI) → ViewModels (@Observable) → Services/Repositories → SwiftData (ModelContext)
```

### Project Conventions
- **Platform**: iOS 26.0+
- **Swift Version**: 5.9+
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **Charts**: Swift Charts
- **Colors**: #0EA5E9 (primary), #14B8A6 (secondary)

### Directory Structure
```
LingoLearn/
├── LingoLearnApp.swift          # App entry, ModelContainer setup
├── ContentView.swift            # TabView navigation (5 tabs)
├── Models/                      # SwiftData @Model entities
├── Core/
│   ├── Theme/AppColors.swift    # Color definitions
│   ├── Extensions/              # Date, Color, View extensions
│   ├── Utilities/HapticManager.swift
│   └── Components/              # RingProgressView, FlameStreakView, etc.
├── Services/
│   ├── SM2Service.swift         # Spaced repetition algorithm
│   ├── SpeechService.swift      # AVSpeechSynthesizer TTS
│   ├── DataSeederService.swift  # First-launch word data loading
│   ├── AchievementService.swift # Achievement checking
│   └── NotificationService.swift # Local notifications
├── Features/
│   ├── Home/
│   ├── Learning/
│   ├── Practice/
│   ├── Progress/
│   └── Settings/
└── Resources/Words/             # cet4_words.json, cet6_words.json
```
