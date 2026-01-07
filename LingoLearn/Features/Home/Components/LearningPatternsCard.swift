//
//  LearningPatternsCard.swift
//  LingoLearn
//
//  Learning patterns and study habit analytics
//

import SwiftUI
import SwiftData

struct LearningPatternsCard: View {
    @Environment(\.modelContext) private var modelContext
    @State private var bestStudyHour: Int = 9
    @State private var mostProductiveDay: String = "周一"
    @State private var averageSessionDuration: TimeInterval = 0
    @State private var consistencyScore: Double = 0
    @State private var weeklyPattern: [Int] = Array(repeating: 0, count: 7)
    @State private var hourlyPattern: [Int] = Array(repeating: 0, count: 24)
    @State private var showContent = false
    @State private var selectedTab: PatternTab = .daily

    enum PatternTab: String, CaseIterable {
        case daily = "每日"
        case hourly = "时段"
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
                                    colors: [.purple.opacity(0.3), .clear],
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 16
                                )
                            )
                            .frame(width: 28, height: 28)

                        Image(systemName: "chart.bar.xaxis.ascending")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    Text("学习模式")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                // Tab selector
                HStack(spacing: 4) {
                    ForEach(PatternTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue)
                            .font(.caption2)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .foregroundStyle(selectedTab == tab ? .white : .secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(selectedTab == tab ? Color.purple : Color.clear)
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    HapticManager.shared.selection()
                                    selectedTab = tab
                                }
                            }
                    }
                }
                .padding(3)
                .background(
                    Capsule()
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            }

            // Pattern visualization
            if selectedTab == .daily {
                dailyPatternView
            } else {
                hourlyPatternView
            }

            // Insights row
            HStack(spacing: 12) {
                InsightBadge(
                    icon: "clock.badge.checkmark",
                    label: "最佳时段",
                    value: formatHour(bestStudyHour),
                    color: .purple
                )

                InsightBadge(
                    icon: "calendar.badge.clock",
                    label: "高效日",
                    value: mostProductiveDay,
                    color: .pink
                )

                InsightBadge(
                    icon: "gauge.with.needle",
                    label: "稳定性",
                    value: "\(Int(consistencyScore * 100))%",
                    color: .indigo
                )
            }

            // Tip based on patterns
            patternTip
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
                        colors: [.purple.opacity(0.2), .pink.opacity(0.15)],
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
            loadPatternData()
            withAnimation(.easeOut(duration: 0.4).delay(0.4)) {
                showContent = true
            }
        }
    }

    // MARK: - Daily Pattern View

    private var dailyPatternView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { day in
                    DayPatternBar(
                        dayIndex: day,
                        value: weeklyPattern[day],
                        maxValue: weeklyPattern.max() ?? 1
                    )
                }
            }
            .frame(height: 60)

            // Day labels
            HStack(spacing: 6) {
                ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Hourly Pattern View

    private var hourlyPatternView: some View {
        VStack(spacing: 8) {
            // Grouped hours (4-hour blocks)
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { block in
                    let startHour = block * 4
                    let blockSum = (0..<4).reduce(0) { sum, offset in
                        sum + hourlyPattern[startHour + offset]
                    }

                    HourBlockBar(
                        blockIndex: block,
                        value: blockSum,
                        maxValue: max(hourBlockMax, 1),
                        isBestTime: bestStudyHour >= startHour && bestStudyHour < startHour + 4
                    )
                }
            }
            .frame(height: 60)

            // Hour block labels
            HStack(spacing: 8) {
                ForEach(["0-4", "4-8", "8-12", "12-16", "16-20", "20-24"], id: \.self) { label in
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var hourBlockMax: Int {
        var maxBlock = 0
        for block in 0..<6 {
            let startHour = block * 4
            let blockSum = (0..<4).reduce(0) { sum, offset in
                sum + hourlyPattern[startHour + offset]
            }
            maxBlock = max(maxBlock, blockSum)
        }
        return maxBlock
    }

    // MARK: - Pattern Tip

    private var patternTip: some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.caption)
                .foregroundStyle(.orange)

            Text(generatePatternTip())
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.08))
        )
    }

    private func generatePatternTip() -> String {
        if consistencyScore > 0.7 {
            return "学习习惯很稳定！保持每天在\(formatHour(bestStudyHour))学习效果最佳"
        } else if consistencyScore > 0.4 {
            return "尝试在\(formatHour(bestStudyHour))固定学习，养成习惯事半功倍"
        } else {
            return "建议每天固定时间学习，培养稳定的学习习惯"
        }
    }

    // MARK: - Data Loading

    private func loadPatternData() {
        let calendar = Calendar.current
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()

        // Fetch study sessions from last month
        let descriptor = FetchDescriptor<StudySession>(
            predicate: #Predicate<StudySession> { $0.date >= oneMonthAgo }
        )

        guard let sessions: [StudySession] = try? modelContext.fetch(descriptor) else { return }

        // Calculate weekly pattern
        var weekData = Array(repeating: 0, count: 7)
        var hourData = Array(repeating: 0, count: 24)
        var dayCount = [Int: Set<Date>]()

        for session in sessions {
            let weekday = calendar.component(.weekday, from: session.date) - 1 // 0-6
            let hour = calendar.component(.hour, from: session.date)
            let dayStart = calendar.startOfDay(for: session.date)

            weekData[weekday] += session.wordsStudied
            hourData[hour] += session.wordsStudied

            // Track unique study days per weekday
            if dayCount[weekday] == nil {
                dayCount[weekday] = Set<Date>()
            }
            dayCount[weekday]?.insert(dayStart)
        }

        weeklyPattern = weekData
        hourlyPattern = hourData

        // Find best study hour
        if let maxHour = hourData.enumerated().max(by: { $0.element < $1.element }) {
            bestStudyHour = maxHour.offset
        }

        // Find most productive day
        let dayNames = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        if let maxDay = weekData.enumerated().max(by: { $0.element < $1.element }) {
            mostProductiveDay = dayNames[maxDay.offset]
        }

        // Calculate consistency score
        calculateConsistencyScore()
    }

    private func calculateConsistencyScore() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var studyDays = 0
        let totalDays = 30

        for dayOffset in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            let progressDescriptor = FetchDescriptor<DailyProgress>(
                predicate: #Predicate<DailyProgress> { $0.date == date }
            )

            if let progress: [DailyProgress] = try? modelContext.fetch(progressDescriptor),
               let dailyProgress = progress.first,
               (dailyProgress.wordsLearned + dailyProgress.wordsReviewed) > 0 {
                studyDays += 1
            }
        }

        consistencyScore = Double(studyDays) / Double(totalDays)
    }

    private func formatHour(_ hour: Int) -> String {
        if hour == 0 { return "午夜" }
        else if hour < 6 { return "凌晨" }
        else if hour < 9 { return "早晨" }
        else if hour < 12 { return "上午" }
        else if hour == 12 { return "中午" }
        else if hour < 14 { return "午后" }
        else if hour < 18 { return "下午" }
        else if hour < 21 { return "傍晚" }
        else { return "晚间" }
    }
}

