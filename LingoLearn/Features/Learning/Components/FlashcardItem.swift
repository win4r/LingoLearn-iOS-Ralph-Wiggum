//
//  FlashcardItem.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI

struct FlashcardItem: View {
    let word: Word
    let onSwipe: (SwipeDirection) -> Void
    var autoPlayPronunciation: Bool = false
    var speechRate: SpeechRate = .normal

    @State private var isFlipped = false
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var hasAutoPlayed = false
    @State private var appeared = false
    @State private var speakerPulse = false
    @State private var shimmerOffset: CGFloat = -200
    private let speechService = SpeechService.shared

    private let swipeThreshold: CGFloat = 100

    private func formatNextReview(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInTomorrow(date) {
            return "明天"
        } else {
            let days = calendar.dateComponents([.day], from: now, to: date).day ?? 0
            if days < 0 {
                return "已过期"
            } else if days <= 7 {
                return "\(days)天后"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "M月d日"
                return formatter.string(from: date)
            }
        }
    }

    private var cardGradientFront: [Color] {
        [Color(.systemBackground), Color.blue.opacity(0.08), Color.cyan.opacity(0.05)]
    }

    private var cardGradientBack: [Color] {
        [Color(.systemBackground), Color.purple.opacity(0.08), Color.pink.opacity(0.05)]
    }

