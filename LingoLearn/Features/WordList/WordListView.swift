//
//  WordListView.swift
//  LingoLearn
//
//  Browse and search all vocabulary words
//

import SwiftUI
import SwiftData

struct WordListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: WordListViewModel?
    @State private var selectedWord: Word?
    @State private var speechRate: SpeechRate = .normal
    @State private var isSearchFocused: Bool = false
    @State private var showExportOptions: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let vm = viewModel {
                    // Search bar
                    SearchBar(
                        text: Binding(
                            get: { vm.searchText },
                            set: { vm.searchText = $0 }
                        ),
                        isFocused: $isSearchFocused,
                        onSubmit: {
                            vm.addToRecentSearches(vm.searchText)
                        }
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Recent searches
                    if isSearchFocused && vm.searchText.isEmpty && !vm.recentSearches.isEmpty {
                        recentSearchesSection(viewModel: vm)
                    }

                    // Filter chips
                    filterSection(viewModel: vm)

                    // Word count and sort button
                    HStack {
                        Text("\(vm.filteredWords.count) 个单词")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Menu {
                            ForEach(WordListFilter.SortOption.allCases, id: \.self) { option in
                                Button(action: {
                                    withAnimation {
                                        vm.sortOption = option
                                    }
                                }) {
                                    Label(option.displayName, systemImage: option.icon)
                                    if vm.sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: vm.sortOption.icon)
                                Text(vm.sortOption.displayName)
                                    .font(.caption)
                            }
                            .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    // Word list
                    if vm.filteredWords.isEmpty {
                        emptyStateView
                    } else {
                        wordList(viewModel: vm)
                    }
                } else {
                    ProgressView("加载中...")
                }
            }
            .navigationTitle("词库")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                viewModel?.refresh()
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = WordListViewModel(modelContext: modelContext)
                }
                loadSpeechRate()
            }
            .sheet(item: $selectedWord) { word in
                WordDetailSheet(word: word)
            }
            .sheet(isPresented: $showExportOptions) {
                if let vm = viewModel {
                    ExportOptionsSheet(words: vm.filteredWords)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        HapticManager.shared.selection()
                        showExportOptions = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(viewModel?.filteredWords.isEmpty ?? true)
                }
            }
        }
    }

    private func recentSearchesSection(viewModel: WordListViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("最近搜索")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: {
                    HapticManager.shared.selection()
                    withAnimation {
                        viewModel.clearRecentSearches()
                    }
                }) {
                    Text("清除")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.recentSearches, id: \.self) { query in
                        RecentSearchChip(query: query) {
                            HapticManager.shared.selection()
                            viewModel.searchText = query
                            isSearchFocused = false
                        } onDelete: {
                            HapticManager.shared.selection()
                            withAnimation {
                                viewModel.removeRecentSearch(query)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func filterSection(viewModel: WordListViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Category filter
                ForEach(WordListFilter.Category.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.displayName,
                        isSelected: viewModel.selectedCategory == category,
                        count: viewModel.countFor(category: category)
                    ) {
                        withAnimation {
                            viewModel.selectedCategory = category
                        }
                    }
                }

                Divider()
                    .frame(height: 24)

                // Mastery filter
                ForEach(WordListFilter.Mastery.allCases, id: \.self) { mastery in
                    FilterChip(
                        title: mastery.displayName,
                        isSelected: viewModel.selectedMastery == mastery,
                        color: mastery.color,
                        count: mastery == .all ? nil : viewModel.countFor(mastery: mastery)
                    ) {
                        withAnimation {
                            viewModel.selectedMastery = mastery
                        }
                    }
                }

                Divider()
                    .frame(height: 24)

                // Difficulty filter
                ForEach(WordListFilter.Difficulty.allCases, id: \.self) { difficulty in
                    DifficultyFilterChip(
                        difficulty: difficulty,
                        isSelected: viewModel.selectedDifficulty == difficulty,
                        count: difficulty == .all ? nil : viewModel.countFor(difficulty: difficulty)
                    ) {
                        withAnimation {
                            viewModel.selectedDifficulty = difficulty
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func loadSpeechRate() {
        let descriptor = FetchDescriptor<UserSettings>()
        if let settings = try? modelContext.fetch(descriptor).first {
            speechRate = settings.speechRate
        }
    }

    private func wordList(viewModel: WordListViewModel) -> some View {
        List {
            ForEach(viewModel.filteredWords) { word in
                WordListRow(word: word, speechRate: speechRate)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedWord = word
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            HapticManager.shared.impact()
                            viewModel.toggleFavorite(word)
                        } label: {
                            Label(
                                word.isFavorite ? "取消收藏" : "收藏",
                                systemImage: word.isFavorite ? "heart.slash.fill" : "heart.fill"
                            )
                        }
                        .tint(word.isFavorite ? .gray : .pink)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            HapticManager.shared.impact()
                            SpeechService.shared.speak(text: word.english, rate: speechRate.rate)
                        } label: {
                            Label("发音", systemImage: "speaker.wave.2.fill")
                        }
                        .tint(.blue)
                    }
                    .contextMenu {
                        Button {
                            SpeechService.shared.speak(text: word.english, rate: speechRate.rate)
                        } label: {
                            Label("播放发音", systemImage: "speaker.wave.2.fill")
                        }

                        Button {
                            viewModel.toggleFavorite(word)
                        } label: {
                            Label(
                                word.isFavorite ? "取消收藏" : "添加收藏",
                                systemImage: word.isFavorite ? "heart.slash" : "heart"
                            )
                        }

                        Divider()

                        Button {
                            UIPasteboard.general.string = word.english
                            HapticManager.shared.success()
                        } label: {
                            Label("复制单词", systemImage: "doc.on.doc")
                        }

                        Button {
                            UIPasteboard.general.string = "\(word.english) - \(word.chinese)"
                            HapticManager.shared.success()
                        } label: {
                            Label("复制单词和释义", systemImage: "doc.on.doc.fill")
                        }

                        ShareLink(item: "\(word.english) [\(word.phonetic)] - \(word.chinese)") {
                            Label("分享", systemImage: "square.and.arrow.up")
                        }
                    }
            }
        }
        .listStyle(.plain)
        .refreshable {
            viewModel.refresh()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            // Enhanced empty state icon
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.accentColor.opacity(0.15), .clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 70
                        )
                    )
                    .frame(width: 120, height: 120)

                // Icon background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(.systemGray5), Color(.systemGray6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.secondary, .secondary.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("没有找到单词")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("尝试调整搜索条件或筛选器")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Actionable suggestion chips
            HStack(spacing: 10) {
                if let vm = viewModel, !vm.searchText.isEmpty {
                    SuggestionChip(text: "清除搜索", icon: "xmark.circle") {
                        HapticManager.shared.selection()
                        withAnimation {
                            vm.searchText = ""
                        }
                    }
                }

                if let vm = viewModel, vm.selectedCategory != .all || vm.selectedMastery != .all || vm.selectedDifficulty != .all {
                    SuggestionChip(text: "清除筛选", icon: "line.3.horizontal.decrease.circle") {
                        HapticManager.shared.selection()
                        withAnimation {
                            vm.selectedCategory = .all
                            vm.selectedMastery = .all
                            vm.selectedDifficulty = .all
                        }
                    }
                }

                SuggestionChip(text: "显示全部", icon: "list.bullet") {
                    HapticManager.shared.selection()
                    withAnimation {
                        viewModel?.searchText = ""
                        viewModel?.selectedCategory = .all
                        viewModel?.selectedMastery = .all
                        viewModel?.selectedDifficulty = .all
                    }
                }
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal)
    }
}

// MARK: - Suggestion Chip

struct SuggestionChip: View {
    let text: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(text)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(.accentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.accentColor.opacity(0.1))
            .clipShape(Capsule())
        }
        .buttonStyle(SuggestionChipButtonStyle())
    }
}

