//
//  StreakFreezeCard.swift
//  LingoLearn
//
//  Streak freeze protection feature card
//

import SwiftUI
import SwiftData

struct StreakFreezeCard: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @Query private var stats: [UserStats]

    @State private var showContent = false
    @State private var showConfirmation = false
    @State private var isAtRisk = false

    private var userSettings: UserSettings? { settings.first }
    private var userStats: UserStats? { stats.first }

    private var streakFreezes: Int {
        userSettings?.streakFreezes ?? 0
    }

    private var currentStreak: Int {
        userStats?.currentStreak ?? 0
    }

    private var isStreakAtRisk: Bool {
        guard let lastStudyDate = userStats?.lastStudyDate else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastStudy = calendar.startOfDay(for: lastStudyDate)

        // Check if yesterday was missed (streak at risk today)
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
            return lastStudy < yesterday && currentStreak > 0
        }
        return false
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
                                    colors: [.cyan.opacity(0.3), .clear],
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 16
                                )
                            )
                            .frame(width: 28, height: 28)

                        Image(systemName: "snowflake")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    Text("连续学习保护")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                // Available freezes
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: index < streakFreezes ? "snowflake.circle.fill" : "snowflake.circle")
                            .font(.subheadline)
                            .foregroundStyle(index < streakFreezes ? .cyan : .gray.opacity(0.3))
                    }
                }
            }

            // Content
            VStack(spacing: 12) {
                if isStreakAtRisk && currentStreak > 0 {
                    // At risk state
                    atRiskView
                } else if currentStreak > 0 {
                    // Safe state with streak
                    safeStateView
                } else {
                    // No streak yet
                    noStreakView
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )

            // Info text
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.caption2)
                Text("每完成7天学习获得1次保护机会")
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
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
                        colors: isStreakAtRisk ? [.orange.opacity(0.3), .red.opacity(0.2)] : [.cyan.opacity(0.2), .blue.opacity(0.15)],
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
            withAnimation(.easeOut(duration: 0.4).delay(0.35)) {
                showContent = true
            }
        }
        .alert("使用连续保护", isPresented: $showConfirmation) {
            Button("取消", role: .cancel) { }
            Button("使用") {
                useStreakFreeze()
            }
        } message: {
            Text("确定使用1次连续保护来保住你的\(currentStreak)天连续学习记录吗？")
        }
    }

    private var atRiskView: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("连续学习即将中断！")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)

                    Text("你的\(currentStreak)天记录需要保护")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            if streakFreezes > 0 {
                Button(action: {
                    HapticManager.shared.impact()
                    showConfirmation = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "snowflake")
                        Text("使用保护 (\(streakFreezes)次可用)")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(.red)
                    Text("没有可用的保护次数")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var safeStateView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(.green)
                    Text("连续学习安全")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Text("当前连续 \(currentStreak) 天")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(streakFreezes)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.cyan)
                Text("次保护")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var noStreakView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("开始你的连续学习")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("每天学习来建立连续记录")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "flame")
                .font(.title)
                .foregroundStyle(.gray.opacity(0.3))
        }
    }

    private func useStreakFreeze() {
        guard let settings = userSettings, let stats = userStats else { return }
        guard settings.streakFreezes > 0 else { return }

        // Use a freeze
        settings.streakFreezes -= 1
        settings.lastStreakFreezeUsed = Date()

        // Update last study date to today to maintain streak
        stats.lastStudyDate = Date()

        try? modelContext.save()

        HapticManager.shared.success()
    }
}

#Preview {
    StreakFreezeCard()
        .padding()
        .background(Color(.systemGroupedBackground))
        .modelContainer(for: [UserSettings.self, UserStats.self])
}
