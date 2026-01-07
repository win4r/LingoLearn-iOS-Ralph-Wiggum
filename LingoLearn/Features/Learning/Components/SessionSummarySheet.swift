//
//  SessionSummarySheet.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI

struct SessionSummarySheet: View {
    let stats: SessionStats
    var newlyUnlockedAchievements: [Achievement] = []
    var dailyGoalReached: Bool = false
    let onContinue: () -> Void
    let onHome: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var iconScale: CGFloat = 0.5
    @State private var showStats = false
    @State private var showAchievements = false
    @State private var showGoalCelebration = false
    @State private var showButtons = false
    @State private var showConfetti = false
    @State private var glowOpacity: Double = 0
    @State private var ringRotation: Double = 0

    private var isExcellent: Bool {
        stats.accuracy >= 0.9
    }

    private var isGood: Bool {
        stats.accuracy >= 0.7
    }

    private var performanceColors: [Color] {
        if isExcellent {
            return [.yellow, .orange]
        } else if isGood {
            return [.green, .mint]
        } else {
            return [.blue, .cyan]
        }
    }

    private var performanceMessage: String {
        if isExcellent {
            return "完美表现！继续保持！"
        } else if isGood {
            return "做得很好！"
        } else {
            return "继续加油！"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 28) {
                    // Success Icon with enhanced decorations
                    ZStack {
                        // Outer rotating ring
                        Circle()
                            .stroke(
                                AngularGradient(
                                    colors: performanceColors + [performanceColors.first ?? .green],
                                    center: .center
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(ringRotation))
                            .opacity(glowOpacity * 0.6)

                        // Glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [performanceColors.first?.opacity(0.3) ?? .clear, .clear],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 70
                                )
                            )
                            .frame(width: 140, height: 140)
                            .opacity(glowOpacity)

                        // Inner circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [performanceColors.first?.opacity(0.15) ?? .clear, performanceColors.last?.opacity(0.08) ?? .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 110, height: 110)

                        Image(systemName: isExcellent ? "star.circle.fill" : (isGood ? "checkmark.seal.fill" : "checkmark.circle.fill"))
                            .font(.system(size: 70))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: performanceColors,
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .symbolEffect(.bounce, value: iconScale == 1.0)
                    }
                    .scaleEffect(iconScale)
                    .padding(.top, 32)

                    // Title
                    VStack(spacing: 8) {
                        Text(isExcellent ? "太棒了!" : (isGood ? "学习完成!" : "继续加油!"))
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text(performanceMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .opacity(iconScale == 1.0 ? 1 : 0)

                    // Stats Cards
                    VStack(spacing: 14) {
                        SummaryStatCard(
                            icon: "book.fill",
                            title: "学习单词",
                            value: "\(stats.totalReviewed)",
                            color: .blue
                        )

                        HStack(spacing: 14) {
                            SummaryStatCard(
                                icon: "checkmark.circle.fill",
                                title: "认识",
                                value: "\(stats.knownCount)",
                                color: .green
                            )

                            SummaryStatCard(
                                icon: "xmark.circle.fill",
                                title: "不认识",
                                value: "\(stats.unknownCount)",
                                color: .red
                            )
                        }

                        SummaryStatCard(
                            icon: "chart.bar.fill",
                            title: "准确率",
                            value: String(format: "%.0f%%", stats.accuracy * 100),
                            color: isGood ? .green : .orange,
                            showProgress: true,
                            progress: stats.accuracy
                        )

                        HStack(spacing: 14) {
                            SummaryStatCard(
                                icon: "clock.fill",
                                title: "学习时长",
                                value: stats.formattedDuration,
                                color: .purple
                            )

                            SummaryStatCard(
                                icon: "hare.fill",
                                title: "学习速度",
                                value: String(format: "%.1f/分钟", stats.wordsPerMinute),
                                color: .cyan
                            )
                        }
                    }
                    .padding(.horizontal)
                    .opacity(showStats ? 1 : 0)
                    .offset(y: showStats ? 0 : 20)

                    // Achievement Unlocks
                    if !newlyUnlockedAchievements.isEmpty {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "trophy.fill")
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.yellow, .orange],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                Text("新成就解锁！")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }

                            ForEach(newlyUnlockedAchievements) { achievement in
                                AchievementUnlockCard(achievement: achievement)
                            }
                        }
                        .padding(.horizontal)
                        .opacity(showAchievements ? 1 : 0)
                        .offset(y: showAchievements ? 0 : 20)
                    }

                    // Daily Goal Celebration
                    if dailyGoalReached {
                        DailyGoalCelebrationCard()
                            .padding(.horizontal)
                            .opacity(showGoalCelebration ? 1 : 0)
                            .offset(y: showGoalCelebration ? 0 : 20)
                    }

                    Spacer()

                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            HapticManager.shared.impact()
                            dismiss()
                            onContinue()
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "book.fill")
                                Text("继续学习")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .cyan.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
                        }
                        .buttonStyle(SummaryButtonStyle())

                        Button(action: {
                            HapticManager.shared.impact()
                            dismiss()
                            onHome()
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "house.fill")
                                Text("返回首页")
                            }
                            .font(.headline)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                        .buttonStyle(SummaryButtonStyle())
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                    .opacity(showButtons ? 1 : 0)
                    .offset(y: showButtons ? 0 : 20)
                }
                .navigationTitle("学习总结")
                .navigationBarTitleDisplayMode(.inline)

                // Confetti for excellent performance
                ConfettiView(isActive: $showConfetti, duration: 3.0)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            playEntryAnimation()
        }
    }

    private func playEntryAnimation() {
        // Icon animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            iconScale = 1.0
        }

        // Glow and ring animation
        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            glowOpacity = 1.0
        }

        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }

        // Haptic feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if isExcellent || dailyGoalReached {
                HapticManager.shared.success()
                showConfetti = true
            } else {
                HapticManager.shared.success()
            }
        }

        // Stats animation
        withAnimation(.easeOut(duration: 0.4).delay(0.4)) {
            showStats = true
        }

        var currentDelay = 0.6

        // Achievements animation
        if !newlyUnlockedAchievements.isEmpty {
            withAnimation(.easeOut(duration: 0.4).delay(currentDelay)) {
                showAchievements = true
            }
            // Extra confetti for achievements
            DispatchQueue.main.asyncAfter(deadline: .now() + currentDelay) {
                showConfetti = true
            }
            currentDelay += 0.2
        }

        // Daily goal celebration animation
        if dailyGoalReached {
            withAnimation(.easeOut(duration: 0.4).delay(currentDelay)) {
                showGoalCelebration = true
            }
            // Extra confetti for goal achievement
            DispatchQueue.main.asyncAfter(deadline: .now() + currentDelay) {
                showConfetti = true
                HapticManager.shared.success()
            }
            currentDelay += 0.2
        }

        // Buttons animation
        withAnimation(.easeOut(duration: 0.4).delay(currentDelay)) {
            showButtons = true
        }
    }
}

