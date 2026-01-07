//
//  HomeView.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HomeViewModel?
    @State private var navigateToLearning = false
    @State private var navigateToReview = false
    @State private var navigateToRandomTest = false
    @State private var randomTestType: SessionType = .multipleChoice
    @State private var showLearningSetup = false
    @State private var showReviewSetup = false
    @State private var selectedCategory: WordCategory? = nil
    @State private var showGreeting = false
    @State private var showMilestoneCelebration = false
    @State private var currentMilestone = 0
    @State private var showGoalCelebration = false
    @State private var hasShownGoalCelebrationToday = false

    private var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "早上好！"
        case 12..<14:
            return "中午好！"
        case 14..<18:
            return "下午好！"
        case 18..<22:
            return "晚上好！"
        default:
            return "夜深了！"
        }
    }

    private var timeBasedSubtitle: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "开启美好的学习之旅"
        case 12..<14:
            return "午休后继续学习吧"
        case 14..<18:
            return "下午是学习的黄金时间"
        case 18..<22:
            return "晚间复习效果最佳"
        default:
            return "注意休息，明天继续"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    studyReminderSection
                    dailyProgressSection
                    streakSection
                    streakFreezeSection
                    weeklyGoalsSection
                    quickStatsSection
                    difficultWordsSection
                    learningPatternsSection
                    studyRecommendationsSection
                    vocabularyInsightsSection
                    reviewForecastSection
                    wordRootSection
                    quickReviewWidgetSection
                    wordOfDaySection
                    smartReviewSection
                    favoriteWordsSection
                    recentNotesSection
                    pomodoroTimerSection
                    dailyTipSection
                    reviewBadgeSection
                    quickActionsSection
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("LingoLearn")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if viewModel == nil {
                    viewModel = HomeViewModel(modelContext: modelContext)
                }
            }
            .refreshable {
                viewModel?.refresh()
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                    showGreeting = true
                }
            }
            .navigationDestination(isPresented: $navigateToLearning) {
                FlashcardView(mode: .learning, categoryFilter: selectedCategory)
            }
            .navigationDestination(isPresented: $navigateToReview) {
                FlashcardView(mode: .review, categoryFilter: selectedCategory)
            }
            .sheet(isPresented: $showLearningSetup) {
                LearningSetupSheet(mode: .learning) { category in
                    selectedCategory = category
                    navigateToLearning = true
                }
            }
            .sheet(isPresented: $showReviewSetup) {
                LearningSetupSheet(mode: .review) { category in
                    selectedCategory = category
                    navigateToReview = true
                }
            }
            .navigationDestination(isPresented: $navigateToRandomTest) {
                TestViewRouter(testType: randomTestType, wordCount: 10, category: .all)
            }
            .onChange(of: viewModel?.showMilestoneCelebration) { _, newValue in
                if let showCelebration = newValue, showCelebration {
                    currentMilestone = viewModel?.currentMilestone ?? 0
                    showMilestoneCelebration = true
                }
            }
            .onChange(of: showMilestoneCelebration) { _, newValue in
                if !newValue {
                    viewModel?.dismissMilestoneCelebration()
                }
            }
        }
        .milestoneCelebration(isShowing: $showMilestoneCelebration, milestone: currentMilestone)
        .goalCelebration(isShowing: $showGoalCelebration)
        .onChange(of: viewModel?.progressPercentage) { oldValue, newValue in
            // Check if goal was just reached
            if let newPercent = newValue, let oldPercent = oldValue,
               newPercent >= 1.0 && oldPercent < 1.0 && !hasShownGoalCelebrationToday {
                hasShownGoalCelebrationToday = true
                showGoalCelebration = true
                saveGoalCelebrationShown()
            }
        }
        .onAppear {
            checkIfGoalCelebrationShownToday()
        }
    }

    private func checkIfGoalCelebrationShownToday() {
        let key = "goalCelebrationDate"
        if let lastDate = UserDefaults.standard.object(forKey: key) as? Date {
            hasShownGoalCelebrationToday = Calendar.current.isDateInToday(lastDate)
        }
    }

    private func saveGoalCelebrationShown() {
        UserDefaults.standard.set(Date(), forKey: "goalCelebrationDate")
    }

    // MARK: - Actions

    private func startRandomTest() {
        let testTypes: [SessionType] = [.multipleChoice, .fillInBlank, .listening]
        randomTestType = testTypes.randomElement() ?? .multipleChoice
        navigateToRandomTest = true
    }

    // MARK: - View Sections

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(timeBasedGreeting)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(showGreeting ? 1 : 0)
                    .offset(y: showGreeting ? 0 : 10)

                Text(timeBasedSubtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .opacity(showGreeting ? 1 : 0)
                    .offset(y: showGreeting ? 0 : 10)
            }
            Spacer()

            // Time-based icon with glow
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [timeBasedGlowColor.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 35
                        )
                    )
                    .frame(width: 60, height: 60)
                    .opacity(showGreeting ? 1 : 0)

                // Icon background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [timeBasedGlowColor.opacity(0.15), timeBasedGlowColor.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: timeBasedIcon)
                    .font(.title2)
                    .foregroundStyle(timeBasedIconGradient)
                    .symbolEffect(.variableColor.iterative, options: .speed(0.3), value: showGreeting)
            }
            .opacity(showGreeting ? 1 : 0)
            .scaleEffect(showGreeting ? 1 : 0.5)
        }
    }

    private var timeBasedGlowColor: Color {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return .orange
        case 12..<14: return .yellow
        case 14..<18: return .orange
        case 18..<22: return .purple
        default: return .indigo
        }
    }

    private var timeBasedIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "sun.horizon.fill"
        case 12..<14:
            return "sun.max.fill"
        case 14..<18:
            return "sun.min.fill"
        case 18..<22:
            return "moon.stars.fill"
        default:
            return "moon.zzz.fill"
        }
    }

    private var timeBasedIconGradient: LinearGradient {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)
        case 12..<14:
            return LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
        case 14..<18:
            return LinearGradient(colors: [.orange, .red.opacity(0.8)], startPoint: .top, endPoint: .bottom)
        case 18..<22:
            return LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom)
        default:
            return LinearGradient(colors: [.indigo, .purple], startPoint: .top, endPoint: .bottom)
        }
    }

    @ViewBuilder
    private var studyReminderSection: some View {
        if let vm = viewModel {
            StudyReminderCard(lastStudyDate: vm.userStats?.lastStudyDate) {
                showLearningSetup = true
            }
        }
    }

    @ViewBuilder
    private var dailyProgressSection: some View {
        if let vm = viewModel {
            DailyProgressCard(
                progress: vm.todayProgress,
                dailyGoal: vm.userSettings?.dailyGoal,
                progressPercentage: vm.progressPercentage
            )
        }
    }

    @ViewBuilder
    private var streakSection: some View {
        if let vm = viewModel, let stats = vm.userStats {
            StreakCard(
                currentStreak: stats.currentStreak,
                longestStreak: stats.longestStreak,
                studiedDates: vm.studiedDates
            )
        }
    }

    private var streakFreezeSection: some View {
        StreakFreezeCard()
    }

    private var weeklyGoalsSection: some View {
        WeeklyGoalsCard()
    }

    private var quickStatsSection: some View {
        QuickStatsCard()
    }

    private var difficultWordsSection: some View {
        DifficultWordsCard()
    }

    private var learningPatternsSection: some View {
        LearningPatternsCard()
    }

    private var studyRecommendationsSection: some View {
        StudyRecommendationsCard()
    }

    private var vocabularyInsightsSection: some View {
        VocabularyInsightsCard()
    }

    private var reviewForecastSection: some View {
        ReviewForecastCard()
    }

    private var wordRootSection: some View {
        WordRootCard()
    }

    private var quickReviewWidgetSection: some View {
        QuickReviewWidget()
    }

    private var wordOfDaySection: some View {
        WordOfDayCard()
    }

    private var smartReviewSection: some View {
        SmartReviewCard {
            navigateToReview = true
        }
    }

    private var favoriteWordsSection: some View {
        FavoriteWordsCard()
    }

    private var recentNotesSection: some View {
        RecentNotesCard()
    }

    private var pomodoroTimerSection: some View {
        PomodoroTimerCard()
    }

    private var dailyTipSection: some View {
        DailyTipCard()
    }

    @ViewBuilder
    private var reviewBadgeSection: some View {
        if let vm = viewModel, vm.wordsDueForReview > 0 {
            ReviewBadge(wordsDueForReview: vm.wordsDueForReview) {
                navigateToReview = true
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            // Enhanced header
            HStack(spacing: 10) {
                ZStack {
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

                    Image(systemName: "bolt.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.accentColor, .cyan],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                Text("快速操作")
                    .font(.headline)

                Spacer()

                // Decorative dots
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.accentColor.opacity(0.4 - Double(i) * 0.1), .cyan.opacity(0.3 - Double(i) * 0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 5, height: 5)
                    }
                }
            }

            VStack(spacing: 12) {
                QuickActionButton(
                    icon: "book.fill",
                    title: "开始学习",
                    subtitle: "学习新单词",
                    color: .blue
                ) {
                    showLearningSetup = true
                }

                QuickActionButton(
                    icon: "arrow.clockwise",
                    title: "快速复习",
                    subtitle: "复习已学单词",
                    color: .purple
                ) {
                    showReviewSetup = true
                }

                QuickActionButton(
                    icon: "shuffle",
                    title: "随机测试",
                    subtitle: "测试你的词汇量",
                    color: .green
                ) {
                    startRandomTest()
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Word.self, UserStats.self, DailyProgress.self, UserSettings.self])
}
