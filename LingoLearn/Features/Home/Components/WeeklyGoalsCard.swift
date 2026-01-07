//
//  WeeklyGoalsCard.swift
//  LingoLearn
//
//  Weekly study goals visualization
//

import SwiftUI
import SwiftData

struct WeeklyGoalsCard: View {
    @Environment(\.modelContext) private var modelContext
    @State private var weeklyData: [DayProgress] = []
    @State private var dailyGoal: Int = 20
    @State private var showContent = false

    struct DayProgress: Identifiable {
        let id = UUID()
        let date: Date
        let wordsStudied: Int
        let goal: Int

        var percentage: Double {
            guard goal > 0 else { return 0 }
            return min(Double(wordsStudied) / Double(goal), 1.0)
        }

        var isToday: Bool {
            Calendar.current.isDateInToday(date)
        }

        var dayName: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            formatter.locale = Locale(identifier: "zh_CN")
            return String(formatter.string(from: date).prefix(1))
        }
    }

    private var weeklyTotal: Int {
        weeklyData.reduce(0) { $0 + $1.wordsStudied }
    }

    private var weeklyGoal: Int {
        dailyGoal * 7
    }

    private var daysCompleted: Int {
        weeklyData.filter { $0.percentage >= 1.0 }.count
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
                                    colors: [.teal.opacity(0.3), .clear],
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 16
                                )
                            )
                            .frame(width: 28, height: 28)

                        Image(systemName: "calendar.badge.checkmark")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.teal, .green],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    Text("本周目标")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                // Weekly summary
                HStack(spacing: 4) {
                    Text("\(daysCompleted)/7")
                        .font(.caption)
                        .fontWeight(.bold)
                    Text("天达标")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(daysCompleted >= 5 ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                )
            }

            // Weekly bar chart
            HStack(spacing: 8) {
                ForEach(weeklyData) { day in
                    WeeklyDayBar(dayProgress: day)
                }
            }
            .frame(height: 80)

            // Weekly total progress
            VStack(spacing: 6) {
                HStack {
                    Text("本周进度")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(weeklyTotal)/\(weeklyGoal)")
                        .font(.caption)
                        .fontWeight(.medium)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.teal, .green],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: min(CGFloat(weeklyTotal) / CGFloat(max(weeklyGoal, 1)) * geometry.size.width, geometry.size.width), height: 6)
                    }
                }
                .frame(height: 6)
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
                        colors: [.teal.opacity(0.2), .green.opacity(0.15)],
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
            loadWeeklyData()
            withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                showContent = true
            }
        }
    }

    private func loadWeeklyData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Load user settings for daily goal
        let settingsDescriptor = FetchDescriptor<UserSettings>()
        if let settings = try? modelContext.fetch(settingsDescriptor).first {
            dailyGoal = settings.dailyGoal
        }

        // Get the start of the week (Sunday)
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today) ?? today

        // Build week data
        var data: [DayProgress] = []
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) else { continue }

            // Fetch progress for this day
            let progressDescriptor = FetchDescriptor<DailyProgress>(
                predicate: #Predicate { $0.date == date }
            )

            var wordsStudied = 0
            if let progress = try? modelContext.fetch(progressDescriptor).first {
                wordsStudied = progress.wordsLearned + progress.wordsReviewed
            }

            data.append(DayProgress(date: date, wordsStudied: wordsStudied, goal: dailyGoal))
        }

        weeklyData = data
    }
}

// MARK: - Weekly Day Bar

private struct WeeklyDayBar: View {
    let dayProgress: WeeklyGoalsCard.DayProgress
    @State private var animatedPercentage: Double = 0
    @State private var appeared = false

    private var barColor: LinearGradient {
        if dayProgress.percentage >= 1.0 {
            return LinearGradient(colors: [.green, .mint], startPoint: .bottom, endPoint: .top)
        } else if dayProgress.percentage >= 0.5 {
            return LinearGradient(colors: [.orange, .yellow], startPoint: .bottom, endPoint: .top)
        } else if dayProgress.percentage > 0 {
            return LinearGradient(colors: [.gray, .gray.opacity(0.7)], startPoint: .bottom, endPoint: .top)
        } else {
            return LinearGradient(colors: [Color(.systemGray5)], startPoint: .bottom, endPoint: .top)
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            // Bar
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6))
                        .frame(width: geometry.size.width)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geometry.size.width, height: max(geometry.size.height * animatedPercentage, 4))
                }
            }

            // Day label
            Text(dayProgress.dayName)
                .font(.caption2)
                .fontWeight(dayProgress.isToday ? .bold : .regular)
                .foregroundStyle(dayProgress.isToday ? .primary : .secondary)

            // Today indicator
            if dayProgress.isToday {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.teal, .green],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 5, height: 5)
            } else {
                Color.clear.frame(width: 5, height: 5)
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                animatedPercentage = dayProgress.percentage
                appeared = true
            }
        }
    }
}

#Preview {
    WeeklyGoalsCard()
        .padding()
        .background(Color(.systemGroupedBackground))
        .modelContainer(for: [DailyProgress.self, UserSettings.self])
}
