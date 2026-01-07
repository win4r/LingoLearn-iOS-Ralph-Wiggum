//
//  WordRootCard.swift
//  LingoLearn
//
//  Shows common word roots and prefixes/suffixes for learning
//

import SwiftUI

struct WordRootCard: View {
    @State private var currentRoot: WordRoot
    @State private var showContent = false
    @State private var isExpanded = false

    private static let wordRoots: [WordRoot] = [
        WordRoot(
            root: "vis/vid",
            meaning: "看",
            origin: "拉丁语",
            examples: [
                WordExample(word: "visible", meaning: "可见的"),
                WordExample(word: "vision", meaning: "视力"),
                WordExample(word: "video", meaning: "视频"),
                WordExample(word: "evidence", meaning: "证据")
            ]
        ),
        WordRoot(
            root: "aud",
            meaning: "听",
            origin: "拉丁语",
            examples: [
                WordExample(word: "audio", meaning: "音频"),
                WordExample(word: "audience", meaning: "观众"),
                WordExample(word: "audible", meaning: "听得见的"),
                WordExample(word: "audition", meaning: "试听")
            ]
        ),
        WordRoot(
            root: "port",
            meaning: "携带",
            origin: "拉丁语",
            examples: [
                WordExample(word: "transport", meaning: "运输"),
                WordExample(word: "import", meaning: "进口"),
                WordExample(word: "export", meaning: "出口"),
                WordExample(word: "portable", meaning: "便携的")
            ]
        ),
        WordRoot(
            root: "scrib/script",
            meaning: "写",
            origin: "拉丁语",
            examples: [
                WordExample(word: "describe", meaning: "描述"),
                WordExample(word: "script", meaning: "剧本"),
                WordExample(word: "subscribe", meaning: "订阅"),
                WordExample(word: "prescription", meaning: "处方")
            ]
        ),
        WordRoot(
            root: "dict",
            meaning: "说",
            origin: "拉丁语",
            examples: [
                WordExample(word: "dictionary", meaning: "字典"),
                WordExample(word: "predict", meaning: "预测"),
                WordExample(word: "contradict", meaning: "反驳"),
                WordExample(word: "verdict", meaning: "裁决")
            ]
        ),
        WordRoot(
            root: "duct",
            meaning: "引导",
            origin: "拉丁语",
            examples: [
                WordExample(word: "conduct", meaning: "引导"),
                WordExample(word: "produce", meaning: "生产"),
                WordExample(word: "reduce", meaning: "减少"),
                WordExample(word: "introduce", meaning: "介绍")
            ]
        ),
        WordRoot(
            root: "spec/spect",
            meaning: "看",
            origin: "拉丁语",
            examples: [
                WordExample(word: "spectacle", meaning: "眼镜"),
                WordExample(word: "inspect", meaning: "检查"),
                WordExample(word: "respect", meaning: "尊重"),
                WordExample(word: "perspective", meaning: "观点")
            ]
        ),
        WordRoot(
            root: "ject",
            meaning: "投掷",
            origin: "拉丁语",
            examples: [
                WordExample(word: "project", meaning: "项目"),
                WordExample(word: "reject", meaning: "拒绝"),
                WordExample(word: "inject", meaning: "注射"),
                WordExample(word: "subject", meaning: "主题")
            ]
        ),
        WordRoot(
            root: "fac/fact",
            meaning: "做",
            origin: "拉丁语",
            examples: [
                WordExample(word: "factory", meaning: "工厂"),
                WordExample(word: "manufacture", meaning: "制造"),
                WordExample(word: "factor", meaning: "因素"),
                WordExample(word: "satisfaction", meaning: "满意")
            ]
        ),
        WordRoot(
            root: "form",
            meaning: "形式",
            origin: "拉丁语",
            examples: [
                WordExample(word: "transform", meaning: "变形"),
                WordExample(word: "inform", meaning: "通知"),
                WordExample(word: "perform", meaning: "表演"),
                WordExample(word: "uniform", meaning: "制服")
            ]
        )
    ]

    init() {
        _currentRoot = State(initialValue: Self.wordRoots.randomElement() ?? Self.wordRoots[0])
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

                        Image(systemName: "character.book.closed.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.teal, .cyan],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    Text("词根词缀")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                // Refresh button
                Button(action: refreshRoot) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(6)
                        .background(Circle().fill(Color(.secondarySystemGroupedBackground)))
                }
            }

            // Root display
            VStack(spacing: 12) {
                // Main root info
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        // Root with origin badge
                        HStack(spacing: 8) {
                            Text(currentRoot.root)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.teal, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Text(currentRoot.origin)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.teal.opacity(0.8))
                                .clipShape(Capsule())
                        }

                        // Meaning
                        Text("含义：\(currentRoot.meaning)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Expand/collapse button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            HapticManager.shared.impact()
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.teal)
                    }
                }

                // Examples grid
                if isExpanded {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(currentRoot.examples) { example in
                            ExampleWordView(example: example, rootText: currentRoot.root)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    // Show compact examples
                    HStack(spacing: 8) {
                        ForEach(currentRoot.examples.prefix(3)) { example in
                            Text(example.word)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.teal)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(Color.teal.opacity(0.1))
                                )
                        }

                        if currentRoot.examples.count > 3 {
                            Text("+\(currentRoot.examples.count - 3)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
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
                        colors: [.teal.opacity(0.2), .cyan.opacity(0.15)],
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
            withAnimation(.easeOut(duration: 0.4).delay(0.45)) {
                showContent = true
            }
        }
    }

    private func refreshRoot() {
        HapticManager.shared.impact()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            var newRoot = Self.wordRoots.randomElement() ?? Self.wordRoots[0]
            // Ensure we get a different root
            while newRoot.root == currentRoot.root && Self.wordRoots.count > 1 {
                newRoot = Self.wordRoots.randomElement() ?? Self.wordRoots[0]
            }
            currentRoot = newRoot
            isExpanded = false
        }
    }
}

// MARK: - Models

private struct WordRoot: Identifiable {
    let id = UUID()
    let root: String
    let meaning: String
    let origin: String
    let examples: [WordExample]
}

private struct WordExample: Identifiable {
    let id = UUID()
    let word: String
    let meaning: String
}

// MARK: - Example Word View

private struct ExampleWordView: View {
    let example: WordExample
    let rootText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Word with highlighted root
            highlightedWord

            // Meaning
            Text(example.meaning)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
    }

    private var highlightedWord: some View {
        let word = example.word.lowercased()
        let rootParts = rootText.lowercased().split(separator: "/").map(String.init)

        // Find the root in the word
        var foundRoot: String?
        var rootRange: Range<String.Index>?

        for part in rootParts {
            if let range = word.range(of: part) {
                foundRoot = part
                rootRange = range
                break
            }
        }

        if let foundRoot = foundRoot, let range = rootRange {
            let prefix = String(word[..<range.lowerBound])
            let suffix = String(word[range.upperBound...])

            return HStack(spacing: 0) {
                if !prefix.isEmpty {
                    Text(prefix)
                        .foregroundStyle(.primary)
                }
                Text(foundRoot)
                    .fontWeight(.bold)
                    .foregroundStyle(.teal)
                if !suffix.isEmpty {
                    Text(suffix)
                        .foregroundStyle(.primary)
                }
            }
            .font(.subheadline)
            .eraseToAnyView()
        } else {
            return Text(example.word)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .eraseToAnyView()
        }
    }
}

// Helper to erase type
private extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}

#Preview {
    WordRootCard()
        .padding()
        .background(Color(.systemGroupedBackground))
}
