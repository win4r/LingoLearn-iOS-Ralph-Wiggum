//
//  WordOfDayCard.swift
//  LingoLearn
//
//  Word of the day card for home screen
//

import SwiftUI
import SwiftData

struct WordOfDayCard: View {
    @Environment(\.modelContext) private var modelContext
    @State private var word: Word?
    @State private var showContent = false
    @State private var isFlipped = false
    @StateObject private var speechService = SpeechService.shared

    var body: some View {
        Group {
            if let word = word {
                wordCard(for: word)
            }
        }
        .onAppear {
            loadWordOfDay()
        }
    }

    @ViewBuilder
    private func wordCard(for word: Word) -> some View {
            VStack(spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                        Text("今日单词")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button(action: {
                        HapticManager.shared.impact()
                        speechService.speak(text: word.english)
                    }) {
                        Image(systemName: speechService.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                            .symbolEffect(.variableColor.iterative, value: speechService.isSpeaking)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

                Divider()
                    .padding(.horizontal, 16)

                // Card content
                VStack(spacing: 12) {
                    Text(word.english)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text(word.phonetic)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Tap to reveal
                    if isFlipped {
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Text(word.partOfSpeech)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        LinearGradient(
                                            colors: [.blue, .cyan],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(Capsule())

                                Text(word.chinese)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                            }

                            Text(word.exampleSentence)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    } else {
                        Text("点击查看释义 →")
                            .font(.caption)
                            .foregroundStyle(.blue)
                            .padding(.vertical, 8)
                    }
                }
                .padding(16)
            }
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [.yellow.opacity(0.3), .orange.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
            .onTapGesture {
                HapticManager.shared.impact()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isFlipped.toggle()
                }
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 15)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("今日单词: \(word.english), \(word.phonetic), \(word.chinese)")
            .accessibilityHint("双击查看详情")
    }

    private func loadWordOfDay() {
        // Use the day of year as seed for consistent daily word
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0

        let descriptor = FetchDescriptor<Word>()
        if let allWords = try? modelContext.fetch(descriptor), !allWords.isEmpty {
            // Use modulo to get a consistent word for the day
            let index = dayOfYear % allWords.count
            word = allWords[index]

            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showContent = true
            }
        }
    }
}

#Preview {
    WordOfDayCard()
        .padding()
        .background(Color(.systemGroupedBackground))
        .modelContainer(for: [Word.self])
}