// MARK: - Daily Goal Celebration Card

private struct DailyGoalCelebrationCard: View {
    @State private var appeared = false
    @State private var glowPulse = false
    @State private var starRotation: Double = 0

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.green.opacity(0.4), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 35
                        )
                    )
                    .frame(width: 60, height: 60)
                    .scaleEffect(glowPulse ? 1.3 : 1.0)
                    .opacity(glowPulse ? 0.3 : 0.7)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.2), .mint.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)

                Image(systemName: "flag.checkered.2.crossed")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .symbolEffect(.bounce, value: appeared)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("🎉")
                        .font(.headline)
                    Text("今日目标已完成！")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                Text("坚持学习，你做得很棒！")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Star decoration
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .offset(
                            x: CGFloat(i - 1) * 12,
                            y: i == 1 ? -8 : 0
                        )
                        .scaleEffect(i == 1 ? 1.2 : 0.8)
                }
            }
            .rotationEffect(.degrees(starRotation))
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))

                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.12), .mint.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.green.opacity(0.4), .mint.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: .green.opacity(0.2), radius: 10, y: 5)
        .scaleEffect(appeared ? 1 : 0.8)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                starRotation = 15
            }
        }
    }
}

// MARK: - Achievement Unlock Card

private struct AchievementUnlockCard: View {
    let achievement: Achievement

    @State private var appeared = false
    @State private var glowPulse = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.yellow.opacity(0.4), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 30
                        )
                    )
                    .frame(width: 56, height: 56)
                    .scaleEffect(glowPulse ? 1.2 : 1.0)
                    .opacity(glowPulse ? 0.3 : 0.6)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.yellow.opacity(0.2), .orange.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: achievement.iconName)
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .symbolEffect(.bounce, value: appeared)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text(achievement.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))

                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [.yellow.opacity(0.1), .orange.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    LinearGradient(
                        colors: [.yellow.opacity(0.3), .orange.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: .orange.opacity(0.15), radius: 8, y: 4)
        .scaleEffect(appeared ? 1 : 0.8)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
}

// MARK: - Summary Stat Card

private struct SummaryStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    var showProgress: Bool = false
    var progress: Double = 0

    @State private var glowOpacity: Double = 0
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 12,
                            endRadius: 32
                        )
                    )
                    .frame(width: 56, height: 56)
                    .opacity(glowOpacity)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.2), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .symbolEffect(.pulse.byLayer, options: .speed(0.5), value: appeared)
            }
            .scaleEffect(appeared ? 1 : 0.8)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .contentTransition(.numericText())

                    if showProgress {
                        Spacer()
                        // Mini progress bar with glow
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [color, color.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * progress, height: 6)
                                    .shadow(color: color.opacity(0.4), radius: 3)
                            }
                        }
                        .frame(width: 80, height: 6)
                    }
                }
            }

            if !showProgress {
                Spacer()
            }
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))

                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.06), color.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.15), color.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: color.opacity(0.08), radius: 10, y: 4)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.3)) {
                glowOpacity = 1.0
            }
        }
    }
}

// MARK: - Summary Button Style

private struct SummaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SessionStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview("Without Achievements") {
    SessionSummarySheet(
        stats: SessionStats(totalReviewed: 20, knownCount: 15, unknownCount: 5),
        onContinue: {},
        onHome: {}
    )
}

#Preview("With Achievements") {
    SessionSummarySheet(
        stats: SessionStats(totalReviewed: 20, knownCount: 20, unknownCount: 0),
        newlyUnlockedAchievements: [
            Achievement(id: "perfect_session", title: "完美练习", description: "一次练习全部正确", iconName: "checkmark.seal.fill"),
            Achievement(id: "first_word", title: "初次学习", description: "学习第一个单词", iconName: "star.fill")
        ],
        onContinue: {},
        onHome: {}
    )
}

#Preview("Daily Goal Reached") {
    SessionSummarySheet(
        stats: SessionStats(totalReviewed: 20, knownCount: 18, unknownCount: 2),
        dailyGoalReached: true,
        onContinue: {},
        onHome: {}
    )
}
