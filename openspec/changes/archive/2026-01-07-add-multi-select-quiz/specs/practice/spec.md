## ADDED Requirements

### Requirement: Multi-Select Quiz Mode
The system SHALL provide a multi-select multiple-choice quiz mode where users identify all correct Chinese translations for a given English word from a set of options.

#### Scenario: Start multi-select quiz from practice menu
- **WHEN** user selects "Multi-Select Quiz" from the practice menu
- **AND** user configures word count and category
- **AND** user taps "Start Test"
- **THEN** the system navigates to the multi-select quiz view
- **AND** displays the first question with timer

#### Scenario: Display multi-select question
- **WHEN** a multi-select question is displayed
- **THEN** the system shows the English word with phonetic spelling
- **AND** displays 5-6 Chinese translation options
- **AND** shows an instruction badge "Select ALL correct translations"
- **AND** 2-3 of the options are correct translations
- **AND** all options are initially unselected

#### Scenario: Toggle answer selection
- **WHEN** user taps an unselected answer option
- **THEN** the option becomes selected with visual indicator
- **AND** haptic feedback is triggered
- **WHEN** user taps a selected answer option
- **THEN** the option becomes unselected
- **AND** the submit button updates to show selection count

#### Scenario: Submit answer with all correct selections
- **WHEN** user has selected all correct options and no incorrect options
- **AND** user taps the Submit button
- **THEN** the system awards full credit (1.0 points)
- **AND** displays success animation
- **AND** all selected options show green "correct" state
- **AND** plays success sound

#### Scenario: Submit answer with partial correct selections
- **WHEN** user has selected some but not all correct options
- **AND** user has not selected any incorrect options
- **AND** user taps the Submit button
- **THEN** the system awards partial credit based on formula: correctSelected / totalCorrect
- **AND** selected correct options show green state
- **AND** missed correct options show yellow/orange "missed" outline
- **AND** plays partial success sound

#### Scenario: Submit answer with incorrect selections
- **WHEN** user has selected one or more incorrect options
- **AND** user taps the Submit button
- **THEN** the system calculates score as max(0, (correctSelected - incorrectSelected) / totalCorrect)
- **AND** incorrect selections show red "wrong" state
- **AND** correct selections show green state
- **AND** missed correct options show "missed" indicator
- **AND** plays error sound if score is 0

#### Scenario: Timer expires before submission
- **WHEN** the question timer reaches zero
- **AND** user has not submitted an answer
- **THEN** the system auto-submits with current selections
- **AND** scoring proceeds as normal based on current state

#### Scenario: Complete multi-select quiz
- **WHEN** user completes all questions in the quiz
- **THEN** the system saves a StudySession with type `.multiSelect`
- **AND** displays TestResultsView with accuracy percentage
- **AND** shows breakdown of fully correct, partially correct, and incorrect answers

### Requirement: Multi-Select Question Generation
The system SHALL generate multi-select questions with appropriate correct and distractor answers.

#### Scenario: Generate question with multiple correct answers
- **WHEN** generating a multi-select question for a word with multiple Chinese meanings
- **THEN** the system includes 2-3 correct translations as options
- **AND** includes 3-4 distractor translations from other words
- **AND** shuffles all options randomly

#### Scenario: Generate question for word with single meaning
- **WHEN** generating a multi-select question for a word with only one Chinese meaning
- **THEN** the system includes the correct translation
- **AND** includes 1-2 semantically related synonyms as additional correct options
- **OR** generates a synonym-based question format

### Requirement: Multi-Select Session Tracking
The system SHALL track multi-select quiz sessions for progress statistics.

#### Scenario: Record session statistics
- **WHEN** a multi-select quiz session completes
- **THEN** the system records:
  - Total questions attempted
  - Questions with full credit
  - Questions with partial credit
  - Questions with zero credit
  - Total accumulated score
  - Session duration
- **AND** the session appears in progress history with type "Multi-Select"
