//
//  PracticeMenuView.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI
import SwiftData

enum PracticeCategory: String, Codable, CaseIterable {
    case all = "All"
    case cet4 = "CET-4"
    case cet6 = "CET-6"

    var icon: String {
        switch self {
        case .all: return "books.vertical.fill"
        case .cet4: return "4.square.fill"
        case .cet6: return "6.square.fill"
        }
    }
}

struct TestType {
    let id: SessionType
    let icon: String
    let title: String
    let description: String
    let color: Color
    let gradientColors: [Color]

    init(id: SessionType, icon: String, title: String, description: String, color: Color) {
        self.id = id
        self.icon = icon
        self.title = title
        self.description = description
        self.color = color
        self.gradientColors = [color, color.opacity(0.7)]
    }
}

struct PracticeMenuView: View {
    @State private var selectedWordCount: Int = 10
    @State private var selectedCategory: PracticeCategory = .all
    @State private var selectedTestType: SessionType? = nil
    @State private var showingTest = false
    @State private var hasAppeared = false

    private let testTypes: [TestType] = [
        TestType(
            id: .multipleChoice,
            icon: "list.bullet.circle.fill",
            title: "选择题",
            description: "从四个选项中选择正确答案",
            color: .blue
        ),
        TestType(
            id: .multiSelect,
            icon: "checklist.checked",
            title: "多选题",
            description: "选择所有正确的中文释义",
            color: .purple
        ),
        TestType(
            id: .fillInBlank,
            icon: "pencil.circle.fill",
            title: "填空题",
            description: "根据中文意思填写英文单词",
            color: .green
        ),
        TestType(
            id: .listening,
            icon: "headphones.circle.fill",
            title: "听力题",
            description: "听发音选择正确的单词",
            color: .orange
        ),
        TestType(
            id: .trueFalse,
            icon: "checkmark.circle.fill",
            title: "判断题",
            description: "判断中文翻译是否正确",
            color: .pink
        )
    ]

    private let wordCountOptions = [10, 20, 30, 50]

    private var estimatedTime: Int {
        // Estimate ~30 seconds per question
        selectedWordCount / 2
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Test type selection
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "选择测试类型", icon: "sparkles")

                        ForEach(Array(testTypes.enumerated()), id: \.element.id) { index, testType in
                            TestTypeCard(
                                testType: testType,
                                isSelected: selectedTestType == testType.id,
                                action: {
                                    HapticManager.shared.selection()
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                        selectedTestType = testType.id
                                    }
                                }
                            )
                            .padding(.horizontal)
                            .offset(y: hasAppeared ? 0 : 30)
                            .opacity(hasAppeared ? 1 : 0)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1),
                                value: hasAppeared
                            )
                        }
                    }

                    // Word count selector
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            SectionHeader(title: "题目数量", icon: "number.circle.fill")

                            Spacer()

                            // Time estimate with enhanced styling
                            HStack(spacing: 5) {
                                Image(systemName: "clock.fill")
                                    .font(.caption2)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.orange, .yellow],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                Text("约 \(estimatedTime) 分钟")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [.orange.opacity(0.1), .yellow.opacity(0.05)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.orange.opacity(0.15), lineWidth: 1)
                            )
                            .padding(.trailing)
                        }

                        HStack(spacing: 10) {
                            ForEach(wordCountOptions, id: \.self) { count in
                                WordCountButton(
                                    count: count,
                                    isSelected: selectedWordCount == count,
                                    action: {
                                        HapticManager.shared.selection()
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedWordCount = count
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Category filter
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(title: "词库分类", icon: "folder.fill")

                        HStack(spacing: 10) {
                            ForEach(PracticeCategory.allCases, id: \.self) { category in
                                CategoryButton(
                                    category: category,
                                    isSelected: selectedCategory == category,
                                    action: {
                                        HapticManager.shared.selection()
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedCategory = category
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Summary and Start button
                    VStack(spacing: 16) {
                        // Selection summary
                        if let testType = selectedTestType,
                           let selected = testTypes.first(where: { $0.id == testType }) {
                            HStack(spacing: 12) {
                                Image(systemName: selected.icon)
                                    .font(.title3)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: selected.gradientColors,
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("已选择: \(selected.title)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    Text("\(selectedWordCount) 道题 · \(selectedCategory.rawValue)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(.green)
                                    .symbolEffect(.bounce, value: selectedTestType)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selected.color.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selected.color.opacity(0.2), lineWidth: 1)
                            )
                            .padding(.horizontal)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .opacity
                            ))
                        }

                        // Start button
                        Button(action: {
                            if selectedTestType != nil {
                                HapticManager.shared.impact()
                                showingTest = true
                            }
                        }) {
                            HStack(spacing: 10) {
                                if selectedTestType != nil {
                                    Image(systemName: "play.fill")
                                        .font(.headline)
                                }
                                Text("开始测试")
                                    .font(.headline)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Group {
                                    if let testType = selectedTestType,
                                       let selected = testTypes.first(where: { $0.id == testType }) {
                                        LinearGradient(
                                            colors: selected.gradientColors,
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    } else {
                                        LinearGradient(
                                            colors: [Color.gray, Color.gray.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    }
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(
                                color: selectedTestType != nil ?
                                    (testTypes.first(where: { $0.id == selectedTestType })?.color ?? .clear).opacity(0.3) :
                                    .clear,
                                radius: 8, y: 4
                            )
                        }
                        .disabled(selectedTestType == nil)
                        .scaleEffect(selectedTestType == nil ? 0.98 : 1.0)
                        .animation(.spring(response: 0.3), value: selectedTestType)
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)
                }
                .padding(.vertical)
            }
            .navigationTitle("练习测试")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: $showingTest) {
                if let testType = selectedTestType {
                    TestViewRouter(
                        testType: testType,
                        wordCount: selectedWordCount,
                        category: selectedCategory
                    )
                }
            }
            .onAppear {
                guard !hasAppeared else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    hasAppeared = true
                }
            }
        }
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String
    let icon: String

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.accentColor.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 5,
                            endRadius: 18
                        )
                    )
                    .frame(width: 32, height: 32)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.accentColor.opacity(0.12), .accentColor.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)

                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.accentColor, .accentColor.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .scaleEffect(appeared ? 1 : 0.8)

            Text(title)
                .font(.headline)
        }
        .padding(.horizontal)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -10)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}

