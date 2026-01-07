//
//  ReviewForecastCard.swift
//  LingoLearn
//
//  Shows upcoming review schedule for the next 7 days
//

import SwiftUI
import SwiftData

struct ReviewForecastCard: View {
    @Environment(\.modelContext) private var modelContext
    @State private var forecastData: [DayForecast] = []
    @State private var showContent = false
    @State private var totalUpcoming: Int = 0

    struct DayForecast: Identifiable {
        let id = UUID()
        let date: Date
        let count: Int
        let dayName: String
        let isToday: Bool
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

                        Image(systemName: "calendar.badge.clock")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.indigo, .purple],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    Text("复习预报")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                // Total count badge
                if totalUpcoming > 0 {
                    Text("\(totalUpcoming)个待复习")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.indigo)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.indigo.opacity(0.1))
                        )
                }
            }

            // 7-day forecast
            HStack(spacing: 8) {
                ForEach(forecastData) { day in
                    ForecastDayView(day: day, maxCount: forecastData.map { $0.count }.max() ?? 1)
                }
            }

            // Legend
            HStack(spacing: 16) {
                ForecastLegendItem(color: .green, label: "轻松")
                ForecastLegendItem(color: .orange, label: "适中")
                ForecastLegendItem(color: .red, label: "繁忙")
            }
            .font(.caption2)
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
            loadForecast()
            withAnimation(.easeOut(duration: 0.4).delay(0.4)) {
                showContent = true
            }
        }
    }

    private func loadForecast() {
        let calendar = Calendar.current
        var forecast: [DayForecast] = []
        var total = 0

        for dayOffset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: Date())) ?? Date()
            let nextDay = calendar.date(byAdding: .day, value: 1, to: date) ?? Date()

            let descriptor = FetchDescriptor<Word>(
                predicate: #Predicate<Word> { word in
                    word.nextReviewDate != nil &&
                    word.nextReviewDate! >= date &&
                    word.nextReviewDate! < nextDay
                }
            )

            let count = (try? modelContext.fetchCount(descriptor)) ?? 0
            total += count

            let dayName: String
            if dayOffset == 0 {
                dayName = "今"
            } else if dayOffset == 1 {
                dayName = "明"
            } else {
                let weekday = calendar.component(.weekday, from: date)
                let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
                dayName = weekdays[weekday - 1]
            }

            forecast.append(DayForecast(
                date: date,
                count: count,
                dayName: dayName,
                isToday: dayOffset == 0
            ))
        }

        forecastData = forecast
        totalUpcoming = total
    }
}

// MARK: - Forecast Day View

private struct ForecastDayView: View {
    let day: ReviewForecastCard.DayForecast
    let maxCount: Int

    private var intensity: Double {
        guard maxCount > 0 else { return 0 }
        return Double(day.count) / Double(maxCount)
    }

    private var barColor: Color {
        if day.count == 0 {
            return .gray.opacity(0.2)
        } else if intensity < 0.33 {
            return .green
        } else if intensity < 0.66 {
            return .orange
        } else {
            return .red
        }
    }

    private var barHeight: CGFloat {
        let minHeight: CGFloat = 8
        let maxHeight: CGFloat = 50
        guard maxCount > 0 else { return minHeight }
        return minHeight + CGFloat(intensity) * (maxHeight - minHeight)
    }

    var body: some View {
        VStack(spacing: 6) {
            // Count
            Text(day.count > 0 ? "\(day.count)" : "-")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(day.count > 0 ? .primary : .secondary)

            // Bar
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [barColor, barColor.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: barHeight)

            // Day label
            Text(day.dayName)
                .font(.caption2)
                .fontWeight(day.isToday ? .bold : .regular)
                .foregroundStyle(day.isToday ? .indigo : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(day.isToday ? Color.indigo.opacity(0.08) : Color.clear)
        )
    }
}

// MARK: - Forecast Legend Item

private struct ForecastLegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
        }
    }
}

#Preview {
    ReviewForecastCard()
        .padding()
        .background(Color(.systemGroupedBackground))
        .modelContainer(for: Word.self)
}
