# Change: Add Multi-Select Multiple-Choice Quiz Mode

## Why

The current multiple-choice quiz only allows single answer selection, which tests basic recall. A multi-select mode where users must identify ALL correct translations from a set of options provides a more challenging and comprehensive test of vocabulary mastery, as it requires users to recognize multiple correct answers while avoiding incorrect ones.

## What Changes

- Add new `multiSelect` session type to `SessionType` enum
- Create `MultiSelectQuizView` for the new quiz mode UI
- Extend `PracticeViewModel` to support multi-select question generation and scoring
- Update `PracticeMenuView` to include the new quiz type option
- Extend `AnswerOptionButton` to support multi-select toggle behavior
- Update `TestViewRouter` to route to the new view

## Impact

- Affected specs: `practice` (new capability within practice module)
- Affected code:
  - `LingoLearn/Models/StudySession.swift` - Add new session type
  - `LingoLearn/Features/Practice/PracticeViewModel.swift` - Multi-select question generation
  - `LingoLearn/Features/Practice/PracticeMenuView.swift` - Menu entry for new quiz type
  - `LingoLearn/Features/Practice/MultiSelectQuizView.swift` - New view (to be created)
  - `LingoLearn/Features/Practice/Components/AnswerOptionButton.swift` - Multi-select state support
