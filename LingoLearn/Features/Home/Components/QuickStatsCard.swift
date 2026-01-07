//
//  QuickStatsCard.swift
//  LingoLearn
//
//  Quick overview of key learning statistics
//

import SwiftUI
import SwiftData

struct QuickStatsCard: View {
    @Environment(\.modelContext) private var modelContext
    @State private var totalWords: Int = 0
    @State private var masteredWords: Int = 0
    @State private var overallAccuracy: Double = 0
    @State private var totalStudyTime: TimeInterval = 0
    @State private var showContent = false

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

                        Image(systemName: "chart.pie.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.indigo, .purple],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    Text("学习概览")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                        .frame(width: 32, height: 32)

                    Circle()
                        .trim(from: 0, to: CGFloat(masteredWords) / max(CGFloat(totalWords), 1))
                        .stroke(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(Double(masteredWords) / max(Double(totalWords), 1) * 100))%")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }

            // Stats grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                QuickStatItem(
                    icon: "book.closed.fill",
                    value: "\(totalWords)",
                    label: "总单词",
                    color: .blue
                )

                QuickStatItem(
                    icon: "checkmark.seal.fill",
                    value: "\(masteredWords)",
                    label: "已掌握",
                    color: .green
                )

                QuickStatItem(
                    icon: "percent",
                    value: String(format: "%.0f%%", overallAccuracy * 100),
                    label: "准确率",
                    color: overallAccuracy >= 0.8 ? .green : (overallAccuracy >= 0.6 ? .orange : .red)
                )

                QuickStatItem(
                    icon: "clock.fill",
                    value: formatStudyTime(totalStudyTime),
                    label: "学习时长",
                    color: .purple
                )
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
            loadStats()
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                showContent = true
            }
        }
    }

    private func loadStats() {
        // Load word stats
        let wordDescriptor = FetchDescriptor<Word>()
        do {
            let words = try modelContext.fetch(wordDescriptor)
            totalWords = words.count
            masteredWords = words.filter { $0.masteryLevel == .mastered }.count

            // Calculate overall accuracy
            let totalStudied = words.reduce(0) { $0 + $1.timesStudied }
            let totalCorrect = words.reduce(0) { $0 + $1.timesCorrect }
            overallAccuracy = totalStudied > 0 ? Double(totalCorrect) / Double(totalStudied) : 0
        } catch {
            AppLogger.logError("Failed to load word stats", error: error, category: AppLogger.data)
        }

        // Load study time from user stats
        let statsDescriptor = FetchDescriptor<UserStats>()
        if let stats = try? modelContext.fetch(statsDescriptor).first {
            totalStudyTime = stats.totalStudyTime
        }
    }

    private func formatStudyTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes < 60 {
            return "\(max(minutes, 0))分钟"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)小时"
            } else {
                return "\(hours)时\(mins)分"
            }
        }
    }
}

// MARK: - Quick Stat Item

private struct QuickStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
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
                    .font(.subheadline)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .scaleEffect(appeared ? 1 : 0.5)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.05))
        )
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.1)) {
                appeared = true
            }
        }
    }
}

#Preview {
    QuickStatsCard()
        .padding()
        .background(Color(.systemGroupedBackground))
        .modelContainer(for: [Word.self, UserStats.self])
}
