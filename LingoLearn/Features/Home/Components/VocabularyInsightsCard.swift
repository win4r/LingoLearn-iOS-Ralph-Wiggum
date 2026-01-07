//
//  VocabularyInsightsCard.swift
//  LingoLearn
//
//  Vocabulary breakdown and insights visualization
//

import SwiftUI
import SwiftData

struct VocabularyInsightsCard: View {
    @Environment(\.modelContext) private var modelContext
    @State private var totalWords: Int = 0
    @State private var masteryBreakdown: [MasteryLevel: Int] = [:]
    @State private var categoryBreakdown: [WordCategory: Int] = [:]
    @State private var showContent = false
    @State private var selectedView: InsightView = .mastery

    enum InsightView: String, CaseIterable {
        case mastery = "掌握度"
        case category = "分类"
    }

    private var masteryPercentage: Double {
        guard totalWords > 0 else { return 0 }
        let mastered = masteryBreakdown[.mastered] ?? 0
        return Double(mastered) / Double(totalWords)
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

                        Image(systemName: "chart.pie.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    Text("词汇分析")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                // View toggle
                HStack(spacing: 4) {
                    ForEach(InsightView.allCases, id: \.self) { view in
                        Text(view.rawValue)
                            .font(.caption2)
                            .fontWeight(selectedView == view ? .semibold : .regular)
                            .foregroundStyle(selectedView == view ? .white : .secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(selectedView == view ? Color.cyan : Color.clear)
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    HapticManager.shared.selection()
                                    selectedView = view
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

            // Content based on selected view
            if selectedView == .mastery {
                masteryView
            } else {
                categoryView
            }

            // Total words summary
            HStack {
                Text("总词汇量")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(totalWords) 个单词")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.cyan)
            }
            .padding(.top, 4)
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
                        colors: [.cyan.opacity(0.2), .blue.opacity(0.15)],
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
            loadData()
            withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
                showContent = true
            }
        }
    }

    // MARK: - Mastery View

    private var masteryView: some View {
        VStack(spacing: 12) {
            // Progress ring
            HStack(spacing: 20) {
                // Ring chart
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: masteryPercentage)
                        .stroke(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(Int(masteryPercentage * 100))%")
                            .font(.headline)
                            .fontWeight(.bold)

                        Text("已掌握")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // Mastery level bars
                VStack(spacing: 8) {
                    ForEach([MasteryLevel.mastered, .reviewing, .learning, .new], id: \.self) { level in
                        MasteryLevelBar(
                            level: level,
                            count: masteryBreakdown[level] ?? 0,
                            total: totalWords
                        )
                    }
                }
            }
        }
    }

    // MARK: - Category View

    private var categoryView: some View {
        VStack(spacing: 10) {
            ForEach(WordCategory.allCases, id: \.self) { category in
                CategoryBar(
                    category: category,
                    count: categoryBreakdown[category] ?? 0,
                    total: totalWords
                )
            }
        }
    }

    // MARK: - Data Loading

    private func loadData() {
        // Fetch all words and count in memory (SwiftData predicates don't support enum rawValue access)
        let descriptor = FetchDescriptor<Word>()
        guard let allWords = try? modelContext.fetch(descriptor) else { return }

        totalWords = allWords.count

        // Get mastery breakdown
        for level in MasteryLevel.allCases {
            masteryBreakdown[level] = allWords.filter { $0.masteryLevel == level }.count
        }

        // Get category breakdown
        for category in WordCategory.allCases {
            categoryBreakdown[category] = allWords.filter { $0.category == category }.count
        }
    }
}

// MARK: - Mastery Level Bar

private struct MasteryLevelBar: View {
    let level: MasteryLevel
    let count: Int
    let total: Int

    @State private var animatedWidth: CGFloat = 0

    private var percentage: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(count) / CGFloat(total)
    }

    var body: some View {
        HStack(spacing: 8) {
            // Icon
            Image(systemName: level.icon)
                .font(.caption2)
                .foregroundStyle(level.color)
                .frame(width: 16)

            // Label
            Text(level.displayName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .leading)

            // Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(level.color)
                        .frame(width: animatedWidth * geometry.size.width, height: 6)
                }
            }
            .frame(height: 6)

            // Count
            Text("\(count)")
                .font(.caption2)
                .fontWeight(.medium)
                .frame(width: 30, alignment: .trailing)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                animatedWidth = percentage
            }
        }
    }
}

// MARK: - Category Bar

private struct CategoryBar: View {
    let category: WordCategory
    let count: Int
    let total: Int

    @State private var animatedWidth: CGFloat = 0

    private var percentage: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(count) / CGFloat(total)
    }

    private var categoryColor: Color {
        switch category {
        case .cet4: return .blue
        case .cet6: return .orange
        }
    }

    private var categoryIcon: String {
        switch category {
        case .cet4: return "4.square.fill"
        case .cet6: return "6.square.fill"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: categoryIcon)
                .font(.subheadline)
                .foregroundStyle(categoryColor)
                .frame(width: 24)

            // Label
            Text(category.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 50, alignment: .leading)

            // Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [categoryColor, categoryColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: animatedWidth * geometry.size.width, height: 8)
                }
            }
            .frame(height: 8)

            // Count and percentage
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.semibold)

                Text("\(Int(percentage * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 40, alignment: .trailing)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                animatedWidth = percentage
            }
        }
    }
}

#Preview {
    VocabularyInsightsCard()
        .padding()
        .background(Color(.systemGroupedBackground))
        .modelContainer(for: Word.self)
}