private struct SuggestionChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    @Binding var isFocused: Bool
    var onSubmit: (() -> Void)? = nil
    @FocusState private var fieldFocused: Bool
    @State private var isActive = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(
                    isActive ?
                    LinearGradient(colors: [.accentColor, .accentColor.opacity(0.7)], startPoint: .top, endPoint: .bottom) :
                    LinearGradient(colors: [.secondary], startPoint: .top, endPoint: .bottom)
                )
                .font(.body.weight(.medium))

            TextField("搜索单词或释义...", text: $text)
                .textFieldStyle(.plain)
                .focused($fieldFocused)
                .onSubmit {
                    onSubmit?()
                }
                .onChange(of: fieldFocused) { _, newValue in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isActive = newValue
                        isFocused = newValue
                    }
                }

            if !text.isEmpty {
                Button(action: {
                    HapticManager.shared.selection()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        text = ""
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isActive ? Color.accentColor.opacity(0.5) : Color.clear,
                    lineWidth: 2
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isActive)
        .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
    }
}

// MARK: - Recent Search Chip

struct RecentSearchChip: View {
    let query: String
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Button(action: onTap) {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(query)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = .accentColor
    var count: Int? = nil
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.selection()
            action()
        }) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                if let count = count {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? color : .white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            LinearGradient(
                                colors: isSelected ? [.white.opacity(0.95), .white.opacity(0.9)] : [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                LinearGradient(colors: [color, color.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                LinearGradient(colors: [Color(.systemGray6)], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(Capsule())
            .shadow(color: isSelected ? color.opacity(0.3) : .clear, radius: 4, y: 2)
        }
        .buttonStyle(FilterChipButtonStyle())
    }
}

struct FilterChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Difficulty Filter Chip

struct DifficultyFilterChip: View {
    let difficulty: WordListFilter.Difficulty
    let isSelected: Bool
    var count: Int? = nil
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.selection()
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: difficulty.icon)
                    .font(.caption2)

                Text(difficulty.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                if let count = count {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? difficulty.color : .white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            LinearGradient(
                                colors: isSelected ? [.white.opacity(0.95), .white.opacity(0.9)] : [difficulty.color, difficulty.color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                LinearGradient(colors: [difficulty.color, difficulty.color.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                LinearGradient(colors: [Color(.systemGray6)], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(Capsule())
            .shadow(color: isSelected ? difficulty.color.opacity(0.3) : .clear, radius: 4, y: 2)
        }
        .buttonStyle(FilterChipButtonStyle())
    }
}

// MARK: - Word List Row

struct WordListRow: View {
    let word: Word
    var speechRate: SpeechRate = .normal
    @StateObject private var speechService = SpeechService.shared
    @State private var isPressed = false
    @State private var appeared = false

    private var masteryIcon: String {
        switch word.masteryLevel {
        case .new: return "sparkle"
        case .learning: return "book.fill"
        case .reviewing: return "arrow.clockwise"
        case .mastered: return "checkmark.circle.fill"
        }
    }

    private var masteryColors: [Color] {
        switch word.masteryLevel {
        case .new: return [.gray, .gray.opacity(0.7)]
        case .learning: return [.orange, .yellow]
        case .reviewing: return [.blue, .cyan]
        case .mastered: return [.green, .mint]
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Mastery indicator with icon and glow
            ZStack {
                // Subtle glow for mastered words
                if word.masteryLevel == .mastered {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.green.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 25
                            )
                        )
                        .frame(width: 40, height: 40)
                }

                Circle()
                    .fill(
                        LinearGradient(
                            colors: masteryColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .shadow(color: masteryColors.first?.opacity(0.3) ?? .clear, radius: 4, y: 2)

                Image(systemName: masteryIcon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(word.english)
                        .font(.body)
                        .fontWeight(.semibold)

                    Text(word.phonetic)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                HStack(spacing: 8) {
                    Text(word.partOfSpeech)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            LinearGradient(
                                colors: [.blue, .cyan.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())

                    Text(word.chinese)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Favorite indicator with animation
            if word.isFavorite {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.pink.opacity(0.2), .clear],
                                center: .center,
                                startRadius: 5,
                                endRadius: 15
                            )
                        )
                        .frame(width: 28, height: 28)

                    Image(systemName: "heart.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red, .pink],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .font(.subheadline)
                }
                .scaleEffect(appeared ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.1), value: appeared)
            }

            // Speak button with enhanced styling
            Button(action: {
                HapticManager.shared.impact()
                speechService.speak(text: word.english, rate: speechRate.rate)
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.12), Color.cyan.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)

                    Image(systemName: speechService.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                        .font(.subheadline)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .symbolEffect(.variableColor.iterative, value: speechService.isSpeaking)
                }
            }
            .buttonStyle(WordRowButtonStyle())
        }
        .padding(.vertical, 8)
        .onAppear {
            appeared = true
        }
    }
}

private struct WordRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Word Detail Sheet

struct WordDetailSheet: View {
    let word: Word
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var speechService = SpeechService.shared
    @State private var isFavorite: Bool = false
    @State private var showContent = false
    @State private var heartScale: CGFloat = 1.0
    @State private var speechRate: SpeechRate = .normal
    @State private var personalNote: String = ""
    @State private var isEditingNote: Bool = false
    @FocusState private var isNoteFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .center, spacing: 16) {
                        // Mastery badge
                        HStack(spacing: 8) {
                            Image(systemName: masteryIcon)
                                .font(.caption)
                            Text(word.masteryLevel.displayName)
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [word.masteryLevel.color, word.masteryLevel.color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.5)

                        Text(word.english)
                            .font(.system(size: 42, weight: .bold))
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)

                        Text(word.phonetic)
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .opacity(showContent ? 1 : 0)

                        // Audio button with animation
                        Button(action: {
                            HapticManager.shared.impact()
                            speechService.speak(text: word.english, rate: speechRate.rate)
                        }) {
                            ZStack {
                                // Outer glow
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [.blue.opacity(0.2), .clear],
                                            center: .center,
                                            startRadius: 20,
                                            endRadius: 45
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .opacity(speechService.isSpeaking ? 1 : 0.5)

                                // Sound wave rings when speaking
                                if speechService.isSpeaking {
                                    ForEach(0..<2, id: \.self) { i in
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.blue.opacity(0.3), .cyan.opacity(0.1)],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                ),
                                                lineWidth: 2
                                            )
                                            .frame(width: 60 + CGFloat(i * 15), height: 60 + CGFloat(i * 15))
                                            .opacity(0.5 - Double(i) * 0.2)
                                    }
                                }

                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue.opacity(0.15), .cyan.opacity(0.08)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 60, height: 60)

                                Image(systemName: speechService.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                                    .font(.title2)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .cyan],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .symbolEffect(.variableColor.iterative, value: speechService.isSpeaking)
                            }
                        }
                        .buttonStyle(WordRowButtonStyle())
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)

                    Divider()
                        .padding(.horizontal)

                    // Chinese meaning
                    DetailSection(title: "释义", icon: "text.book.closed", color: .blue, showContent: showContent) {
                        HStack(spacing: 12) {
                            Text(word.partOfSpeech)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
                                )
                                .clipShape(Capsule())

                            Text(word.chinese)
                                .font(.title3)
                                .fontWeight(.medium)
                        }
                    }

                    // Example sentence
                    if !word.exampleSentence.isEmpty {
                        DetailSection(title: "例句", icon: "quote.bubble", color: .purple, showContent: showContent) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(word.exampleSentence)
                                    .font(.body)
                                    .italic()

                                Text(word.exampleTranslation)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.1), Color.purple.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    // Word Info (Category & Difficulty)
                    DetailSection(title: "单词信息", icon: "info.circle", color: .indigo, showContent: showContent) {
                        HStack(spacing: 12) {
                            // Category badge
                            HStack(spacing: 6) {
                                Image(systemName: "graduationcap.fill")
                                    .font(.caption2)
                                Text(word.category.rawValue)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    colors: word.category == .cet4 ? [.blue, .cyan] : [.purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())

                            // Difficulty indicator
                            HStack(spacing: 4) {
                                Text("难度")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                ForEach(1...5, id: \.self) { level in
                                    Image(systemName: level <= word.difficulty ? "star.fill" : "star")
                                        .font(.caption2)
                                        .foregroundStyle(
                                            level <= word.difficulty ?
                                            LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom) :
                                            LinearGradient(colors: [.gray.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                                        )
                                }
                            }

                            Spacer()
                        }
                    }

                    // Stats
                    DetailSection(title: "学习记录", icon: "chart.bar", color: .green, showContent: showContent) {
                        HStack(spacing: 12) {
                            StatBox(
                                title: "学习次数",
                                value: "\(word.timesStudied)",
                                icon: "book.fill",
                                color: .blue
                            )
                            StatBox(
                                title: "正确次数",
                                value: "\(word.timesCorrect)",
                                icon: "checkmark.circle.fill",
                                color: .green
                            )
                            StatBox(
                                title: "正确率",
                                value: word.timesStudied > 0 ? "\(Int(Double(word.timesCorrect) / Double(word.timesStudied) * 100))%" : "0%",
                                icon: "percent",
                                color: .orange
                            )
                        }
                    }

                    // Schedule info (Next review & Last studied)
                    DetailSection(title: "复习计划", icon: "calendar.badge.clock", color: .teal, showContent: showContent) {
                        VStack(spacing: 12) {
                            HStack {
                                HStack(spacing: 8) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text("上次学习")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if let lastStudied = word.lastStudiedDate {
                                    Text(formatRelativeDate(lastStudied))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                } else {
                                    Text("尚未学习")
                                        .font(.subheadline)
                                        .foregroundStyle(.tertiary)
                                }
                            }

                            HStack {
                                HStack(spacing: 8) {
                                    Image(systemName: "calendar")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text("下次复习")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if let nextReview = word.nextReviewDate {
                                    let isOverdue = nextReview < Date()
                                    HStack(spacing: 4) {
                                        if isOverdue {
                                            Image(systemName: "exclamationmark.circle.fill")
                                                .font(.caption)
                                                .foregroundStyle(.orange)
                                        }
                                        Text(isOverdue ? "待复习" : formatRelativeDate(nextReview))
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundStyle(isOverdue ? .orange : .primary)
                                    }
                                } else {
                                    Text("尚未安排")
                                        .font(.subheadline)
                                        .foregroundStyle(.tertiary)
                                }
                            }

                            if word.interval > 0 {
                                HStack {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        Text("复习间隔")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Text("\(word.interval)天")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.teal.opacity(0.08), Color.teal.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Personal Notes Section
                    DetailSection(title: "个人笔记", icon: "note.text", color: .orange, showContent: showContent) {
                        VStack(alignment: .leading, spacing: 12) {
                            if isEditingNote {
                                TextEditor(text: $personalNote)
                                    .font(.body)
                                    .frame(minHeight: 100)
                                    .padding(8)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .focused($isNoteFocused)

                                HStack {
                                    Button("取消") {
                                        personalNote = word.personalNote
                                        isEditingNote = false
                                        isNoteFocused = false
                                    }
                                    .foregroundStyle(.secondary)

                                    Spacer()

                                    Button(action: saveNote) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark")
                                            Text("保存")
                                        }
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            LinearGradient(
                                                colors: [.orange, .red],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .clipShape(Capsule())
                                    }
                                }
                            } else {
                                if personalNote.isEmpty {
                                    Button(action: {
                                        isEditingNote = true
                                        isNoteFocused = true
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.title3)
                                            Text("添加笔记")
                                                .font(.subheadline)
                                        }
                                        .foregroundStyle(.orange)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 20)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.orange.opacity(0.1))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                                                        .foregroundStyle(.orange.opacity(0.3))
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(personalNote)
                                            .font(.body)
                                            .foregroundStyle(.primary)

                                        Button(action: {
                                            isEditingNote = true
                                            isNoteFocused = true
                                        }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "pencil")
                                                Text("编辑")
                                            }
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.orange.opacity(0.1), Color.orange.opacity(0.05)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("单词详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 16) {
                        Button(action: toggleFavorite) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .foregroundStyle(isFavorite ? .red : .secondary)
                                .scaleEffect(heartScale)
                                .symbolEffect(.bounce, value: isFavorite)
                        }
                        .accessibilityLabel(isFavorite ? "取消收藏" : "添加收藏")

                        ShareLink(item: "\(word.english) [\(word.phonetic)]\n\(word.partOfSpeech) \(word.chinese)\n\n例句: \(word.exampleSentence)\n\(word.exampleTranslation)") {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("分享单词")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isFavorite = word.isFavorite
                personalNote = word.personalNote
                loadSpeechRate()
                withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                    showContent = true
                }
            }
        }
    }

    private func loadSpeechRate() {
        let descriptor = FetchDescriptor<UserSettings>()
        if let settings = try? modelContext.fetch(descriptor).first {
            speechRate = settings.speechRate
        }
    }

    private var masteryIcon: String {
        switch word.masteryLevel {
        case .new: return "sparkle"
        case .learning: return "book.fill"
        case .reviewing: return "arrow.clockwise"
        case .mastered: return "star.fill"
        }
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else if calendar.isDateInTomorrow(date) {
            return "明天"
        }

        let daysDiff = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: date)).day ?? 0

        if daysDiff < 0 {
            return "\(abs(daysDiff))天前"
        } else if daysDiff <= 7 {
            return "\(daysDiff)天后"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
            return formatter.string(from: date)
        }
    }

    private func toggleFavorite() {
        HapticManager.shared.impact()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            heartScale = 1.3
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                heartScale = 1.0
            }
        }
        isFavorite.toggle()
        word.isFavorite = isFavorite
        try? modelContext.save()
    }

    private func saveNote() {
        word.personalNote = personalNote
        try? modelContext.save()
        isEditingNote = false
        isNoteFocused = false
        HapticManager.shared.success()
    }
}

