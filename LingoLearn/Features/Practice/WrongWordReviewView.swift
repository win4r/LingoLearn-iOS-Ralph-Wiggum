//
//  WrongWordReviewView.swift
//  LingoLearn
//
//  A view for reviewing words that were answered incorrectly in a test
//

import SwiftUI
import SwiftData

struct WrongWordReviewView: View {
    let wrongWords: [Word]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var showCompletion = false
    @State private var appeared = false
    @State private var speechRate: SpeechRate = .normal
    @StateObject private var speechService = SpeechService.shared

    private var currentWord: Word? {
        guard currentIndex < wrongWords.count else { return nil }
        return wrongWords[currentIndex]
    }

    private var hasMoreWords: Bool {
        currentIndex < wrongWords.count
    }

    private var progress: CGFloat {
        guard wrongWords.count > 0 else { return 0 }
        return CGFloat(currentIndex + 1) / CGFloat(wrongWords.count)
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Enhanced progress header
                VStack(spacing: 12) {
                    HStack {
                        // Progress counter
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.orange.opacity(0.2), .yellow.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 32, height: 32)

                                Image(systemName: "arrow.counterclockwise")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.orange, .yellow],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("复习进度")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(currentIndex + 1) / \(wrongWords.count)")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .contentTransition(.numericText())
                            }
                        }

                        Spacer()

                        // Wrong count badge
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                            Text("\(wrongWords.count)个错题")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .orange.opacity(0.3), radius: 4, y: 2)
                    }

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [.orange, .yellow],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * progress, height: 6)
                                .animation(.easeInOut(duration: 0.3), value: progress)
                        }
                    }
                    .frame(height: 6)
                }
                .padding(.horizontal)
                .padding(.top)

                if showCompletion {
                    Spacer()
                    completionView
                    Spacer()
                } else if let word = currentWord {
                    // Card
                    ReviewCardView(
                        word: word,
                        isFlipped: $isFlipped,
                        onSpeak: {
                            speechService.speak(text: word.english, rate: speechRate.rate)
                        }
                    )
                    .padding(.horizontal)

                    Spacer()

                    // Enhanced action buttons
                    HStack(spacing: 32) {
                        // Previous button
                        Button(action: previousWord) {
                            ZStack {
                                Circle()
                                    .fill(
                                        currentIndex > 0 ?
                                            LinearGradient(colors: [.blue.opacity(0.15), .cyan.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                            LinearGradient(colors: [.gray.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                                    )
                                    .frame(width: 60, height: 60)

                                Image(systemName: "chevron.left")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(
                                        currentIndex > 0 ?
                                            LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom) :
                                            LinearGradient(colors: [.gray.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                                    )
                            }
                            .shadow(color: currentIndex > 0 ? .blue.opacity(0.2) : .clear, radius: 8, y: 4)
                        }
                        .disabled(currentIndex == 0)
                        .buttonStyle(ReviewActionButtonStyle())

                        // Flip button
                        Button(action: {
                            HapticManager.shared.impact()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                isFlipped.toggle()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.purple.opacity(0.2), .pink.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 72, height: 72)

                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.purple, .pink],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 60, height: 60)
                                    .shadow(color: .purple.opacity(0.4), radius: 8, y: 4)

                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(ReviewActionButtonStyle())

                        // Next button
                        Button(action: nextWord) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.green.opacity(0.15), .mint.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 60, height: 60)

                                Image(systemName: "chevron.right")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.green, .mint],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                            .shadow(color: .green.opacity(0.2), radius: 8, y: 4)
                        }
                        .buttonStyle(ReviewActionButtonStyle())
                    }
                    .padding(.bottom, 16)

                    // Enhanced instructions
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.tap.fill")
                                .font(.caption2)
                                .foregroundColor(.purple)
                            Text("点击翻转")
                                .font(.caption)
                        }

                        Text("·")
                            .foregroundStyle(.secondary)

                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.caption2)
                                .foregroundColor(.accentColor)
                            Text("切换单词")
                                .font(.caption)
                        }
                    }
                    .foregroundStyle(.secondary)
                    .padding(.bottom)
                } else {
                    Spacer()
                    Text("没有错题需要复习")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .navigationTitle("错题复习")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadSpeechRate()
        }
    }

    private func loadSpeechRate() {
        let descriptor = FetchDescriptor<UserSettings>()
        if let settings = try? modelContext.fetch(descriptor).first {
            speechRate = settings.speechRate
        }
    }

    private var completionView: some View {
        VStack(spacing: 28) {
            // Celebration icon with glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.green.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.15), .mint.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .green.opacity(0.4), radius: 10)
            }

            VStack(spacing: 8) {
                Text("复习完成!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text("你已复习了全部\(wrongWords.count)个错题")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 14) {
                Button(action: {
                    HapticManager.shared.impact()
                    currentIndex = 0
                    isFlipped = false
                    showCompletion = false
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.body.weight(.semibold))
                        Text("再复习一次")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .orange.opacity(0.3), radius: 8, y: 4)
                }

                Button(action: {
                    HapticManager.shared.success()
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.body.weight(.semibold))
                        Text("完成")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .green.opacity(0.3), radius: 8, y: 4)
                }
            }
            .buttonStyle(ReviewActionButtonStyle())
            .padding(.horizontal, 40)
            .padding(.top, 12)
        }
    }

    private func nextWord() {
        isFlipped = false
        if currentIndex < wrongWords.count - 1 {
            withAnimation {
                currentIndex += 1
            }
        } else {
            withAnimation {
                showCompletion = true
            }
        }
    }

    private func previousWord() {
        guard currentIndex > 0 else { return }
        isFlipped = false
        withAnimation {
            currentIndex -= 1
        }
    }
}

