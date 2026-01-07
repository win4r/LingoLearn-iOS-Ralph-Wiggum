//
//  FlashcardStack.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI

struct FlashcardStack: View {
    let words: [Word]
    let currentIndex: Int
    let onSwipe: (SwipeDirection) -> Void
    var autoPlayPronunciation: Bool = false
    var speechRate: SpeechRate = .normal

    private let maxVisibleCards = 3
    private let cardOffset: CGFloat = 10
    private let cardScale: CGFloat = 0.04

    @State private var appeared = false

    var body: some View {
        ZStack {
            // Background decoration
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentColor.opacity(0.03 - Double(i) * 0.01),
                                Color.accentColor.opacity(0.01)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 320 - CGFloat(i * 20), height: 420 - CGFloat(i * 15))
                    .offset(y: CGFloat(i * 12) + 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(Double(i) * 0.1), value: appeared)
            }

            ForEach(visibleCardIndices.reversed(), id: \.self) { index in
                if index < words.count {
                    FlashcardItem(
                        word: words[index],
                        onSwipe: onSwipe,
                        autoPlayPronunciation: autoPlayPronunciation && index == currentIndex,
                        speechRate: speechRate
                    )
                    .offset(y: offsetForCard(at: index))
                    .scaleEffect(scaleForCard(at: index))
                    .opacity(opacityForCard(at: index))
                    .zIndex(zIndexForCard(at: index))
                    .allowsHitTesting(index == currentIndex)
                    .shadow(
                        color: index == currentIndex ? Color.accentColor.opacity(0.15) : .clear,
                        radius: 20, y: 10
                    )
                }
            }

            // Card count indicator
            if words.count > 1 {
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        ForEach(0..<min(words.count, 5), id: \.self) { i in
                            ZStack {
                                // Glow for current
                                if i == currentIndex {
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [.accentColor.opacity(0.4), .cyan.opacity(0.2)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: 24, height: 10)
                                        .blur(radius: 4)
                                }

                                Capsule()
                                    .fill(
                                        i == currentIndex ?
                                            LinearGradient(
                                                colors: [.accentColor, .cyan.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ) :
                                            LinearGradient(
                                                colors: [Color.gray.opacity(0.25), Color.gray.opacity(0.2)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                    )
                                    .frame(width: i == currentIndex ? 22 : 8, height: 6)
                            }
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
                        }
                        if words.count > 5 {
                            HStack(spacing: 2) {
                                Text("+")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                Text("\(words.count - 5)")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.secondary, .secondary.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        ZStack {
                            Capsule()
                                .fill(.ultraThinMaterial)

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(.systemBackground).opacity(0.8), Color(.systemBackground).opacity(0.6)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
                }
                .padding(.bottom, 8)
            }
        }
        .frame(height: 500)
        .onAppear {
            appeared = true
        }
    }

    private var visibleCardIndices: [Int] {
        let start = currentIndex
        let end = min(currentIndex + maxVisibleCards, words.count)
        return Array(start..<end)
    }

    private func offsetForCard(at index: Int) -> CGFloat {
        let position = index - currentIndex
        return CGFloat(position) * cardOffset
    }

    private func scaleForCard(at index: Int) -> CGFloat {
        let position = index - currentIndex
        return 1.0 - (CGFloat(position) * cardScale)
    }

    private func opacityForCard(at index: Int) -> Double {
        let position = index - currentIndex
        return 1.0 - (Double(position) * 0.15)
    }

    private func zIndexForCard(at index: Int) -> Double {
        return Double(words.count - index)
    }
}

#Preview {
    FlashcardStack(
        words: [
            Word(
                english: "Hello",
                chinese: "你好",
                phonetic: "/həˈloʊ/",
                partOfSpeech: "noun",
                exampleSentence: "Hello, how are you?",
                exampleTranslation: "你好,你好吗?",
                category: .cet4,
                difficulty: 1
            ),
            Word(
                english: "Goodbye",
                chinese: "再见",
                phonetic: "/ɡʊdˈbaɪ/",
                partOfSpeech: "noun",
                exampleSentence: "Goodbye, see you tomorrow.",
                exampleTranslation: "再见,明天见。",
                category: .cet4,
                difficulty: 1
            ),
            Word(
                english: "Thank you",
                chinese: "谢谢",
                phonetic: "/θæŋk juː/",
                partOfSpeech: "phrase",
                exampleSentence: "Thank you for your help.",
                exampleTranslation: "谢谢你的帮助。",
                category: .cet4,
                difficulty: 1
            )
        ],
        currentIndex: 0,
        onSwipe: { _ in }
    )
}
