//
//  QuickReviewWidget.swift
//  LingoLearn
//
//  Quick word review directly on the home screen
//

import SwiftUI
import SwiftData

struct QuickReviewWidget: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentWord: Word?
    @State private var isFlipped = false
    @State private var showContent = false
    @State private var cardOffset: CGSize = .zero
    @State private var wordQueue: [Word] = []

    private let speechService = SpeechService.shared

    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.mint.opacity(0.3), .clear],
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 16
                                )
                            )
                            .frame(width: 28, height: 28)

                        Image(systemName: "bolt.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.mint, .green],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    Text("快速复习")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                // Refresh button
                Button(action: loadNextWord) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(6)
                        .background(Circle().fill(Color(.secondarySystemGroupedBackground)))
                }
            }

            // Word card
            if let word = currentWord {
                QuickReviewCard(
                    word: word,
                    isFlipped: $isFlipped,
                    offset: $cardOffset,
                    onKnow: { handleResponse(known: true) },
                    onDontKnow: { handleResponse(known: false) },
                    onSpeak: { speechService.speak(text: word.english) }
                )
            } else {
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

                    Text("暂无需要复习的单词")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }

            // Instructions
            if currentWord != nil {
                HStack(spacing: 16) {
                    Label("点击翻转", systemImage: "hand.tap")
                    Label("左右滑动作答", systemImage: "arrow.left.arrow.right")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
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
                        colors: [.mint.opacity(0.2), .green.opacity(0.15)],
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
            loadWords()
            withAnimation(.easeOut(duration: 0.4).delay(0.55)) {
                showContent = true
            }
        }
    }

    private func loadWords() {
        let today = Date()
        var descriptor = FetchDescriptor<Word>(
            predicate: #Predicate<Word> { word in
                word.nextReviewDate != nil && word.nextReviewDate! <= today
            },
            sortBy: [SortDescriptor(\.nextReviewDate, order: .forward)]
        )
        descriptor.fetchLimit = 10

        if let words = try? modelContext.fetch(descriptor), !words.isEmpty {
            wordQueue = words
            currentWord = wordQueue.first
        }
    }

    private func loadNextWord() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isFlipped = false
            cardOffset = .zero
        }

        if !wordQueue.isEmpty {
            wordQueue.removeFirst()
        }

        if wordQueue.isEmpty {
            loadWords()
        }

        currentWord = wordQueue.first
    }

    private func handleResponse(known: Bool) {
        guard let word = currentWord else { return }

        // Update word stats
        word.timesStudied += 1
        if known {
            word.timesCorrect += 1
            // Schedule next review further out
            word.nextReviewDate = Calendar.current.date(byAdding: .day, value: word.interval + 1, to: Date())
        } else {
            // Schedule sooner review
            word.nextReviewDate = Calendar.current.date(byAdding: .hour, value: 4, to: Date())
        }
        word.lastStudiedDate = Date()

        try? modelContext.save()

        HapticManager.shared.impact()

        // Load next word
        loadNextWord()
    }
}

// MARK: - Quick Review Card

private struct QuickReviewCard: View {
    let word: Word
    @Binding var isFlipped: Bool
    @Binding var offset: CGSize
    let onKnow: () -> Void
    let onDontKnow: () -> Void
    let onSpeak: () -> Void

    @State private var rotation: Double = 0

    private let swipeThreshold: CGFloat = 80

    var body: some View {
        ZStack {
            // Back (Chinese)
            cardBack
                .rotation3DEffect(.degrees(isFlipped ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 1 : 0)

            // Front (English)
            cardFront
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 0 : 1)
        }
        .offset(offset)
        .rotationEffect(.degrees(rotation))
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = value.translation
                    rotation = Double(value.translation.width / 30)
                }
                .onEnded { value in
                    if value.translation.width > swipeThreshold {
                        // Right swipe - know
                        withAnimation(.easeOut(duration: 0.2)) {
                            offset = CGSize(width: 300, height: 0)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onKnow()
                        }
                    } else if value.translation.width < -swipeThreshold {
                        // Left swipe - don't know
                        withAnimation(.easeOut(duration: 0.2)) {
                            offset = CGSize(width: -300, height: 0)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onDontKnow()
                        }
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            offset = .zero
                            rotation = 0
                        }
                    }
                }
        )
        .onTapGesture {
            HapticManager.shared.impact()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isFlipped.toggle()
            }
        }
        .overlay(swipeIndicator)
    }

    private var cardFront: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(word.english)
                    .font(.title3)
                    .fontWeight(.bold)

                Text(word.phonetic)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onSpeak) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                    )
            }
        }
        .padding(16)
        .frame(height: 80)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.blue.opacity(0.1), lineWidth: 1)
        )
    }

    private var cardBack: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(word.chinese)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(word.partOfSpeech)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Mastery indicator
            Image(systemName: word.masteryLevel.icon)
                .font(.subheadline)
                .foregroundStyle(word.masteryLevel.color)
                .padding(10)
                .background(
                    Circle()
                        .fill(word.masteryLevel.color.opacity(0.1))
                )
        }
        .padding(16)
        .frame(height: 80)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.purple.opacity(0.1), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var swipeIndicator: some View {
        if offset.width > 30 {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.green.opacity(0.2))
                .overlay(
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.green)
                            .padding(.trailing, 20)
                    }
                )
        } else if offset.width < -30 {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.red.opacity(0.2))
                .overlay(
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.red)
                            .padding(.leading, 20)
                        Spacer()
                    }
                )
        }
    }
}

#Preview {
    QuickReviewWidget()
        .padding()
        .background(Color(.systemGroupedBackground))
        .modelContainer(for: Word.self)
}