// MARK: - Button Style

private struct ReviewActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Review Card View

struct ReviewCardView: View {
    let word: Word
    @Binding var isFlipped: Bool
    let onSpeak: () -> Void

    @State private var speakerPulse = false

    var body: some View {
        ZStack {
            // Back of card (Chinese meaning)
            backCardContent
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))

            // Front of card (English word)
            frontCardContent
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        }
        .frame(height: 400)
        .onTapGesture {
            HapticManager.shared.impact()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isFlipped.toggle()
            }
        }
    }

    private var frontCardContent: some View {
        VStack(spacing: 18) {
            Spacer()

            // Wrong indicator badge
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                Text("需要复习")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: .orange.opacity(0.3), radius: 4, y: 2)

            Text(word.english)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.primary, .primary.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .multilineTextAlignment(.center)

            Text(word.phonetic)
                .font(.system(size: 18, design: .monospaced))
                .foregroundStyle(.secondary)

            // Enhanced speaker button
            Button(action: {
                speakerPulse = true
                onSpeak()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    speakerPulse = false
                }
            }) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.blue.opacity(0.2), .clear],
                                center: .center,
                                startRadius: 15,
                                endRadius: 30
                            )
                        )
                        .frame(width: 56, height: 56)
                        .scaleEffect(speakerPulse ? 1.3 : 1.0)
                        .opacity(speakerPulse ? 0 : 0.5)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.15), .cyan.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }

            Spacer()

            // Flip hint
            HStack(spacing: 6) {
                Image(systemName: "hand.tap.fill")
                    .font(.caption2)
                Text("点击翻转查看释义")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            .padding(.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(.systemBackground))

                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [.orange.opacity(0.08), .yellow.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    LinearGradient(
                        colors: [.orange.opacity(0.4), .yellow.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: .orange.opacity(0.15), radius: 15, y: 8)
    }

    private var backCardContent: some View {
        VStack(spacing: 18) {
            Spacer()

            Text(word.chinese)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.primary, .primary.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .multilineTextAlignment(.center)

            Text(word.partOfSpeech)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .clipShape(Capsule())

            if !word.exampleSentence.isEmpty {
                VStack(spacing: 10) {
                    HStack(spacing: 4) {
                        Image(systemName: "text.quote")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("例句")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.secondary)

                    Text(word.exampleSentence)
                        .font(.body)
                        .italic()
                        .multilineTextAlignment(.center)

                    Text(word.exampleTranslation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [.orange.opacity(0.08), .yellow.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .padding(.horizontal)
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "hand.tap.fill")
                    .font(.caption2)
                Text("点击翻转查看单词")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            .padding(.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(.systemBackground))

                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.06), .pink.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    LinearGradient(
                        colors: [.purple.opacity(0.3), .pink.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: .purple.opacity(0.12), radius: 15, y: 8)
    }
}

#Preview {
    NavigationStack {
        WrongWordReviewView(wrongWords: [
            Word(
                english: "Abandon",
                chinese: "放弃",
                phonetic: "/əˈbændən/",
                partOfSpeech: "verb",
                exampleSentence: "Don't abandon your dreams.",
                exampleTranslation: "不要放弃你的梦想。",
                category: .cet4,
                difficulty: 2
            ),
            Word(
                english: "Brilliant",
                chinese: "杰出的",
                phonetic: "/ˈbrɪliənt/",
                partOfSpeech: "adjective",
                exampleSentence: "She had a brilliant idea.",
                exampleTranslation: "她有一个绝妙的主意。",
                category: .cet4,
                difficulty: 2
            )
        ])
    }
}
