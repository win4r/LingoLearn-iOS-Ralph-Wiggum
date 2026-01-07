//
//  DifficultWordsCard.swift
//  LingoLearn
//
//  Shows words the user struggles with most
//

import SwiftUI
import SwiftData

struct DifficultWordsCard: View {
    @Environment(\.modelContext) private var modelContext
    @State private var difficultWords: [DifficultWord] = []
    @State private var showContent = false
    @State private var expandedWordId: String?

    struct DifficultWord: Identifiable {
        var id: String { word.id.uuidString }
        let word: Word
        let incorrectCount: Int
        let accuracy: Double

        var difficultyLevel: DifficultyLevel {
            if accuracy < 0.3 { return .veryHard }
            else if accuracy < 0.5 { return .hard }
            else { return .challenging }
        }
    }

    enum DifficultyLevel {
        case veryHard, hard, challenging

        var color: Color {
            switch self {
            case .veryHard: return .red
            case .hard: return .orange
            case .challenging: return .yellow
            }
        }

        var label: String {
            switch self {
            case .veryHard: return "困难"
            case .hard: return "较难"
            case .challenging: return "需加强"
            }
        }

        var icon: String {
            switch self {
            case .veryHard: return "exclamationmark.triangle.fill"
            case .hard: return "exclamationmark.circle.fill"
            case .challenging: return "info.circle.fill"
            }
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.red.opacity(0.3), .clear],
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 16
                                )
                            )
                            .frame(width: 28, height: 28)

                        Image(systemName: "brain.head.profile")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.red, .orange],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    Text("需要关注")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                if !difficultWords.isEmpty {
                    Text("\(difficultWords.count)个单词")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.1))
                        )
                }
            }

            if difficultWords.isEmpty {
                // Empty state
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.green.opacity(0.15), .mint.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)

                        Image(systemName: "checkmark.seal.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    Text("表现很棒！")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("目前没有需要特别关注的单词")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                // Difficult words list
                VStack(spacing: 10) {
                    ForEach(difficultWords.prefix(5)) { item in
                        DifficultWordRow(
                            item: item,
                            isExpanded: expandedWordId == item.id,
                            onTap: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if expandedWordId == item.id {
                                        expandedWordId = nil
                                    } else {
                                        expandedWordId = item.id
                                    }
                                }
                            }
                        )
                    }
                }

                // Tip
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)

                    Text("点击单词查看详情，多复习可提高记忆")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: difficultWords.isEmpty
                            ? [.green.opacity(0.2), .mint.opacity(0.15)]
                            : [.red.opacity(0.2), .orange.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 10)
        .onAppear {
            loadDifficultWords()
            withAnimation(.easeOut(duration: 0.4).delay(0.35)) {
                showContent = true
            }
        }
    }

    private func loadDifficultWords() {
        // Fetch words that have been studied (have sessions)
        let descriptor = FetchDescriptor<Word>(
            predicate: #Predicate<Word> { $0.timesStudied > 0 },
            sortBy: [SortDescriptor(\.timesCorrect, order: .forward)]
        )

        guard let words: [Word] = try? modelContext.fetch(descriptor) else { return }

        // Calculate accuracy and filter difficult words
        var difficult: [DifficultWord] = []

        for word in words {
            guard word.timesStudied >= 2 else { continue } // Need at least 2 attempts

            let accuracy = Double(word.timesCorrect) / Double(word.timesStudied)
            let incorrectCount = word.timesStudied - word.timesCorrect

            // Include if accuracy is below 60%
            if accuracy < 0.6 {
                difficult.append(DifficultWord(
                    word: word,
                    incorrectCount: incorrectCount,
                    accuracy: accuracy
                ))
            }
        }

        // Sort by accuracy (lowest first)
        difficult.sort { $0.accuracy < $1.accuracy }

        difficultWords = difficult
    }
}

// MARK: - Difficult Word Row

private struct DifficultWordRow: View {
    let item: DifficultWordsCard.DifficultWord
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            HStack(spacing: 12) {
                // Difficulty indicator
                ZStack {
                    Circle()
                        .fill(item.difficultyLevel.color.opacity(0.15))
                        .frame(width: 32, height: 32)

                    Image(systemName: item.difficultyLevel.icon)
                        .font(.caption)
                        .foregroundStyle(item.difficultyLevel.color)
                }

                // Word info
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.word.english)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(item.word.chinese)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Stats
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("\(Int(item.accuracy * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(item.difficultyLevel.color)
                    }

                    Text("错\(item.incorrectCount)次")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // Expand indicator
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
            .onTapGesture {
                HapticManager.shared.selection()
                onTap()
            }

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()

                    // Phonetic
                    if !item.word.phonetic.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "speaker.wave.2")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(item.word.phonetic)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Example sentence
                    if !item.word.exampleSentence.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("例句")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)

                            Text(item.word.exampleSentence)
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                    }

                    // Statistics detail
                    HStack(spacing: 16) {
                        StatBadge(
                            label: "尝试",
                            value: "\(item.word.timesStudied)次",
                            color: .blue
                        )

                        StatBadge(
                            label: "正确",
                            value: "\(item.word.timesCorrect)次",
                            color: .green
                        )

                        StatBadge(
                            label: "等级",
                            value: item.difficultyLevel.label,
                            color: item.difficultyLevel.color
                        )

                        Spacer()
                    }

                    // Tip
                    HStack(spacing: 6) {
                        Image(systemName: "brain")
                            .font(.caption2)
                        Text("建议多复习此单词")
                            .font(.caption2)
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.1))
                    )
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Stat Badge

private struct StatBadge: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(color)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    DifficultWordsCard()
        .padding()
        .background(Color(.systemGroupedBackground))
        .modelContainer(for: Word.self)
}
