//
//  LearningSetupSheet.swift
//  LingoLearn
//
//  Setup options before starting a learning session
//

import SwiftUI
import SwiftData

struct LearningSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let mode: LearningMode
    let onStart: (WordCategory?) -> Void

    @State private var selectedCategory: CategoryOption = .all
    @State private var wordCounts: [CategoryOption: Int] = [:]
    @State private var showContent = false

    enum CategoryOption: String, CaseIterable {
        case all = "全部"
        case cet4 = "CET-4"
        case cet6 = "CET-6"

        var wordCategory: WordCategory? {
            switch self {
            case .all: return nil
            case .cet4: return .cet4
            case .cet6: return .cet6
            }
        }

        var icon: String {
            switch self {
            case .all: return "books.vertical.fill"
            case .cet4: return "4.square.fill"
            case .cet6: return "6.square.fill"
            }
        }

        var color: Color {
            switch self {
            case .all: return .purple
            case .cet4: return .blue
            case .cet6: return .orange
            }
        }

        var description: String {
            switch self {
            case .all: return "学习所有类别的单词"
            case .cet4: return "大学英语四级核心词汇"
            case .cet6: return "大学英语六级核心词汇"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header illustration
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [selectedCategory.color.opacity(0.2), .clear],
                                center: .center,
                                startRadius: 30,
                                endRadius: 80
                            )
                        )
                        .frame(width: 140, height: 140)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [selectedCategory.color.opacity(0.15), selectedCategory.color.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)

                    Image(systemName: mode == .learning ? "book.fill" : "arrow.clockwise")
                        .font(.system(size: 44))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [selectedCategory.color, selectedCategory.color.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .symbolEffect(.bounce, value: selectedCategory)
                }
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.8)

                // Title
                VStack(spacing: 6) {
                    Text(mode == .learning ? "开始学习" : "开始复习")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("选择要学习的词汇类别")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .opacity(showContent ? 1 : 0)

                // Category options
                VStack(spacing: 12) {
                    ForEach(CategoryOption.allCases, id: \.self) { option in
                        CategoryOptionRow(
                            option: option,
                            wordCount: wordCounts[option] ?? 0,
                            isSelected: selectedCategory == option,
                            onSelect: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    HapticManager.shared.selection()
                                    selectedCategory = option
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                Spacer()

                // Start button
                Button(action: {
                    HapticManager.shared.impact()
                    dismiss()
                    onStart(selectedCategory.wordCategory)
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: mode == .learning ? "play.fill" : "arrow.clockwise")
                        Text("开始\(mode == .learning ? "学习" : "复习")")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [selectedCategory.color, selectedCategory.color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: selectedCategory.color.opacity(0.3), radius: 10, y: 5)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
                .opacity(showContent ? 1 : 0)
            }
            .padding(.top, 24)
            .navigationTitle("学习设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            loadWordCounts()
            withAnimation(.easeOut(duration: 0.4)) {
                showContent = true
            }
        }
    }

    private func loadWordCounts() {
        let today = Date()

        // Count for each category
        for option in CategoryOption.allCases {
            var count = 0

            switch mode {
            case .learning:
                let minTimes = AppConstants.Learning.minTimesStudiedForLearning

                if let category = option.wordCategory {
                    let categoryRaw = category.rawValue
                    let descriptor = FetchDescriptor<Word>(
                        predicate: #Predicate<Word> { word in
                            word.timesStudied < minTimes && word.category.rawValue == categoryRaw
                        }
                    )
                    count = (try? modelContext.fetchCount(descriptor)) ?? 0
                } else {
                    let descriptor = FetchDescriptor<Word>(
                        predicate: #Predicate<Word> { word in
                            word.timesStudied < minTimes
                        }
                    )
                    count = (try? modelContext.fetchCount(descriptor)) ?? 0
                }

            case .review:
                if let category = option.wordCategory {
                    let categoryRaw = category.rawValue
                    let descriptor = FetchDescriptor<Word>(
                        predicate: #Predicate<Word> { word in
                            word.nextReviewDate != nil && word.nextReviewDate! <= today && word.category.rawValue == categoryRaw
                        }
                    )
                    count = (try? modelContext.fetchCount(descriptor)) ?? 0
                } else {
                    let descriptor = FetchDescriptor<Word>(
                        predicate: #Predicate<Word> { word in
                            word.nextReviewDate != nil && word.nextReviewDate! <= today
                        }
                    )
                    count = (try? modelContext.fetchCount(descriptor)) ?? 0
                }
            }

            wordCounts[option] = count
        }
    }
}

// MARK: - Category Option Row

private struct CategoryOptionRow: View {
    let option: LearningSetupSheet.CategoryOption
    let wordCount: Int
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var appeared = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [option.color.opacity(isSelected ? 0.2 : 0.1), option.color.opacity(isSelected ? 0.1 : 0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: option.icon)
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [option.color, option.color.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(option.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Word count
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(wordCount)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(option.color)

                    Text("可学习")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? option.color : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(option.color)
                            .frame(width: 14, height: 14)
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
                        isSelected
                            ? LinearGradient(colors: [option.color.opacity(0.4), option.color.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.gray.opacity(0.15)], startPoint: .top, endPoint: .bottom),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(color: isSelected ? option.color.opacity(0.15) : .black.opacity(0.05), radius: isSelected ? 8 : 4, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
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
    LearningSetupSheet(mode: .learning) { category in
        print("Selected category: \(String(describing: category))")
    }
    .modelContainer(for: Word.self)
}