// MARK: - Detail Section

struct DetailSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let showContent: Bool
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Text(title)
                    .font(.headline)
            }

            content
        }
        .padding(.horizontal)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 15)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    var icon: String = "circle.fill"
    var color: Color = .primary

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.2), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .scaleEffect(appeared ? 1 : 0.5)
            .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.1), value: appeared)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.primary, .primary.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .contentTransition(.numericText())

            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
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
            appeared = true
        }
    }
}

// MARK: - Extensions

extension MasteryLevel {
    var displayName: String {
        switch self {
        case .new: return "新词"
        case .learning: return "学习中"
        case .reviewing: return "复习中"
        case .mastered: return "已掌握"
        }
    }

    var color: Color {
        switch self {
        case .new: return .gray
        case .learning: return .orange
        case .reviewing: return .blue
        case .mastered: return .green
        }
    }

    var icon: String {
        switch self {
        case .new: return "sparkle"
        case .learning: return "book.fill"
        case .reviewing: return "arrow.clockwise"
        case .mastered: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Export Options Sheet

struct ExportOptionsSheet: View {
    let words: [Word]
    @Environment(\.dismiss) private var dismiss
    @State private var exportFormat: ExportFormat = .simple
    @State private var includePhonetic: Bool = true
    @State private var includeMastery: Bool = false
    @State private var showContent = false

    enum ExportFormat: String, CaseIterable {
        case simple = "简洁模式"
        case detailed = "详细模式"
        case flashcard = "闪卡模式"

        var description: String {
            switch self {
            case .simple: return "单词 - 释义"
            case .detailed: return "包含音标、词性、例句"
            case .flashcard: return "适合导入其他闪卡应用"
            }
        }

        var icon: String {
            switch self {
            case .simple: return "list.bullet"
            case .detailed: return "doc.text"
            case .flashcard: return "rectangle.stack"
            }
        }
    }

    private var exportText: String {
        var lines: [String] = []
        lines.append("LingoLearn 词汇导出")
        lines.append("共 \(words.count) 个单词")
        lines.append("导出时间: \(formatDate(Date()))")
        lines.append("")
        lines.append("---")
        lines.append("")

        for (index, word) in words.enumerated() {
            switch exportFormat {
            case .simple:
                var line = "\(index + 1). \(word.english) - \(word.chinese)"
                if includePhonetic {
                    line += " \(word.phonetic)"
                }
                if includeMastery {
                    line += " [\(word.masteryLevel.displayName)]"
                }
                lines.append(line)

            case .detailed:
                lines.append("\(index + 1). \(word.english)")
                if includePhonetic {
                    lines.append("   音标: \(word.phonetic)")
                }
                lines.append("   词性: \(word.partOfSpeech)")
                lines.append("   释义: \(word.chinese)")
                lines.append("   例句: \(word.exampleSentence)")
                lines.append("   翻译: \(word.exampleTranslation)")
                if includeMastery {
                    lines.append("   掌握度: \(word.masteryLevel.displayName)")
                }
                lines.append("")

            case .flashcard:
                // Tab-separated format for import into Anki/Quizlet
                var line = "\(word.english)\t\(word.chinese)"
                if includePhonetic {
                    line += "\t\(word.phonetic)"
                }
                lines.append(line)
            }
        }

        return lines.joined(separator: "\n")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.2), .cyan.opacity(0.15)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 70, height: 70)

                            Image(systemName: "square.and.arrow.up")
                                .font(.title)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }

                        Text("导出 \(words.count) 个单词")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("选择导出格式并分享到其他应用")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)

