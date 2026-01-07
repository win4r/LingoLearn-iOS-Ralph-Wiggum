# Design: Multi-Select Multiple-Choice Quiz Mode

## Context

LingoLearn currently offers four practice modes: single-answer multiple choice, fill-in-blank, listening, and true/false. All existing modes test single-word recognition. A multi-select mode adds complexity by requiring users to identify multiple correct answers, testing deeper vocabulary understanding.

## Goals / Non-Goals

### Goals
- Provide a more challenging vocabulary test that requires comprehensive knowledge
- Maintain consistent UX patterns with existing practice modes
- Support partial credit scoring to reward partial knowledge
- Integrate seamlessly with existing progress tracking and statistics

### Non-Goals
- Adaptive difficulty (all questions have similar structure)
- Timed per-selection (only overall question timer)
- Multiplayer or competitive features

## Decisions

### Question Structure
- **Decision**: Each question shows one English word with 5-6 Chinese translation options, where 2-3 are correct
- **Rationale**: This provides enough options to be challenging without being overwhelming; 2-3 correct answers ensures users must know the word well

### Answer Selection
- **Decision**: Users tap options to toggle selection (multi-select), then tap "Submit" to confirm
- **Alternatives considered**:
  - Auto-submit after N selections: Rejected because it limits flexibility and may frustrate users
  - Swipe gestures: Rejected for consistency with existing tap-based interaction

### Scoring Logic
- **Decision**: Partial credit scoring - score = (correct selections - incorrect selections) / total correct answers, minimum 0
- **Rationale**: Rewards partial knowledge while penalizing random guessing
- **Formula**: `score = max(0, (correctSelected - incorrectSelected)) / totalCorrect`
- **Example**: 3 correct answers exist, user selects 2 correct + 1 incorrect = (2-1)/3 = 0.33 points

### Visual Feedback
- **Decision**: After submission, show all options with correct/incorrect/missed states
- **States**:
  - `correct`: User selected, was correct (green)
  - `wrong`: User selected, was incorrect (red)
  - `missed`: User did not select, but was correct (yellow/orange outline)
  - `neutral`: User did not select, was incorrect (gray)

### Data Model
- **Decision**: Reuse existing `TestQuestion` struct with `options` as all choices and add `correctAnswers: Set<String>` for multi-select
- **Alternative**: Create separate `MultiSelectQuestion` struct
- **Rationale**: Extending existing struct minimizes code duplication, but may require optional properties

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Partial credit scoring may confuse users | Show detailed breakdown after each question |
| Too many options may overwhelm on small screens | Limit to 6 options max, use scrollable list if needed |
| Users may not realize they need to select multiple | Add clear instruction badge ("Select ALL correct translations") |

## UI Layout

```
+----------------------------------+
|  [Timer Bar]                     |
|  Question 3/10          Score: 2 |
+----------------------------------+
|                                  |
|  [Select ALL correct meanings]   |
|                                  |
|  +----------------------------+  |
|  |      "abandon"             |  |
|  |      /əˈbændən/            |  |
|  +----------------------------+  |
|                                  |
|  [ ] 放弃                        |
|  [x] 遗弃                        |  <- selected
|  [ ] 完成                        |
|  [x] 抛弃                        |  <- selected
|  [ ] 开始                        |
|  [ ] 沉溺于                      |
|                                  |
|  +----------------------------+  |
|  |      Submit (2 selected)   |  |
|  +----------------------------+  |
+----------------------------------+
```

## Open Questions

- Should there be a minimum/maximum number of selections before submit is enabled?
  - **Proposed**: Minimum 1 selection required, no maximum
- Should wrong selections have stronger penalty (e.g., -0.5 per wrong vs +1 per correct)?
  - **Proposed**: Equal weight for simplicity in v1
