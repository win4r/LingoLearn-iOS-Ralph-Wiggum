//
//  DailyProgressCard.swift
//  LingoLearn
//
//  Displays the daily progress ring and stats
//

import SwiftUI

struct DailyProgressCard: View {
    let progress: DailyProgress?
    let dailyGoal: Int?
    let progressPercentage: Double

    @State private var animatedProgress: Double = 0
    @State private var showStats = false
    @State private var showCelebration = false
    @State private var glowOpacity: Double = 0

    private var isGoalComplete: Bool {
        progressPercentage >= 1.0
    }

    private var motivationalMessage: String {
        if isGoalComplete {
            return "太棒了！目标已达成 🎉"
        } else if progressPercentage >= 0.75 {
            return "就快完成了，加油！"
        } else if progressPercentage >= 0.5 {
            return "已完成一半，继续加油！"
        } else if progressPercentage >= 0.25 {
            return "良好的开始！"
        } else if progressPercentage > 0 {
            return "今天也要加油哦！"
        } else {
            return "开始今天的学习吧！"
        }
    }

    private var gradientColors: [Color] {
        if isGoalComplete {
            return [.green, .mint]
        } else if progressPercentage >= 0.75 {
            return [.teal, .green]
        } else if progressPercentage >= 0.5 {
            return [.blue, .teal]
        } else {
            return [.blue, .purple]
        }
    }

    private var accessibilityDescription: String {
        if let progress = progress, let goal = dailyGoal {
            let percentage = Int(progressPercentage * 100)
            return "今日进度\(percentage)%,已学习\(progress.wordsLearned)个,已复习\(progress.wordsReviewed)个,目标\(goal)个,学习时长\(Int(progress.totalStudyTime / 60))分钟,\(motivationalMessage)"
        }
        return "今日进度,开始今天的学习吧"
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("今日进度")
                        .font(.headline)

                    Text(motivationalMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .opacity(showStats ? 1 : 0)
                }

                Spacer()

                if let progress = progress, let goal = dailyGoal {
                    HStack(spacing: 6) {
                        Text("\(progress.wordsLearned + progress.wordsReviewed)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .contentTransition(.numericText())

                        Text("/ \(goal)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if isGoalComplete {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .font(.title3)
                                .symbolEffect(.bounce, value: showCelebration)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(gradientColors.first?.opacity(0.1) ?? Color.blue.opacity(0.1))
                    )
                }
            }

            // Progress Ring with decorations
            ZStack {
                // Glow effect for goal complete
                if isGoalComplete {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.green.opacity(0.2), .clear],
                                center: .center,
                                startRadius: 50,
                                endRadius: 100
                            )
                        )
                        .frame(width: 180, height: 180)
                        .opacity(glowOpacity)
                }

                RingProgressView(
                    progress: animatedProgress,
                    lineWidth: 16,
                    gradientColors: gradientColors,
                    size: 140
                )
            }

            // Stats Row
            if let progress = progress {
                HStack(spacing: 0) {
                    ProgressStatItem(
                        icon: "book.fill",
                        title: "已学",
                        value: "\(progress.wordsLearned)",
                        color: .blue
                    )
                    .opacity(showStats ? 1 : 0)
                    .offset(x: showStats ? 0 : -20)

                    Divider()
                        .frame(height: 36)
                        .padding(.horizontal, 16)

                    ProgressStatItem(
                        icon: "arrow.clockwise",
                        title: "已复习",
                        value: "\(progress.wordsReviewed)",
                        color: .purple
                    )
                    .opacity(showStats ? 1 : 0)
                    .scaleEffect(showStats ? 1 : 0.8)

                    Divider()
                        .frame(height: 36)
                        .padding(.horizontal, 16)

                    ProgressStatItem(
                        icon: "clock.fill",
                        title: "时长",
                        value: "\(Int(progress.totalStudyTime / 60))分",
                        color: .green
                    )
                    .opacity(showStats ? 1 : 0)
                    .offset(x: showStats ? 0 : 20)
                }
            }
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))

                // Subtle gradient overlay
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [gradientColors.first?.opacity(0.05) ?? .clear, .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    isGoalComplete ?
                        LinearGradient(colors: [.green.opacity(0.4), .mint.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom),
                    lineWidth: 2
                )
        )
        .onAppear {
            playEntryAnimation()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .onChange(of: progressPercentage) { oldValue, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newValue
            }

            if newValue >= 1.0 && oldValue < 1.0 {
                HapticManager.shared.success()
                showCelebration = true
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    glowOpacity = 1.0
                }
            }
        }
    }

    private func playEntryAnimation() {
        // Animate progress ring
        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
            animatedProgress = progressPercentage
        }

        // Animate stats
        withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
            showStats = true
        }

        // Check if goal already complete on appear
        if isGoalComplete {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showCelebration = true
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    glowOpacity = 1.0
                }
            }
        }
    }
}

// MARK: - Progress Stat Item

private struct ProgressStatItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .contentTransition(.numericText())
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .contentTransition(.numericText())

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    DailyProgressCard(
        progress: nil,
        dailyGoal: 20,
        progressPercentage: 0.65
    )
    .padding()
}
