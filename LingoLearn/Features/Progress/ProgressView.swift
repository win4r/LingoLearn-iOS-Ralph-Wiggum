//
//  ProgressView.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI
import SwiftData

struct LearningProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ProgressViewModel?
    @State private var selectedPeriod: TimePeriod = .week
    @State private var showShareSheet = false

    enum TimePeriod: String, CaseIterable {
        case week = "7天"
        case month = "30天"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Period Selector
                    Picker("Time Period", selection: $selectedPeriod) {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: selectedPeriod) { _, newValue in
                        HapticManager.shared.selection()
                        viewModel?.updatePeriod(newValue == .week ? 7 : 30)
                    }

                    // Stats Cards
                    statsCardsSection

                    // Recent Sessions
                    if let vm = viewModel, !vm.recentSessions.isEmpty {
                        sessionHistorySection
                    }

                    // Line Chart
                    lineChartSection

                    // Calendar Heatmap
                    calendarHeatmapSection

                    // Mastery Distribution
                    masteryDistributionSection

                    // Achievement Wall
                    achievementWallSection
                }
                .padding(.vertical)
            }
            .navigationTitle("学习进度")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: generateProgressSummary()) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = ProgressViewModel(modelContext: modelContext)
                }
                viewModel?.loadData()
            }
            .refreshable {
                viewModel?.loadData()
            }
        }
    }

    private func generateProgressSummary() -> String {
        guard let vm = viewModel else {
            return "LingoLearn - 我的学习进度"
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年M月d日"
        let today = dateFormatter.string(from: Date())

        var summary = """
        📚 LingoLearn 学习报告
        📅 \(today)

        🔥 连续学习: \(vm.currentStreak)天
        ⭐ 最长记录: \(vm.longestStreak)天
        📖 已学词汇: \(vm.totalWordsLearned)个
        ⏱️ 总学习时长: \(vm.formattedTotalStudyTime)

        📊 掌握情况:
        """

        let total = (vm.newCount) + (vm.learningCount) + (vm.reviewingCount) + (vm.masteredCount)
        if total > 0 {
            let masteryRate = Double(vm.masteredCount) / Double(total) * 100
            summary += """

        • 新词: \(vm.newCount)个
        • 学习中: \(vm.learningCount)个
        • 复习中: \(vm.reviewingCount)个
        • 已掌握: \(vm.masteredCount)个
        • 掌握率: \(String(format: "%.1f", masteryRate))%
        """
        }

        // Add achievements
        let unlockedCount = vm.unlockedAchievements.count
        if unlockedCount > 0 {
            summary += """


        🏆 已解锁成就: \(unlockedCount)个
        """
        }

        summary += """


        ——
        使用 LingoLearn 学习英语词汇
        """

        return summary
    }

    private var statsCardsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    title: "当前连续",
                    value: "\(viewModel?.currentStreak ?? 0)",
                    unit: "天",
                    icon: "flame.fill",
                    color: .orange
                )

                StatCard(
                    title: "最长连续",
                    value: "\(viewModel?.longestStreak ?? 0)",
                    unit: "天",
                    icon: "star.fill",
                    color: .yellow
                )
            }

            HStack(spacing: 12) {
                StatCard(
                    title: "总学习词汇",
                    value: "\(viewModel?.totalWordsLearned ?? 0)",
                    unit: "个",
                    icon: "book.fill",
                    color: .blue
                )

                StatCard(
                    title: "总学习时长",
                    value: viewModel?.formattedTotalStudyTime ?? "0分钟",
                    unit: "",
                    icon: "clock.fill",
                    color: .green
                )
            }
        }
        .padding(.horizontal)
    }

    private var lineChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProgressSectionHeader(title: "学习趋势", icon: "chart.line.uptrend.xyaxis", color: .blue)
                .padding(.horizontal)

            WeeklyLineChart(data: viewModel?.chartData ?? [])
                .frame(height: 200)
                .padding()
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.systemBackground))
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.05), .cyan.opacity(0.02)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .blue.opacity(0.08), radius: 8, y: 4)
                .padding(.horizontal)
        }
    }

    private var calendarHeatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProgressSectionHeader(title: "学习日历", icon: "calendar", color: .green)
                .padding(.horizontal)

            CalendarHeatmap(dailyProgress: viewModel?.dailyProgressData ?? [])
                .frame(height: 180)
                .padding()
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.systemBackground))
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [.green.opacity(0.05), .mint.opacity(0.02)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.green.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .green.opacity(0.08), radius: 8, y: 4)
                .padding(.horizontal)
        }
    }

    private var masteryDistributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProgressSectionHeader(title: "掌握度分布", icon: "chart.pie", color: .purple)
                .padding(.horizontal)

            VStack(spacing: 16) {
                MasteryPieChart(
                    newCount: viewModel?.newCount ?? 0,
                    learningCount: viewModel?.learningCount ?? 0,
                    reviewingCount: viewModel?.reviewingCount ?? 0,
                    masteredCount: viewModel?.masteredCount ?? 0
                )
                .frame(height: 200)

                // Legend
                HStack(spacing: 16) {
                    LegendItem(color: .gray, label: "新学", count: viewModel?.newCount ?? 0)
                    LegendItem(color: .orange, label: "学习中", count: viewModel?.learningCount ?? 0)
                    LegendItem(color: .blue, label: "复习中", count: viewModel?.reviewingCount ?? 0)
                    LegendItem(color: .green, label: "已掌握", count: viewModel?.masteredCount ?? 0)
                }
                .font(.caption)
            }
            .padding()
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemBackground))
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.05), .pink.opacity(0.02)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.purple.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .purple.opacity(0.08), radius: 8, y: 4)
            .padding(.horizontal)
        }
    }

    private var achievementWallSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProgressSectionHeader(title: "成就墙", icon: "trophy.fill", color: .yellow)
                .padding(.horizontal)

            AchievementWall(
                unlockedAchievements: viewModel?.unlockedAchievements ?? [],
                onAchievementTap: { achievement in
                    // Show achievement details
                }
            )
            .padding()
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemBackground))
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [.yellow.opacity(0.05), .orange.opacity(0.02)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.yellow.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .yellow.opacity(0.08), radius: 8, y: 4)
            .padding(.horizontal)
        }
    }

    private var sessionHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProgressSectionHeader(title: "最近学习", icon: "clock.arrow.circlepath", color: .cyan)
                .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(viewModel?.recentSessions ?? []) { session in
                    SessionHistoryRow(session: session)
                }
            }
            .padding()
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemBackground))
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [.cyan.opacity(0.05), .blue.opacity(0.02)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.cyan.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .cyan.opacity(0.08), radius: 8, y: 4)
            .padding(.horizontal)
        }
    }
}