    var body: some View {
        ZStack {
            // Card Back (Chinese side)
            cardBack
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : 180),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(isFlipped ? 1 : 0)

            // Card Front (English side)
            cardFront
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(isFlipped ? 0 : 1)
        }
        .frame(width: 320, height: 450)
        .offset(offset)
        .rotationEffect(.degrees(rotation))
        .overlay(swipeOverlay)
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = value.translation
                    rotation = Double(value.translation.width / 20)
                }
                .onEnded { value in
                    handleSwipeEnd(value: value)
                }
        )
        .onTapGesture {
            HapticManager.shared.impact()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isFlipped.toggle()
            }
        }
        .onAppear {
            // Animate entry
            withAnimation(.easeOut(duration: 0.4)) {
                appeared = true
            }

            // Start shimmer animation
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                shimmerOffset = 400
            }

            // Auto-play pronunciation when card appears (only once)
            if autoPlayPronunciation && !hasAutoPlayed {
                hasAutoPlayed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    speechService.speak(text: word.english, rate: speechRate.rate)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isFlipped
            ? "单词卡片,\(word.english),意思是\(word.chinese)"
            : "单词卡片,\(word.english),\(word.phonetic)")
        .accessibilityHint("双击翻转卡片,向右滑动表示认识,向左滑动表示不认识,向上滑动收藏,向下滑动表示太简单")
        .accessibilityAddTraits(.isButton)
    }

    private var cardFront: some View {
        ZStack {
            // Shimmer effect
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.15), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 80)
                .offset(x: shimmerOffset)
                .mask(RoundedRectangle(cornerRadius: 20))

            VStack(spacing: 20) {
                Spacer()

                // Category and difficulty badges
                HStack(spacing: 8) {
                    // Category badge
                    HStack(spacing: 6) {
                        Image(systemName: "book.closed.fill")
                            .font(.caption2)
                        Text(word.category.rawValue)
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: .blue.opacity(0.3), radius: 4, y: 2)

                    // Difficulty stars
                    HStack(spacing: 2) {
                        ForEach(1...3, id: \.self) { star in
                            Image(systemName: star <= word.difficulty ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundStyle(
                                    star <= word.difficulty
                                        ? LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                                        : LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                                )
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : -10)

                // Word
                Text(word.english)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.05), radius: 2, y: 1)

                // Phonetic
                Text(word.phonetic)
                    .font(.system(size: 20, design: .monospaced))
                    .foregroundStyle(.secondary)

                // Part of Speech with gradient
                Text(word.partOfSpeech)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [.blue.opacity(0.8), .purple.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: .blue.opacity(0.3), radius: 6, y: 3)

                Spacer()

                // Speaker Button with enhanced styling
                Button(action: {
                    speakerPulse = true
                    speechService.speak(text: word.english, language: "en-US", rate: speechRate.rate)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        speakerPulse = false
                    }
                }) {
                    ZStack {
                        // Glow ring
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.blue.opacity(0.2), .clear],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 35
                                )
                            )
                            .frame(width: 60, height: 60)
                            .scaleEffect(speakerPulse ? 1.3 : 1.0)
                            .opacity(speakerPulse ? 0 : 0.5)

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.15), .blue.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)

                        Image(systemName: speechService.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .symbolEffect(.variableColor, options: .repeating.speed(0.5), value: speechService.isSpeaking)
                    }
                }
                .buttonStyle(FlashcardButtonStyle())

                // Flip hint
                HStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill")
                        .font(.caption2)
                    Text("点击翻转查看释义")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
            }
            .padding()
        }
        .frame(width: 320, height: 450)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))

                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: cardGradientFront,
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
                        colors: [.blue.opacity(0.2), .cyan.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .blue.opacity(0.15), radius: 20, y: 8)
    }

    private var cardBack: some View {
        VStack(spacing: 16) {
            Spacer()

            // Study progress indicators
            HStack(spacing: 16) {
                // Times studied
                HStack(spacing: 4) {
                    Image(systemName: "book.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    Text("\(word.timesStudied)次")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())

                // Accuracy
                if word.timesStudied > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "percent")
                            .font(.caption2)
                            .foregroundStyle(.green)
                        Text("\(Int(Double(word.timesCorrect) / Double(word.timesStudied) * 100))%")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .clipShape(Capsule())
                }

                // Mastery level
                HStack(spacing: 4) {
                    Image(systemName: word.masteryLevel.icon)
                        .font(.caption2)
                        .foregroundStyle(word.masteryLevel.color)
                    Text(word.masteryLevel.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(word.masteryLevel.color.opacity(0.1))
                .clipShape(Capsule())
            }

            // Next review date (if scheduled)
            if let nextReview = word.nextReviewDate {
                HStack(spacing: 4) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.caption2)
                        .foregroundStyle(.purple)
                    Text("下次复习: \(formatNextReview(nextReview))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Chinese Meaning
            Text(word.chinese)
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.primary, .primary.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .multilineTextAlignment(.center)

            // Pronunciation practice buttons
            HStack(spacing: 12) {
                // Normal speed button
                Button(action: {
                    HapticManager.shared.impact()
                    SoundService.shared.playTap()
                    speechService.speak(text: word.english, rate: speechRate.rate)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: speechService.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                            .font(.subheadline)
                            .symbolEffect(.variableColor, options: .repeating.speed(0.5), value: speechService.isSpeaking)
                        Text("正常")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: .blue.opacity(0.3), radius: 6, y: 3)
                }
                .buttonStyle(FlashcardButtonStyle())

                // Slow speed button for practice
                Button(action: {
                    HapticManager.shared.impact()
                    SoundService.shared.playTap()
                    speechService.speak(text: word.english, rate: SpeechRate.slow.rate)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "tortoise.fill")
                            .font(.subheadline)
                        Text("慢速")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: .orange.opacity(0.3), radius: 6, y: 3)
                }
                .buttonStyle(FlashcardButtonStyle())
            }

            // Decorative divider
            HStack(spacing: 8) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .purple.opacity(0.5)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 60, height: 2)

                Circle()
                    .fill(LinearGradient(colors: [.purple, .pink], startPoint: .top, endPoint: .bottom))
                    .frame(width: 6, height: 6)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.5), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 60, height: 2)
            }
            .padding(.vertical, 8)

            // Example Sentence with enhanced styling
            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "text.quote")
                        .font(.caption)
                        .foregroundStyle(
                            LinearGradient(colors: [.purple, .pink], startPoint: .top, endPoint: .bottom)
                        )
                    Text("例句")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }

                Text(word.exampleSentence)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text(word.exampleTranslation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.1), .pink.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        LinearGradient(
                            colors: [.purple.opacity(0.2), .pink.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )

            Spacer()

            // Mastery Level Badge and Favorite
            HStack(spacing: 12) {
                MasteryBadge(level: word.masteryLevel)

                if word.isFavorite {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.yellow.opacity(0.3), .clear],
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 18
                                )
                            )
                            .frame(width: 36, height: 36)

                        Image(systemName: "heart.fill")
                            .font(.title3)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: .orange.opacity(0.5), radius: 4)
                    }
                }
            }
            .padding(.bottom, 8)
        }
        .padding()
        .frame(width: 320, height: 450)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))

                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: cardGradientBack,
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
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .purple.opacity(0.15), radius: 20, y: 8)
    }

    private var swipeOverlay: some View {
        Group {
            if offset.width > 50 {
                // Right swipe - Know it
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.4), Color.green.opacity(0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "hand.thumbsup.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, .green.opacity(0.7)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: .green.opacity(0.5), radius: 10)
                            Text("认识")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    )
                    .transition(.opacity)
            } else if offset.width < -50 {
                // Left swipe - Don't know
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.red.opacity(0.2), Color.red.opacity(0.4)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "hand.thumbsdown.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.red, .red.opacity(0.7)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: .red.opacity(0.5), radius: 10)
                            Text("不认识")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                    )
                    .transition(.opacity)
            } else if offset.height < -50 {
                // Up swipe - Favorite
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: .orange.opacity(0.5), radius: 10)
                            Text("收藏")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                    )
                    .transition(.opacity)
            } else if offset.height > 50 {
                // Down swipe - Easy/Perfect recall
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.mint.opacity(0.3), Color.cyan.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.mint, .cyan],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: .cyan.opacity(0.5), radius: 10)
                            Text("太简单")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.mint, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                    )
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: offset.width)
        .animation(.easeInOut(duration: 0.2), value: offset.height)
    }

    private func handleSwipeEnd(value: DragGesture.Value) {
        let horizontalAmount = value.translation.width
        let verticalAmount = value.translation.height

        if abs(horizontalAmount) > abs(verticalAmount) {
            // Horizontal swipe
            if horizontalAmount > swipeThreshold {
                // Right swipe - Know it
                HapticManager.shared.success()
                withAnimation {
                    offset = CGSize(width: 500, height: 0)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onSwipe(.right)
                    resetCard()
                }
            } else if horizontalAmount < -swipeThreshold {
                // Left swipe - Don't know
                HapticManager.shared.warning()
                withAnimation {
                    offset = CGSize(width: -500, height: 0)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onSwipe(.left)
                    resetCard()
                }
            } else {
                resetCard()
            }
        } else {
            // Vertical swipe
            if verticalAmount < -swipeThreshold {
                // Up swipe - Favorite
                HapticManager.shared.impact()
                withAnimation {
                    offset = CGSize(width: 0, height: -500)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onSwipe(.up)
                    resetCard()
                }
            } else if verticalAmount > swipeThreshold {
                // Down swipe - Easy/Perfect recall
                HapticManager.shared.success()
                withAnimation {
                    offset = CGSize(width: 0, height: 500)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onSwipe(.down)
                    resetCard()
                }
            } else {
                resetCard()
            }
        }
    }

    private func resetCard() {
        withAnimation(.spring()) {
            offset = .zero
            rotation = 0
            isFlipped = false
        }
    }
}

