//
//  MultiSelectQuizView.swift
//  LingoLearn
//
//  Multi-select quiz where users identify ALL correct translations
//

import SwiftUI
import SwiftData

struct MultiSelectQuizView: View {
    let wordCount: Int
    let category: PracticeCategory

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allWords: [Word]
    @Query private var userSettings: [UserSettings]

    @State private var viewModel = PracticeViewModel()
    @State private var selectedAnswers: Set<String> = []
    @State private var answerSubmitted = false
    @State private var showCorrectAnimation = false
    @State private var showWrongAnimation = false
    @State private var isLoading = true
    @State private var navigateToResults = false
    @State private var answerStates: [String: AnswerState] = [:]
    @State private var lastScore: Double = 0

    private var filteredWords: [Word] {
        if category == .all {
            return Array(allWords.shuffled().prefix(wordCount))
        } else {
            let categoryEnum: WordCategory = category == .cet4 ? .cet4 : .cet6
            let filtered = allWords.filter { $0.category == categoryEnum }
            return Array(filtered.shuffled().prefix(wordCount))
        }
    }

    private var timeLimit: Double {
        Double(userSettings.first?.questionTimeLimit ?? 20)
    }

    private var canSubmit: Bool {
        !selectedAnswers.isEmpty && !answerSubmitted
    }

    var body: some View {
        ZStack {
            if isLoading {
                LoadingView(message: "准备测试...")
            } else if viewModel.testCompleted {
                Color.clear
            } else {
                VStack(spacing: 0) {
                    // Timer bar
                    CountdownTimerBar(
                        timeRemaining: viewModel.timeRemaining,
                        totalTime: viewModel.questionTimeLimit
                    )
                    .padding()

                    // Progress indicator
                    progressHeader

                    // Question area
                    if let question = viewModel.currentMultiSelectQuestion {
                        questionContent(question: question)
                    }
                }
            }

            // Answer animations overlay
            if showCorrectAnimation {
                CorrectAnswerAnimation()
                    .transition(.scale.combined(with: .opacity))
            }

            if showWrongAnimation {
                WrongAnswerAnimation()
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .navigationTitle("多选题")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("退出") {
                    viewModel.stopTimer()
                    dismiss()
                }
            }
        }
        .navigationDestination(isPresented: $navigateToResults) {
            TestResultsView(
                sessionType: .multiSelect,
                correctAnswers: viewModel.correctAnswers,
                wrongAnswers: viewModel.wrongAnswers,
                totalQuestions: viewModel.totalQuestions,
                duration: Date().timeIntervalSince(viewModel.sessionStartTime ?? Date())
            )
        }
        .onAppear {
            setupTest()
        }
        .onDisappear {
            viewModel.stopTimer()
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: 8) {
            HStack {
                // Question counter
                HStack(spacing: 6) {
                    Image(systemName: "list.number")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    Text("题目 \(viewModel.currentQuestionIndex + 1) / \(viewModel.totalQuestions)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Score indicator
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.green.opacity(0.2), .mint.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    Text("\(viewModel.correctAnswers)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }

            // Progress dots
            QuestionProgressDots(
                totalQuestions: viewModel.totalQuestions,
                currentIndex: viewModel.currentQuestionIndex,
                correctAnswers: viewModel.correctAnswers
            )
        }
        .padding(.horizontal)
    }

    // MARK: - Question Content

    @ViewBuilder
    private func questionContent(question: MultiSelectQuestion) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Instruction badge
                HStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill")
                        .font(.caption)
                    Text("选择所有正确的中文释义")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [.purple, .purple.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .purple.opacity(0.3), radius: 6, y: 3)
                .padding(.top, 16)

                // English word card
                wordCard(word: question.word)

                // Selection count indicator
                if !answerSubmitted {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("已选择 \(selectedAnswers.count) 个")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(selectedAnswers.isEmpty ? Color.secondary : Color.accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(selectedAnswers.isEmpty ? Color.gray.opacity(0.1) : Color.accentColor.opacity(0.1))
                    )
                }

                // Answer options
                VStack(spacing: 12) {
                    ForEach(question.options, id: \.self) { option in
                        AnswerOptionButton(
                            text: option,
                            state: answerStates[option] ?? (selectedAnswers.contains(option) ? .selected : .normal),
                            action: {
                                if !answerSubmitted {
                                    toggleSelection(option)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)

                // Submit button
                if !answerSubmitted {
                    Button(action: submitAnswer) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.headline)
                            Text("提交答案")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: canSubmit ? [.purple, .purple.opacity(0.8)] : [.gray, .gray.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: canSubmit ? .purple.opacity(0.3) : .clear, radius: 8, y: 4)
                    }
                    .disabled(!canSubmit)
                    .padding(.horizontal)
                } else {
                    // Score feedback after submission
                    scoreFeedback
                }

                Spacer(minLength: 20)
            }
        }
    }

    // MARK: - Word Card

    private func wordCard(word: Word) -> some View {
        VStack(spacing: 14) {
            // Category indicator
            HStack(spacing: 4) {
                Image(systemName: "book.closed.fill")
                    .font(.caption2)
                Text(word.category.rawValue)
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                LinearGradient(
                    colors: [.purple, .pink],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())

            Text(word.english)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.primary, .primary.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text(word.phonetic)
                .font(.system(size: 16, design: .monospaced))
                .foregroundStyle(.secondary)

            Text(word.partOfSpeech)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color(.systemGray6))
                .clipShape(Capsule())
        }
        .padding(.vertical, 20)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))

                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.08), .pink.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [.purple.opacity(0.2), .pink.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .purple.opacity(0.1), radius: 12, y: 6)
        .padding(.horizontal)
    }