// MARK: - Test Type Card

struct TestTypeCard: View {
    let testType: TestType
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isSelected ? testType.gradientColors : [testType.color.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: testType.color.opacity(isSelected ? 0.3 : 0), radius: 6, y: 3)

                    Image(systemName: testType.icon)
                        .font(.system(size: 26))
                        .foregroundStyle(isSelected ? .white : testType.color)
                        .symbolEffect(.bounce, value: isSelected)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(testType.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(testType.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? testType.color : Color.gray.opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: 26, height: 26)

                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: testType.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 26, height: 26)

                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: isSelected ?
                                [testType.color.opacity(0.12), testType.color.opacity(0.06)] :
                                [Color(.systemBackground), Color(.systemBackground)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: isSelected ? testType.gradientColors : [Color.gray.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? testType.color.opacity(0.15) : .clear,
                radius: 8, y: 4
            )
        }
        .buttonStyle(TestTypeButtonStyle())
    }
}

struct TestTypeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Word Count Button

private struct WordCountButton: View {
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(count)")
                    .font(.title3)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .contentTransition(.numericText())

                Text("题")
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.9) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [.accentColor, .accentColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        LinearGradient(
                            colors: [Color.gray.opacity(0.12), Color.gray.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: isSelected ? Color.accentColor.opacity(0.3) : .clear, radius: 4, y: 2)
        }
        .buttonStyle(TestTypeButtonStyle())
    }
}

// MARK: - Category Button

private struct CategoryButton: View {
    let category: PracticeCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white : .accentColor)

                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [.accentColor, .accentColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        LinearGradient(
                            colors: [Color.gray.opacity(0.12), Color.gray.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: isSelected ? Color.accentColor.opacity(0.3) : .clear, radius: 4, y: 2)
        }
        .buttonStyle(TestTypeButtonStyle())
    }
}

struct TestViewRouter: View {
    let testType: SessionType
    let wordCount: Int
    let category: PracticeCategory
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        switch testType {
        case .multipleChoice:
            MultipleChoiceView(wordCount: wordCount, category: category)
                .environment(\.modelContext, modelContext)
        case .multiSelect:
            MultiSelectQuizView(wordCount: wordCount, category: category)
                .environment(\.modelContext, modelContext)
        case .fillInBlank:
            FillInBlankView(wordCount: wordCount, category: category)
                .environment(\.modelContext, modelContext)
        case .listening:
            ListeningTestView(wordCount: wordCount, category: category)
                .environment(\.modelContext, modelContext)
        case .trueFalse:
            TrueFalseView(wordCount: wordCount, category: category)
                .environment(\.modelContext, modelContext)
        default:
            Text("Test type not implemented")
        }
    }
}

#Preview {
    PracticeMenuView()
}