struct MasteryBadge: View {
    let level: MasteryLevel

    @State private var glowOpacity: Double = 0
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 6) {
            // Icon with glow for mastered
            ZStack {
                if level == .mastered {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white.opacity(0.4), .clear],
                                center: .center,
                                startRadius: 2,
                                endRadius: 10
                            )
                        )
                        .frame(width: 20, height: 20)
                        .opacity(glowOpacity)
                }

                Image(systemName: iconName)
                    .font(.caption.weight(.semibold))
                    .symbolEffect(.bounce, options: .speed(0.5), value: level == .mastered)
            }

            Text(level.rawValue)
                .font(.caption)
                .fontWeight(.bold)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            ZStack {
                // Main gradient
                Capsule()
                    .fill(backgroundGradient)

                // Shimmer overlay for mastered
                if level == .mastered {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.2), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(glowOpacity * 0.5)
                }
            }
        )
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .white.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: shadowColor.opacity(0.4), radius: 6, y: 3)
        .scaleEffect(appeared ? 1 : 0.8)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                appeared = true
            }

            if level == .mastered {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowOpacity = 1.0
                }
            }
        }
    }

    private var iconName: String {
        switch level {
        case .new:
            return "sparkle"
        case .learning:
            return "book.fill"
        case .reviewing:
            return "arrow.clockwise"
        case .mastered:
            return "star.fill"
        }
    }

    private var backgroundGradient: LinearGradient {
        switch level {
        case .new:
            return LinearGradient(colors: [.gray, .gray.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .learning:
            return LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .reviewing:
            return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .mastered:
            return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var shadowColor: Color {
        switch level {
        case .new:
            return .gray
        case .learning:
            return .orange
        case .reviewing:
            return .blue
        case .mastered:
            return .green
        }
    }
}

// MARK: - Button Style

private struct FlashcardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    FlashcardItem(
        word: Word(
            english: "Hello",
            chinese: "你好",
            phonetic: "/həˈloʊ/",
            partOfSpeech: "noun",
            exampleSentence: "Hello, how are you?",
            exampleTranslation: "你好,你好吗?",
            category: .cet4,
            difficulty: 1
        ),
        onSwipe: { _ in }
    )
}
