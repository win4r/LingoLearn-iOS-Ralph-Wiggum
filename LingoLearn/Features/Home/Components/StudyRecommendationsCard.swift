//
//  StudyRecommendationsCard.swift
//  LingoLearn
//
//  Personalized study recommendations based on user behavior
//

import SwiftUI
import SwiftData

struct StudyRecommendationsCard: View {
    @Environment(\.modelContext) private var modelContext
    @State private var recommendations: [Recommendation] = []
    @State private var showContent = false

    struct Recommendation: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let message: String
        let color: Color
        let priority: Priority
        let actionType: ActionType

        enum Priority: Int, Comparable {
            case high = 3
            case medium = 2
            case low = 1

            static func < (lhs: Priority, rhs: Priority) -> Bool {
                lhs.rawValue < rhs.rawValue
            }
        }

        enum ActionType {
            case learn
            case review
            case practice
            case rest
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
                                    colors: [.indigo.opacity(0.3), .clear],
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 16
                                )
                            )
                            .frame(width: 28, height: 28)

                        Image(systemName: "sparkles")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.indigo, .purple],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    Text("智能建议")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                Image(systemName: "brain.head.profile")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Recommendations list
            if recommendations.isEmpty {
                // Empty state
                VStack(spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("继续学习获取个性化建议")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 10) {
                    ForEach(recommendations.prefix(3)) { rec in
                        RecommendationRow(recommendation: rec)
                    }
                }
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
                        colors: [.indigo.opacity(0.2), .purple.opacity(0.15)],
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
            generateRecommendations()
            withAnimation(.easeOut(duration: 0.4).delay(0.45)) {
                showContent = true
            }
        }
    }

    private func generateRecommendations() {
        var recs: [Recommendation] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let hour = calendar.component(.hour, from: Date())

        // Fetch user stats
        let statsDescriptor = FetchDescriptor<UserStats>()
        guard let stats = try? modelContext.fetch(statsDescriptor).first else { return }

        // Fetch today's progress
        let progressDescriptor = FetchDescriptor<DailyProgress>(
            predicate: #Predicate<DailyProgress> { $0.date == today }
        )
        let todayProgress = try? modelContext.fetch(progressDescriptor).first

        // Fetch user settings
        let settingsDescriptor = FetchDescriptor<UserSettings>()
        let settings = try? modelContext.fetch(settingsDescriptor).first
        let dailyGoal = settings?.dailyGoal ?? 20

        // Fetch words due for review
        let reviewDescriptor = FetchDescriptor<Word>(
            predicate: #Predicate<Word> { $0.nextReviewDate != nil && $0.nextReviewDate! <= today }
        )
        let wordsDueCount = (try? modelContext.fetchCount(reviewDescriptor)) ?? 0

        // Fetch difficult words (low accuracy)
        let wordsDescriptor = FetchDescriptor<Word>(
            predicate: #Predicate<Word> { $0.timesStudied >= 2 }
        )
        let studiedWords = try? modelContext.fetch(wordsDescriptor)
        let difficultWordsCount = studiedWords?.filter { word in
            let accuracy = Double(word.timesCorrect) / Double(word.timesStudied)
            return accuracy < 0.6
        }.count ?? 0

        // Calculate today's progress
        let todayTotal = (todayProgress?.wordsLearned ?? 0) + (todayProgress?.wordsReviewed ?? 0)
        let progressPercent = Double(todayTotal) / Double(dailyGoal)

        // 1. Review reminder (high priority if words due)
        if wordsDueCount > 0 {
            recs.append(Recommendation(
                icon: "arrow.clockwise",
                title: "复习提醒",
                message: "有 \(wordsDueCount) 个单词需要复习，及时复习记忆更牢固",
                color: .orange,
                priority: wordsDueCount > 10 ? .high : .medium,
                actionType: .review
            ))
        }

        // 2. Daily goal progress
        if progressPercent < 1.0 {
            let remaining = dailyGoal - todayTotal
            recs.append(Recommendation(
                icon: "target",
                title: "今日目标",
                message: "还差 \(remaining) 个单词完成今日目标，加油！",
                color: .blue,
                priority: progressPercent < 0.5 ? .medium : .low,
                actionType: .learn
            ))
        } else {
            recs.append(Recommendation(
                icon: "checkmark.seal.fill",
                title: "目标达成",
                message: "太棒了！今日目标已完成，继续保持学习习惯",
                color: .green,
                priority: .low,
                actionType: .rest
            ))
        }

        // 3. Difficult words alert
        if difficultWordsCount > 0 {
            recs.append(Recommendation(
                icon: "brain.head.profile",
                title: "重点词汇",
                message: "有 \(difficultWordsCount) 个单词正确率偏低，建议多加练习",
                color: .red,
                priority: difficultWordsCount > 5 ? .high : .medium,
                actionType: .practice
            ))
        }

        // 4. Streak maintenance
        if let lastStudy = stats.lastStudyDate {
            let lastStudyDay = calendar.startOfDay(for: lastStudy)
            let daysSinceLast = calendar.dateComponents([.day], from: lastStudyDay, to: today).day ?? 0

            if daysSinceLast == 0 && todayTotal == 0 {
                // Today not started yet, remind to keep streak
                if stats.currentStreak > 0 {
                    recs.append(Recommendation(
                        icon: "flame.fill",
                        title: "保持连续学习",
                        message: "已连续学习 \(stats.currentStreak) 天，今天继续保持！",
                        color: .orange,
                        priority: stats.currentStreak > 7 ? .high : .medium,
                        actionType: .learn
                    ))
                }
            }
        }

        // 5. Time-based suggestions
        if hour >= 22 || hour < 6 {
            recs.append(Recommendation(
                icon: "moon.zzz.fill",
                title: "休息建议",
                message: "夜深了，保证充足睡眠也是学习的一部分哦",
                color: .indigo,
                priority: .low,
                actionType: .rest
            ))
        } else if hour >= 8 && hour < 12 {
            if todayTotal == 0 {
                recs.append(Recommendation(
                    icon: "sun.horizon.fill",
                    title: "黄金时段",
                    message: "早晨是记忆力最佳时段，开始今天的学习吧",
                    color: .orange,
                    priority: .medium,
                    actionType: .learn
                ))
            }
        }

        // 6. New user encouragement
        if stats.totalWordsLearned < 20 {
            recs.append(Recommendation(
                icon: "sparkles",
                title: "新手加油",
                message: "词汇量正在积累中，每天坚持学习很快就能看到进步！",
                color: .purple,
                priority: .medium,
                actionType: .learn
            ))
        }

        // Sort by priority (high first) and take top 3
        recommendations = recs.sorted { $0.priority > $1.priority }
    }
}

// MARK: - Recommendation Row

private struct RecommendationRow: View {
    let recommendation: StudyRecommendationsCard.Recommendation

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(recommendation.color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: recommendation.icon)
                    .font(.subheadline)
                    .foregroundStyle(recommendation.color)
            }

            // Content
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(recommendation.title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if recommendation.priority == .high {
                        Text("重要")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(recommendation.color)
                            .clipShape(Capsule())
                    }
                }

                Text(recommendation.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            // Action indicator
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .scaleEffect(appeared ? 1 : 0.95)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}

#Preview {
    StudyRecommendationsCard()
        .padding()
        .background(Color(.systemGroupedBackground))
        .modelContainer(for: [UserStats.self, DailyProgress.self, UserSettings.self, Word.self])
}