                    // Format options
                    VStack(alignment: .leading, spacing: 12) {
                        Text("导出格式")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            ExportFormatRow(
                                format: format,
                                isSelected: exportFormat == format
                            ) {
                                HapticManager.shared.selection()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    exportFormat = format
                                }
                            }
                        }
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)

                    // Options
                    VStack(alignment: .leading, spacing: 12) {
                        Text("导出选项")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 0) {
                            Toggle(isOn: $includePhonetic) {
                                Label("包含音标", systemImage: "speaker.wave.2")
                            }
                            .padding()

                            Divider()
                                .padding(.leading, 50)

                            Toggle(isOn: $includeMastery) {
                                Label("包含掌握度", systemImage: "chart.bar.fill")
                            }
                            .padding()
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)

                    // Preview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("预览")
                            .font(.headline)
                            .padding(.horizontal)

                        Text(String(exportText.prefix(500)) + (exportText.count > 500 ? "..." : ""))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)

                    // Share button
                    ShareLink(item: exportText) {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up")
                            Text("分享")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
                    }
                    .padding(.horizontal)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)

                    Spacer(minLength: 20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("导出词汇")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                showContent = true
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: date)
    }
}

private struct ExportFormatRow: View {
    let format: ExportOptionsSheet.ExportFormat
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected ?
                            LinearGradient(colors: [.blue.opacity(0.2), .cyan.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [Color(.systemGray5)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: format.icon)
                        .font(.title3)
                        .foregroundStyle(
                            isSelected ?
                            LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom) :
                            LinearGradient(colors: [.secondary], startPoint: .top, endPoint: .bottom)
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(format.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text(format.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.blue.opacity(0.3) : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}

#Preview {
    WordListView()
        .modelContainer(for: [Word.self])
}
