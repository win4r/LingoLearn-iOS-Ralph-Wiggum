//
//  TrueFalseView.swift
//  LingoLearn
//
//  Created by Charles Qin on 1/7/26.
//

import SwiftUI
import SwiftData

struct TrueFalseView: View {
    let wordCount: Int
    let category: PracticeCategory

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allWords: [Word]
    @Query private var userSettings: [UserSettings]

    @State private var viewModel = PracticeViewModel()
    @State private var selectedAnswer: Bool? = nil
    @State private var answerSubmitted = false
    @State private var showCorrectAnimation = false
    @State private var showWrongAnimation = false
    @State private var isLoading = true
    @State private var navigateToResults = false

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
        Double(userSettings.first?.questionTimeLimit ?? 15)
    }

    private func buttonState(for answer: Bool) -> AnswerState {
        if !answerSubmitted {
            return selectedAnswer == answer ? .selected : .normal
        } else {
            guard let correctBool = viewModel.currentQuestion?.correctBoolAnswer else { return .disabled }
            let correctAnswer = correctBool ? "True" : "False"
            let selectedAnswerStr = (answer ? "True" : "False")

            if selectedAnswerStr == correctAnswer {
                return .correct
            } else if selectedAnswer == answer {
                return .wrong
            } else {
                return .disabled
            }
        }
    }

    var body: some View {
        ZStack {
            if isLoading {
                LoadingView(message: "准备测试...")
            } else if viewModel.testCompleted {
                Color.clear
            } else {
                VStack(spacing: 0) {
                    CountdownTimerBar(
                        timeRemaining: viewModel.timeRemaining,
                        totalTime: viewModel.questionTimeLimit
                    )
                    .padding()

                    VStack(spacing: 8) {
                        HStack {
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

                        QuestionProgressDots(
                            totalQuestions: viewModel.totalQuestions,
                            currentIndex: viewModel.currentQuestionIndex,
                            correctAnswers: viewModel.correctAnswers
                        )
                    }
                    .padding(.horizontal)

                    if let question = viewModel.currentQuestion {
                        VStack(spacing: 32) {
                            HStack(spacing: 6) {
                                Image(systemName: "hand.tap.fill")
                                    .font(.caption)
                                Text("判断翻译是否正确")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: .purple.opacity(0.3), radius: 6, y: 3)
                            .padding(.top, 20)

                            VStack(spacing: 16) {
                                HStack(spacing: 4) {
                                    Image(systemName: "book.closed.fill")
                                        .font(.caption2)
                                    Text(question.word.category.rawValue)
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())

                                if let statement = question.statement {
                                    Text(statement)
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.primary, .primary.opacity(0.8)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .multilineTextAlignment(.center)
                                }

                                Text(question.word.phonetic)
                                    .font(.system(size: 18, design: .monospaced))
                                    .foregroundStyle(.secondary)

                                Text(question.word.partOfSpeech)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 5)
                                    .background(Color(.systemGray6))
                                    .clipShape(Capsule())
                            }
                            .padding(.vertical, 24)
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

                            VStack(spacing: 16) {
                                HStack(spacing: 16) {
                                    TrueFalseButton(
                                        title: "√ 正确",
                                        isSelected: selectedAnswer == true,
                                        state: buttonState(for: true),
                                        isCorrectAnswer: true,
                                        action: {
                                            if !answerSubmitted {
                                                handleAnswerSelection(true)
                                            }
                                        }
                                    )

                                    TrueFalseButton(
                                        title: "× 错误",
                                        isSelected: selectedAnswer == false,
                                        state: buttonState(for: false),
                                        isCorrectAnswer: false,
                                        action: {
                                            if !answerSubmitted {
                                                handleAnswerSelection(false)
                                            }
                                        }
                                    )
                                }
                                .padding(.horizontal)

                                if answerSubmitted {
                                    if let statement = question.statement {
                                        let isCorrect = (selectedAnswer == true && viewModel.currentQuestion?.correctBoolAnswer == true) ||
                                                       (selectedAnswer == false && viewModel.currentQuestion?.correctBoolAnswer == false)

                                        HStack(spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .fill(
                                                        LinearGradient(
                                                            colors: isCorrect ? [.green, .mint] : [.red, .orange],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(width: 32, height: 32)

                                                Image(systemName: isCorrect ? "checkmark" : "xmark")
                                                    .font(.caption.weight(.bold))
                                                    .foregroundStyle(.white)
                                            }

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(isCorrect ? "回答正确" : "正确答案")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)

                                                HStack(spacing: 8) {
                                                    Text(isCorrect ? "True" : (viewModel.currentQuestion?.correctBoolAnswer == true ? "正确" : "错误"))
                                                        .font(.title3)
                                                        .fontWeight(.bold)
                                                        .foregroundStyle(
                                                            LinearGradient(
                                                                colors: isCorrect ? [.green, .mint] : [.red, .orange],
                                                                startPoint: .leading,
                                                                endPoint: .trailing
                                                            )
                                                        )

                                                    Text(viewModel.currentQuestion?.word.english ?? "")
                                                        .font(.subheadline)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }

                                            Spacer()
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(
                                                    LinearGradient(
                                                        colors: isCorrect ?
                                                            [.green.opacity(0.12), .mint.opacity(0.06)] :
                                                            [.red.opacity(0.12), .orange.opacity(0.06)],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: isCorrect ?
                                                            [.green.opacity(0.3), .mint.opacity(0.2)] :
                                                            [.red.opacity(0.3), .orange.opacity(0.2)],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    ),
                                                    lineWidth: 1
                                                )
                                        )
                                        .transition(.scale.combined(with: .opacity))
                                    }
                                }
                            }

                            Spacer()
                        }
                    }
                }
            }

            if showCorrectAnimation {
                CorrectAnswerAnimation()
                    .transition(.scale.combined(with: .opacity))
            }

            if showWrongAnimation {
                WrongAnswerAnimation()
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .navigationTitle("判断题")
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
                sessionType: .trueFalse,
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

    private func handleAnswerSelection(_ answer: Bool) {
        selectedAnswer = answer
        answerSubmitted = true

        let answerStr = answer ? "True" : "False"
        viewModel.submitAnswer(answerStr)

        let isCorrect = answer == viewModel.currentQuestion?.correctBoolAnswer

        if isCorrect {
            withAnimation {
                showCorrectAnimation = true
            }
        } else {
            withAnimation {
                showWrongAnimation = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showCorrectAnimation = false
                showWrongAnimation = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                selectedAnswer = nil
                answerSubmitted = false
                viewModel.nextQuestion()

                if viewModel.testCompleted {
                    viewModel.saveSession(modelContext: modelContext, sessionType: .trueFalse)
                    navigateToResults = true
                }
            }
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
            testType: .trueFalse,
            timeLimit: timeLimit
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            viewModel.startTimer()
        }
    }
}

struct TrueFalseButton: View {
    let title: String
    let isSelected: Bool
    let state: AnswerState
    let isCorrectAnswer: Bool
    let action: () -> Void

    private var buttonGradient: LinearGradient {
        switch state {
        case .normal:
            return LinearGradient(
                colors: [Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .selected:
            return LinearGradient(
                colors: isCorrectAnswer ?
                    [Color.green.opacity(0.18), Color.green.opacity(0.1)] :
                    [Color.red.opacity(0.18), Color.red.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .correct:
            return LinearGradient(
                colors: [Color.green.opacity(0.18), Color.mint.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .wrong:
            return LinearGradient(
                colors: [Color.red.opacity(0.18), Color.orange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .disabled:
            return LinearGradient(
                colors: [Color.gray.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var borderGradient: LinearGradient {
        switch state {
        case .normal:
            return LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
        case .selected:
            return LinearGradient(
                colors: isCorrectAnswer ? [.green, .mint] : [.red, .orange],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .correct:
            return LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
        case .wrong:
            return LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
        case .disabled:
            return LinearGradient(colors: [Color.gray.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
        }
    }

    private var iconColor: Color {
        switch state {
        case .correct: return .green
        case .wrong: return .red
        case .selected: return isCorrectAnswer ? .green : .red
        default: return .gray
        }
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.impact()
            action()
        }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [iconColor.opacity(0.2), .clear],
                                center: .center,
                                startRadius: 5,
                                endRadius: 25
                            )
                        )
                        .frame(width: 50, height: 50)

                    Circle()
                        .stroke(
                            state == .normal ?
                                LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .top, endPoint: .bottom) :
                                LinearGradient(colors: isCorrectAnswer ? [.green, .mint] : [.red, .orange], startPoint: .top, endPoint: .bottom),
                            lineWidth: state == .normal ? 2 : 0
                        )
                        .frame(width: 26, height: 26)

                    Image(systemName: isCorrectAnswer ? "checkmark" : "xmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: isCorrectAnswer ? [.green, .mint] : [.red, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(state == .disabled ? .secondary : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))

                    RoundedRectangle(cornerRadius: 16)
                        .fill(buttonGradient)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderGradient, lineWidth: state == .normal ? 1.5 : 2.5)
            )
            .shadow(
                color: state == .correct ? .green.opacity(0.25) :
                       state == .wrong ? .red.opacity(0.25) :
                       state == .selected ? iconColor.opacity(0.2) : .black.opacity(0.03),
                radius: state == .normal ? 4 : 10,
                y: state == .normal ? 2 : 4
            )
        }
        .buttonStyle(TrueFalseButtonStyle())
        .disabled(state == .disabled || state == .correct || state == .wrong)
    }
}

struct TrueFalseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        TrueFalseView(wordCount: 10, category: .all)
            .modelContainer(for: [Word.self, StudySession.self, UserSettings.self])
    }
}