// MARK: - Day Pattern Bar

private struct DayPatternBar: View {
    let dayIndex: Int
    let value: Int
    let maxValue: Int

    @State private var animatedHeight: CGFloat = 0

    private var heightPercentage: CGFloat {
        guard maxValue > 0 else { return 0.1 }
        return max(CGFloat(value) / CGFloat(maxValue), 0.1)
    }

    private var barColor: LinearGradient {
        let intensity = heightPercentage
        if intensity > 0.7 {
            return LinearGradient(colors: [.purple, .pink], startPoint: .bottom, endPoint: .top)
        } else if intensity > 0.3 {
            return LinearGradient(colors: [.purple.opacity(0.7), .pink.opacity(0.6)], startPoint: .bottom, endPoint: .top)
        } else {
            return LinearGradient(colors: [.purple.opacity(0.4), .pink.opacity(0.3)], startPoint: .bottom, endPoint: .top)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(barColor)
                    .frame(height: geometry.size.height * animatedHeight)
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(dayIndex) * 0.05)) {
                animatedHeight = heightPercentage
            }
        }
    }
}

// MARK: - Hour Block Bar

private struct HourBlockBar: View {
    let blockIndex: Int
    let value: Int
    let maxValue: Int
    let isBestTime: Bool

    @State private var animatedHeight: CGFloat = 0

    private var heightPercentage: CGFloat {
        guard maxValue > 0 else { return 0.1 }
        return max(CGFloat(value) / CGFloat(maxValue), 0.1)
    }

    private var barColor: LinearGradient {
        if isBestTime {
            return LinearGradient(colors: [.orange, .yellow], startPoint: .bottom, endPoint: .top)
        }
        let intensity = heightPercentage
        if intensity > 0.5 {
            return LinearGradient(colors: [.indigo, .purple], startPoint: .bottom, endPoint: .top)
        } else {
            return LinearGradient(colors: [.indigo.opacity(0.5), .purple.opacity(0.4)], startPoint: .bottom, endPoint: .top)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()

                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(height: geometry.size.height * animatedHeight)

                    if isBestTime && value > 0 {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.orange)
                            .offset(y: -10)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(blockIndex) * 0.08)) {
                animatedHeight = heightPercentage
            }
        }
    }
}

// MARK: - Insight Badge

private struct InsightBadge: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
            }

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    LearningPatternsCard()
        .padding()
        .background(Color(.systemGroupedBackground))
        .modelContainer(for: [StudySession.self, DailyProgress.self])
}
