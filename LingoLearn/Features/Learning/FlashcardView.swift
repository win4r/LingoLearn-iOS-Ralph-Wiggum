//
//  FlashcardView.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI
import SwiftData

struct FlashcardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: FlashcardViewModel?
    @State private var autoPlayPronunciation: Bool = false
    @State private var speechRate: SpeechRate = .normal
    @State private var hasAppeared = false
    @StateObject private var onboarding = OnboardingManager.shared
    @State private var sessionStartTime: Date = Date()
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showCategoryFilter = false
    @State private var focusModeEnabled = false

    let mode: LearningMode
    var categoryFilter: WordCategory? = nil

    private var progress: Double {
        guard let vm = viewModel, !vm.currentWords.isEmpty else { return 0 }
        return Double(vm.currentIndex) / Double(vm.currentWords.count)
    }

    private var formattedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(.systemGroupedBackground),
                    Color(.systemGroupedBackground).opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                // Header with progress
                headerSection

                // Progress bar
                if let vm = viewModel, !vm.currentWords.isEmpty {
                    progressBarSection
                        .padding(.horizontal)
                }

                // Card Stack
                if let vm = viewModel {
                    if vm.isLoading {
                        Spacer()
                        loadingView
                        Spacer()
                    } else if let error = vm.errorMessage {
                        Spacer()
                        errorView(message: error)
                        Spacer()
                    } else if vm.hasMoreCards {
                        FlashcardStack(
                            words: vm.currentWords,
                            currentIndex: vm.currentIndex,
                            onSwipe: { direction in
                                vm.handleSwipe(direction: direction)
                            },
                            autoPlayPronunciation: autoPlayPronunciation,
                            speechRate: speechRate
                        )
                        .padding(.horizontal)
                    } else if !vm.hasMoreCards && !vm.currentWords.isEmpty {
                        Spacer()
                        completionView
                        Spacer()
                    } else {
                        Spacer()
                        noWordsView
                        Spacer()
                    }
                } else {
                    Spacer()
                    loadingView
                    Spacer()
                }

                // Instructions (hidden in focus mode)
                if !focusModeEnabled {
                    instructionsSection
                }

                Spacer(minLength: 16)
            }

            // First-time swipe hint overlay
            if onboarding.showSwipeHint && viewModel?.hasMoreCards == true {
                VStack {
                    Spacer()
                    SwipeGestureHint()
                        .padding(.bottom, 120)
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .navigationTitle(mode == .learning ? "学习模式" : "复习模式")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                viewModel = FlashcardViewModel(modelContext: modelContext, mode: mode, categoryFilter: categoryFilter)
            }
            loadAutoPlaySetting()
            startTimer()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                hasAppeared = true
            }
        }
        .onDisappear {
            // Clean up to prevent memory leak when navigating away
            stopTimer()
            hasAppeared = false
            viewModel = nil
        }
        .focusable()
        .onKeyPress(.leftArrow) {
            if let vm = viewModel, vm.hasMoreCards {
                vm.handleSwipe(direction: .left)
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.rightArrow) {
            if let vm = viewModel, vm.hasMoreCards {
                vm.handleSwipe(direction: .right)
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.upArrow) {
            if let vm = viewModel, vm.hasMoreCards {
                vm.handleSwipe(direction: .up)
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.downArrow) {
            if let vm = viewModel, vm.hasMoreCards {
                vm.handleSwipe(direction: .down)
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.space) {
            // Space bar to flip card - handled in FlashcardItem via tap gesture
            return .ignored
        }
        .sheet(isPresented: Binding(
            get: { viewModel?.showSummary ?? false },
            set: { if !$0 { viewModel?.showSummary = false } }
        )) {
            if let vm = viewModel {
                SessionSummarySheet(
                    stats: vm.sessionStats,
                    newlyUnlockedAchievements: vm.newlyUnlockedAchievements,
                    dailyGoalReached: vm.dailyGoalJustReached,
                    onContinue: {
                        vm.reset()
                    },
                    onHome: {
                        dismiss()
                    }
                )
            }
        }
        .masteryCelebration(
            isShowing: Binding(
                get: { viewModel?.showMasteryCelebration ?? false },
                set: { if !$0 { viewModel?.showMasteryCelebration = false } }
            ),
            wordEnglish: viewModel?.masteredWordEnglish ?? ""
        )
    }

    private var headerSection: some View {
        HStack(spacing: 16) {
            if let vm = viewModel {
                if !focusModeEnabled {
                    // Previous card button
                    Button(action: {
                        HapticManager.shared.impact()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            vm.goToPreviousCard()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.caption.weight(.bold))
                            Text("上一个")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(vm.canGoBack ? .blue : .gray.opacity(0.5))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(vm.canGoBack ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                        )
                    }
                    .disabled(!vm.canGoBack)
                }

                // Current progress badge (always visible)
                HStack(spacing: 6) {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.caption)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.accentColor, .accentColor.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("\(vm.currentIndex)/\(vm.currentWords.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(Capsule())

                Spacer()

                // Focus mode toggle
                Button(action: {
                    HapticManager.shared.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        focusModeEnabled.toggle()
                    }
                }) {
                    Image(systemName: focusModeEnabled ? "eye.slash.fill" : "eye.fill")
                        .font(.subheadline)
                        .foregroundStyle(
                            focusModeEnabled
                                ? LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [.gray, .gray.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                        )
                        .padding(8)
                        .background(
                            Circle()
                                .fill(focusModeEnabled ? Color.orange.opacity(0.15) : Color.gray.opacity(0.1))
                        )
                }

                if !focusModeEnabled {
                    // Timer badge
                    SessionTimerBadge(time: formattedTime)

                    // Stats badges
                    HStack(spacing: 10) {
                        StatBadge(
                            icon: "checkmark.circle.fill",
                            value: vm.sessionStats.knownCount,
                            color: .green
                        )

                        StatBadge(
                            icon: "xmark.circle.fill",
                            value: vm.sessionStats.unknownCount,
                            color: .red
                        )
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var progressBarSection: some View {
        VStack(spacing: 6) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 6)

                    // Progress
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: progressGradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geometry.size.width * progress), height: 6)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)

                    // Glow effect when near completion
                    if progress >= 0.8 {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, geometry.size.width * progress), height: 6)
                            .blur(radius: 4)
                            .opacity(0.5)
                    }
                }
            }
            .frame(height: 6)

            // Progress percentage
            HStack {
                Text("\(Int(progress * 100))% 完成")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())

                Spacer()

                if let vm = viewModel {
                    Text("剩余 \(vm.currentWords.count - vm.currentIndex) 个")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var progressGradientColors: [Color] {
        if progress >= 0.8 {
            return [.green, .mint]
        } else if progress >= 0.5 {
            return [.accentColor, .blue]
        } else {
            return [.orange, .accentColor]
        }
    }

    private var instructionsSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 16) {
                InstructionItem(icon: "hand.thumbsdown.fill", text: "不认识", color: .red, direction: "←")
                InstructionItem(icon: "heart.fill", text: "收藏", color: .yellow, direction: "↑")
                InstructionItem(icon: "hand.thumbsup.fill", text: "认识", color: .green, direction: "→")
                InstructionItem(icon: "bolt.fill", text: "太简单", color: .cyan, direction: "↓")
            }

            HStack(spacing: 4) {
                Image(systemName: "hand.tap.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("点击卡片翻转")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("·")
                    .foregroundStyle(.secondary)
                Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("滑动作答")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
        .padding(.horizontal)
        .offset(y: hasAppeared ? 0 : 50)
        .opacity(hasAppeared ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: hasAppeared)
    }

    private var completionView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.2), .green.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)

                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .symbolEffect(.bounce, value: hasAppeared)
            }

            VStack(spacing: 8) {
                Text("太棒了！")
                    .font(.title)
                    .fontWeight(.bold)

                Text("所有单词已学习完成")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Stats summary
            if let vm = viewModel {
                HStack(spacing: 20) {
                    CompletionStatItem(
                        icon: "checkmark.circle.fill",
                        value: vm.sessionStats.knownCount,
                        label: "认识",
                        color: .green
                    )

                    CompletionStatItem(
                        icon: "xmark.circle.fill",
                        value: vm.sessionStats.unknownCount,
                        label: "不认识",
                        color: .red
                    )

                }
                .padding(.top, 8)
            }
        }
        .scaleEffect(hasAppeared ? 1 : 0.8)
        .opacity(hasAppeared ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: hasAppeared)
    }

    private var noWordsView: some View {
        EmptyStateView(
            icon: mode == .learning ? "book.closed.fill" : "checkmark.circle.fill",
            title: mode == .learning ? "暂无新单词" : "全部复习完成！",
            description: mode == .learning
                ? "所有单词都已学习过，继续复习已学单词吧"
                : "太棒了！没有需要复习的单词，继续保持学习习惯",
            iconColor: mode == .learning ? .blue : .green,
            actionTitle: mode == .learning ? "去复习" : "学习新词",
            action: {
                dismiss()
            }
        )
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.accentColor.opacity(0.15), .accentColor.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.accentColor)
            }

            Text("正在加载单词...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.red.opacity(0.15), .red.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("加载失败")
                    .font(.headline)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                viewModel?.reset()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("重试")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.accentColor, .accentColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
        }
        .padding()
    }

    private func loadAutoPlaySetting() {
        let descriptor = FetchDescriptor<UserSettings>()
        if let settings = try? modelContext.fetch(descriptor).first {
            autoPlayPronunciation = settings.autoPlayPronunciation
            speechRate = settings.speechRate
        }
    }

    private func startTimer() {
        sessionStartTime = Date()
        elapsedTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime = Date().timeIntervalSince(sessionStartTime)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Supporting Views

private struct StatBadge: View {
    let icon: String
    let value: Int
    let color: Color

    @State private var glowOpacity: Double = 0

    var body: some View {
        HStack(spacing: 5) {
            ZStack {
                // Subtle glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 2,
                            endRadius: 10
                        )
                    )
                    .frame(width: 18, height: 18)
                    .opacity(glowOpacity)

                Image(systemName: icon)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            Text("\(value)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.primary, .primary.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.12), color.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            Capsule()
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowOpacity = 1.0
            }
        }
    }
}

private struct SessionTimerBadge: View {
    let time: String

    @State private var pulseAnimation = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "timer")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .purple.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(pulseAnimation ? 1.1 : 1.0)

            Text(time)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.12), Color.purple.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            Capsule()
                .stroke(Color.purple.opacity(0.15), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
}

struct InstructionItem: View {
    let icon: String
    let text: String
    let color: Color
    var direction: String = ""

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.15), color.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 2) {
                Text(text)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                if !direction.isEmpty {
                    Text(direction)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct CompletionStatItem: View {
    let icon: String
    let value: Int
    let label: String
    let color: Color

    @State private var appeared = false
    @State private var glowOpacity: Double = 0

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 28
                        )
                    )
                    .frame(width: 50, height: 50)
                    .opacity(glowOpacity)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.15), color.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .scaleEffect(appeared ? 1 : 0.5)

            Text("\(value)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .contentTransition(.numericText())

            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 70)
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))

                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.08), color.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.1), radius: 6, y: 3)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.3)) {
                glowOpacity = 1.0
            }
        }
    }
}

#Preview {
    NavigationStack {
        FlashcardView(mode: .learning)
            .modelContainer(for: [Word.self, UserStats.self, DailyProgress.self, UserSettings.self])
    }
}
