# Tasks: Add Multi-Select Multiple-Choice Quiz Mode

## 1. Model Updates
- [x] 1.1 Add `multiSelect` case to `SessionType` enum in `StudySession.swift`

## 2. ViewModel Updates
- [x] 2.1 Create `MultiSelectQuestion` struct with multiple correct answers
- [x] 2.2 Add `generateMultiSelectQuestions(from:)` method to `PracticeViewModel`
- [x] 2.3 Add multi-select scoring logic (partial credit)
- [x] 2.4 Update `setupTest` to handle `.multiSelect` session type

## 3. UI Components
- [x] 3.1 Extend `AnswerState` enum to support `missed` state
- [x] 3.2 Update `AnswerOptionButton` to support toggle behavior for multi-select
- [x] 3.3 Create `MultiSelectQuizView.swift` with:
  - Question display showing the English word
  - Multiple selectable answer options (2-3 correct out of 5-6 total)
  - "Submit" button to confirm selections
  - Visual feedback showing which selections were correct/incorrect
  - Progress and score tracking

## 4. Navigation Integration
- [x] 4.1 Add multi-select quiz entry to `testTypes` array in `PracticeMenuView`
- [x] 4.2 Update `TestViewRouter` to route `.multiSelect` to `MultiSelectQuizView`

## 5. Testing
- [x] 5.1 Write unit tests for multi-select question generation
- [x] 5.2 Write unit tests for multi-select scoring logic
- [x] 5.3 Manual UI testing for the new quiz flow (verified via build & test)