    // MARK: - Score Feedback

    private var scoreFeedback: some View {
        VStack(spacing: 12) {
            let scorePercent = Int(lastScore * 100)

            HStack(spacing: 8) {
                Image(systemName: scorePercent == 100 ? "star.fill" : scorePercent > 0 ? "star.leadinghalf.filled" : "star")
                    .font(.title2)
                    .foregroundStyle(scorePercent == 100 ? .yellow : scorePercent > 0 ? .orange : .gray)

                Text(scorePercent == 100 ? "完全正确!" : scorePercent > 0 ? "部分正确" : "再接再厉")
                    .font(.headline)
                    .fontWeight(.bold)

                Text("(\(scorePercent)%)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        scorePercent == 100 ? Color.green.opacity(0.1) :
                        scorePercent > 0 ? Color.orange.opacity(0.1) : Color.red.opacity(0.1)
                    )
            )

            // Continue button
            Button(action: nextQuestion) {
                HStack(spacing: 8) {
                    Text("继续")
                        .font(.headline)
                    Image(systemName: "arrow.right")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.accentColor, .accentColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .accentColor.opacity(0.3), radius: 8, y: 4)
            }
            .padding(.horizontal)
        }
        .padding(.horizontal)
    }

    // MARK: - Actions

    private func toggleSelection(_ option: String) {
        HapticManager.shared.selection()
        if selectedAnswers.contains(option) {
            selectedAnswers.remove(option)
        } else {
            selectedAnswers.insert(option)
        }
    }

    private func submitAnswer() {
        guard let question = viewModel.currentMultiSelectQuestion else { return }

        answerSubmitted = true
        viewModel.stopTimer()

        let (score, isFullyCorrect) = viewModel.submitMultiSelectAnswer(selectedAnswers: selectedAnswers)
        lastScore = score

        // Update answer states for visual feedback
        for option in question.options {
            let isCorrect = question.correctAnswers.contains(option)
            let wasSelected = selectedAnswers.contains(option)

            if wasSelected && isCorrect {
                answerStates[option] = .correct
            } else if wasSelected && !isCorrect {
                answerStates[option] = .wrong
            } else if !wasSelected && isCorrect {
                answerStates[option] = .missed
            } else {
                answerStates[option] = .disabled
            }
        }

        // Show animation
        if isFullyCorrect {
            withAnimation {
                showCorrectAnimation = true
            }
        } else if score == 0 {
            withAnimation {
                showWrongAnimation = true
            }
        }

        // Hide animation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                showCorrectAnimation = false
                showWrongAnimation = false
            }
        }
    }

    private func nextQuestion() {
        // Reset state for next question
        selectedAnswers = []
        answerSubmitted = false
        answerStates = [:]
        lastScore = 0

        viewModel.nextQuestion()

        if viewModel.testCompleted {
            viewModel.saveSession(modelContext: modelContext, sessionType: .multiSelect)
            navigateToResults = true
        }
    }

    private func setupTest() {
        let words = filteredWords

        if words.isEmpty {
            isLoading = false
            return
        }

        viewModel.setupTest(
            words: words,
            testType: .multiSelect,
            timeLimit: timeLimit
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            viewModel.startTimer()
        }
    }
}

#Preview {
    NavigationStack {
        MultiSelectQuizView(wordCount: 10, category: .all)
            .modelContainer(for: [Word.self, StudySession.self, UserSettings.self])
    }
}