// MARK: - Session History Row

struct SessionHistoryRow: View {
    let session: StudySession

    private var sessionTypeIcon: String {
        switch session.sessionType {
        case .learning: return "book.fill"
        case .review: return "arrow.clockwise"
        case .practice: return "gamecontroller.fill"
        case .multipleChoice: return "list.bullet.rectangle"
        case .fillInBlank: return "character.cursor.ibeam"
        case .listening: return "headphones"
        }
    }

    private var sessionTypeColor: Color {
        switch session.sessionType {
        case .learning: return .blue
        case .review: return .purple
        case .practice, .multipleChoice, .fillInBlank, .listening: return .green
        }
    }

    private var sessionTypeName: String {
        switch session.sessionType {
        case .learning: return "学习"
        case .review: return "复习"
        case .practice: return "练习"
        case .multipleChoice: return "选择题"
        case .fillInBlank: return "填空题"
        case .listening: return "听力"
        }
    }

    private var formattedDuration: String {
        let minutes = Int(session.duration) / 60
        let seconds = Int(session.duration) % 60
        if minutes > 0 {
            return "\(minutes)分\(seconds)秒"
        }
        return "\(seconds)秒"
    }

    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: session.date, relativeTo: Date())
    }

    private var accuracy: Double {
        guard session.wordsStudied > 0 else { return 0 }
        return Double(session.wordsCorrect) / Double(session.wordsStudied)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [sessionTypeColor.opacity(0.15), sessionTypeColor.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: sessionTypeIcon)
                    .font(.body)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [sessionTypeColor, sessionTypeColor.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            // Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(sessionTypeName)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    Text(formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Label("\(session.wordsStudied)词", systemImage: "textformat")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label(formattedDuration, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    // Accuracy indicator
                    HStack(spacing: 4) {
                        Circle()
                            .fill(accuracy >= 0.8 ? Color.green : (accuracy >= 0.6 ? Color.orange : Color.red))
                            .frame(width: 6, height: 6)
                        Text(String(format: "%.0f%%", accuracy * 100))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(accuracy >= 0.8 ? .green : (accuracy >= 0.6 ? .orange : .red))
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    @State private var isAnimating = false
    @State private var glowOpacity: Double = 0
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [color.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 8,
                                endRadius: 22
                            )
                        )
                        .frame(width: 40, height: 40)
                        .opacity(glowOpacity)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.15), color.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .symbolEffect(.bounce, value: isAnimating)
                }
                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .contentTransition(.numericText())
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))

                RoundedRectangle(cornerRadius: 14)
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
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.08), radius: 8, y: 4)
        .scaleEffect(appeared ? 1 : 0.95)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAnimating = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.5)) {
                glowOpacity = 1.0
            }
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 2,
                            endRadius: 8
                        )
                    )
                    .frame(width: 14, height: 14)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 8, height: 8)
            }

            Text(label)
                .fontWeight(.medium)

            Text("\(count)")
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
    }
}

// MARK: - Section Header

struct ProgressSectionHeader: View {
    let title: String
    let icon: String
    let color: Color

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 5,
                            endRadius: 16
                        )
                    )
                    .frame(width: 28, height: 28)

                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .scaleEffect(appeared ? 1 : 0.8)

            Text(title)
                .font(.headline)
        }
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -10)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}

#Preview {
    LearningProgressView()
        .modelContainer(for: [DailyProgress.self, UserStats.self, Word.self])
}
