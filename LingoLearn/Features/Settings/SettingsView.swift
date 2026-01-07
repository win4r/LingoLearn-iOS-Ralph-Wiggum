//
//  SettingsView.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allWords: [Word]
    @State private var viewModel: SettingsViewModel?
    @State private var showResetConfirmation = false
    @State private var showContent = false
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var isExporting = false

    private var wordStats: (total: Int, mastered: Int, learning: Int, new: Int) {
        let mastered = allWords.filter { $0.masteryLevel == .mastered }.count
        let learning = allWords.filter { $0.masteryLevel == .learning || $0.masteryLevel == .reviewing }.count
        let newWords = allWords.filter { $0.masteryLevel == .new }.count
        return (allWords.count, mastered, learning, newWords)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    settingsForm(viewModel: viewModel)
                } else {
                    LoadingView(message: "加载设置...")
                }
            }
            .navigationTitle("设置")
            .onAppear {
                if viewModel == nil {
                    viewModel = SettingsViewModel(modelContext: modelContext)
                    viewModel?.loadSettings()
                }
                withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                    showContent = true
                }
            }
            .alert("重置学习进度", isPresented: $showResetConfirmation) {
                Button("取消", role: .cancel) { }
                Button("重置", role: .destructive) {
                    HapticManager.shared.warning()
                    viewModel?.resetProgress()
                }
            } message: {
                Text("确定要重置所有学习进度吗？此操作无法撤销。")
            }
            .sheet(isPresented: $showExportSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private func exportStudyHistory() {
        isExporting = true
        HapticManager.shared.impact()

        Task {
            do {
                let url = try await generateCSVExport()
                await MainActor.run {
                    exportURL = url
                    isExporting = false
                    showExportSheet = true
                    HapticManager.shared.success()
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    HapticManager.shared.error()
                }
            }
        }
    }

    private func generateCSVExport() async throws -> URL {
        // Fetch all study sessions and words
        let sessionDescriptor = FetchDescriptor<StudySession>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let sessions = (try? modelContext.fetch(sessionDescriptor)) ?? []

        let progressDescriptor = FetchDescriptor<DailyProgress>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let progress = (try? modelContext.fetch(progressDescriptor)) ?? []

        // Create CSV content
        var csvContent = "日期,学习单词数,复习单词数,正确率,学习时间(分钟)\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for day in progress {
            let dateStr = dateFormatter.string(from: day.date)
            let accuracy = String(format: "%.1f%%", day.accuracy * 100)
            let studyTime = String(format: "%.1f", day.totalStudyTime / 60)
            csvContent += "\(dateStr),\(day.wordsLearned),\(day.wordsReviewed),\(accuracy),\(studyTime)\n"
        }

        csvContent += "\n\n单词学习详情\n"
        csvContent += "单词,中文释义,掌握度,学习次数,正确次数,正确率\n"

        for word in allWords.sorted(by: { $0.timesStudied > $1.timesStudied }) {
            let accuracy = word.timesStudied > 0 ? Double(word.timesCorrect) / Double(word.timesStudied) * 100 : 0
            let accuracyStr = String(format: "%.1f%%", accuracy)
            // Escape commas in text
            let english = word.english.replacingOccurrences(of: ",", with: " ")
            let chinese = word.chinese.replacingOccurrences(of: ",", with: " ")
            csvContent += "\(english),\(chinese),\(word.masteryLevel.displayName),\(word.timesStudied),\(word.timesCorrect),\(accuracyStr)\n"
        }

        // Write to temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "LingoLearn_学习记录_\(dateFormatter.string(from: Date())).csv"
        let fileURL = tempDir.appendingPathComponent(fileName)

        // Write with UTF-8 BOM for Excel compatibility
        let bom = "\u{FEFF}"
        let dataWithBOM = (bom + csvContent).data(using: .utf8)!
        try dataWithBOM.write(to: fileURL)

        return fileURL
    }

    @ViewBuilder
    private func settingsForm(viewModel: SettingsViewModel) -> some View {
        Form {
            // Learning Goal Section
            Section {
                DailyGoalSlider(
                    value: Binding(
                        get: { viewModel.dailyGoal },
                        set: {
                            viewModel.dailyGoal = $0
                            HapticManager.shared.selection()
                        }
                    ),
                    range: 10...100,
                    step: 5
                )
            } header: {
                SettingSectionHeader(icon: "target", title: "学习目标", color: .blue)
            } footer: {
                Text("每天学习 \(viewModel.dailyGoal) 个单词")
            }

            // Reminder Section
            Section {
                Toggle("开启每日提醒", isOn: Binding(
                    get: { viewModel.reminderEnabled },
                    set: { newValue in
                        HapticManager.shared.impact()
                        viewModel.reminderEnabled = newValue
                        Task {
                            await viewModel.handleReminderToggle(newValue)
                        }
                    }
                ))

                if viewModel.reminderEnabled {
                    ReminderPicker(time: Binding(
                        get: { viewModel.reminderTime },
                        set: { newValue in
                            viewModel.reminderTime = newValue
                            Task {
                                await viewModel.scheduleReminder()
                            }
                        }
                    ))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            } header: {
                SettingSectionHeader(icon: "bell.badge", title: "提醒设置", color: .orange)
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.reminderEnabled)

            // Feedback Section
            Section {
                Toggle("声音效果", isOn: Binding(
                    get: { viewModel.soundEnabled },
                    set: {
                        HapticManager.shared.impact()
                        viewModel.soundEnabled = $0
                    }
                ))
                Toggle("触觉反馈", isOn: Binding(
                    get: { viewModel.hapticsEnabled },
                    set: {
                        if $0 { HapticManager.shared.success() }
                        viewModel.hapticsEnabled = $0
                    }
                ))
            } header: {
                SettingSectionHeader(icon: "hand.tap", title: "反馈设置", color: .purple)
            }

            // Pronunciation Section
            Section {
                Toggle("自动播放发音", isOn: Binding(
                    get: { viewModel.autoPlayPronunciation },
                    set: {
                        HapticManager.shared.impact()
                        viewModel.autoPlayPronunciation = $0
                    }
                ))

                HStack {
                    Text("发音速度")
                    Spacer()
                    Picker("发音速度", selection: Binding(
                        get: { viewModel.speechRate },
                        set: {
                            HapticManager.shared.selection()
                            viewModel.speechRate = $0
                            // Preview the selected speed
                            SpeechService.shared.speak(text: "Hello", rate: $0.rate)
                        }
                    )) {
                        ForEach(SpeechRate.allCases, id: \.self) { rate in
                            Text(rate.displayName).tag(rate)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
            } header: {
                SettingSectionHeader(icon: "speaker.wave.2", title: "发音设置", color: .green)
            } footer: {
                Text("学习新单词时自动播放发音")
            }

            // Appearance Section
            Section {
                Picker("外观模式", selection: Binding(
                    get: { viewModel.appearanceMode },
                    set: {
                        HapticManager.shared.selection()
                        viewModel.appearanceMode = $0
                    }
                )) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                SettingSectionHeader(icon: "paintbrush", title: "外观", color: .pink)
            }

            // Vocabulary Section
            Section {
                NavigationLink {
                    WordListView()
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.cyan.opacity(0.15), .blue.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)

                            Image(systemName: "books.vertical.fill")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.cyan, .blue],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                        Text("词库管理")
                            .fontWeight(.medium)
                    }
                }
            } header: {
                SettingSectionHeader(icon: "book.closed", title: "词库", color: .cyan)
            } footer: {
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .font(.caption2)
                    Text("查看、搜索和管理所有单词")
                }
                .foregroundStyle(.secondary)
            }

            // Word Statistics Section
            Section {
                VStack(spacing: 16) {
                    // Total words
                    HStack {
                        Label("总单词数", systemImage: "textformat.abc")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(wordStats.total)")
                            .font(.headline)
                            .foregroundStyle(.blue)
                    }

                    Divider()

                    // Progress breakdown
                    HStack(spacing: 20) {
                        StatPill(
                            icon: "checkmark.circle.fill",
                            label: "已掌握",
                            count: wordStats.mastered,
                            color: .green
                        )

                        StatPill(
                            icon: "book.fill",
                            label: "学习中",
                            count: wordStats.learning,
                            color: .orange
                        )

                        StatPill(
                            icon: "sparkle",
                            label: "新词",
                            count: wordStats.new,
                            color: .gray
                        )
                    }

                    // Progress bar
                    if wordStats.total > 0 {
                        VStack(alignment: .leading, spacing: 6) {
                            GeometryReader { geo in
                                HStack(spacing: 2) {
                                    Rectangle()
                                        .fill(Color.green)
                                        .frame(width: geo.size.width * CGFloat(wordStats.mastered) / CGFloat(wordStats.total))

                                    Rectangle()
                                        .fill(Color.orange)
                                        .frame(width: geo.size.width * CGFloat(wordStats.learning) / CGFloat(wordStats.total))

                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: geo.size.width * CGFloat(wordStats.new) / CGFloat(wordStats.total))
                                }
                                .clipShape(Capsule())
                            }
                            .frame(height: 8)

                            Text("掌握率: \(wordStats.total > 0 ? Int(Double(wordStats.mastered) / Double(wordStats.total) * 100) : 0)%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
            } header: {
                SettingSectionHeader(icon: "chart.pie.fill", title: "学习统计", color: .purple)
            }

            // Data Section
            Section {
                Button(role: .destructive, action: {
                    HapticManager.shared.warning()
                    showResetConfirmation = true
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.red.opacity(0.15), .orange.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)

                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.red, .orange],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                        Text("重置学习进度")
                            .foregroundStyle(.red)
                            .fontWeight(.medium)
                    }
                }
            } header: {
                SettingSectionHeader(icon: "externaldrive", title: "数据", color: .gray)
            } footer: {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.caption2)
                    Text("此操作将删除所有学习记录，但保留已学单词")
                }
                .foregroundStyle(.secondary)
            }

            // Export Section
            Section {
                Button(action: exportStudyHistory) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.indigo.opacity(0.15), .purple.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)

                            if isExporting {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "square.and.arrow.up.fill")
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.indigo, .purple],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                        }
                        Text("导出学习记录")
                            .foregroundStyle(.primary)
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "doc.badge.arrow.up")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .disabled(isExporting)
            } header: {
                SettingSectionHeader(icon: "square.and.arrow.up", title: "数据导出", color: .indigo)
            } footer: {
                HStack(spacing: 4) {
                    Image(systemName: "doc.text")
                        .font(.caption2)
                    Text("导出 CSV 格式的学习历史记录")
                }
                .foregroundStyle(.secondary)
            }

            // App Info Section
            Section {
                // Version row
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.15), .cyan.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)

                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }

                // Privacy policy link
                Link(destination: URL(string: "https://example.com/privacy")!) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.green.opacity(0.15), .mint.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)

                            Image(systemName: "hand.raised.fill")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                        Text("隐私政策")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                // Terms link
                Link(destination: URL(string: "https://example.com/terms")!) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.orange.opacity(0.15), .yellow.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)

                            Image(systemName: "doc.text.fill")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .yellow],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                        Text("服务条款")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            } header: {
                SettingSectionHeader(icon: "info.circle", title: "关于", color: .blue)
            }
        }
    }
}

// MARK: - Setting Section Header

struct SettingSectionHeader: View {
    let icon: String
    let title: String
    let color: Color

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 2,
                            endRadius: 12
                        )
                    )
                    .frame(width: 24, height: 24)

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
                .fontWeight(.medium)
                .foregroundStyle(.primary)
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

// Extension to add display name for AppearanceMode
extension AppearanceMode {
    var displayName: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }
}

// MARK: - Stat Pill

private struct StatPill: View {
    let icon: String
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(color)
                Text("\(count)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .modelContainer(for: [UserSettings.self, DailyProgress.self, UserStats.self])
}
