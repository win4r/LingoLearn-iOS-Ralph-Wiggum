//
//  SmartReviewCard.swift
//  LingoLearn
//
//  Smart review suggestions based on spaced repetition data
//

import SwiftUI
import SwiftData

struct SmartReviewCard: View {
    @Environment(\.modelContext) private var modelContext
    @State private var overdueWords: [Word] = []
    @State private var dueSoonWords: [Word] = []
    @State private var showContent = false

    let onStartReview: () -> Void

    private var hasReviewItems: Bool {
        !overdueWords.isEmpty || !dueSoonWords.isEmpty
    }

    private var urgencyColor: Color {
        if !overdueWords.isEmpty {
            return .red
        } else if !dueSoonWords.isEmpty {
            return .orange
        }
        return .green
    }

    var body: some View {
        Group {
            if hasReviewItems {
                reviewCard
            }
        }
        .onAppear {
            loadReviewData()
        }
    }

    private var reviewCard: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [urgencyColor.opacity(0.3), .clear],
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 16
                                )
                            )
                            .frame(width: 28, height: 28)

                        Image(systemName: "brain.head.profile")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [urgencyColor, urgencyColor.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    Text("智能复习建议")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                // Review count badge
                HStack(spacing: 4) {
                    Image(systemName: "clock.badge.exclamationmark")
                        .font(.caption2)
                    Text("\(overdueWords.count + dueSoonWords.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    LinearGradient(
                        colors: [urgencyColor, urgencyColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }

            // Overdue section
            if !overdueWords.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        Text("已过期 (\(overdueWords.count)个)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.red)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(overdueWords.prefix(5)) { word in
                                WordChip(word: word, color: .red)
                            }
                            if overdueWords.count > 5 {
                                Text("+\(overdueWords.count - 5)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 8)
                            }
                        }
                    }
                }
            }

            // Due soon section
            if !dueSoonWords.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 6, height: 6)
                        Text("即将到期 (\(dueSoonWords.count)个)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.orange)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(dueSoonWords.prefix(5)) { word in
                                WordChip(word: word, color: .orange)
                            }
                            if dueSoonWords.count > 5 {
                                Text("+\(dueSoonWords.count - 5)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 8)
                            }
                        }
                    }
                }
            }

            // Start review button
            Button(action: {
                HapticManager.shared.impact()
                SoundService.shared.playTap()
                onStartReview()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline)
                    Text("开始复习")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [urgencyColor, urgencyColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(urgencyColor.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 10)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.4)) {
                showContent = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("智能复习建议,\(overdueWords.count)个已过期,\(dueSoonWords.count)个即将到期")
        .accessibilityHint("双击开始复习")
    }

    private func loadReviewData() {
        let now = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now

        let descriptor = FetchDescriptor<Word>()

        do {
            let allWords = try modelContext.fetch(descriptor)

            // Overdue words (nextReviewDate in the past)
            overdueWords = allWords.filter { word in
                guard let reviewDate = word.nextReviewDate else { return false }
                return reviewDate < now && word.masteryLevel != .new
            }.sorted { ($0.nextReviewDate ?? .distantPast) < ($1.nextReviewDate ?? .distantPast) }

            // Due soon words (nextReviewDate within next 24 hours)
            dueSoonWords = allWords.filter { word in
                guard let reviewDate = word.nextReviewDate else { return false }
                return reviewDate >= now && reviewDate <= tomorrow && word.masteryLevel != .new
            }.sorted { ($0.nextReviewDate ?? .distantFuture) < ($1.nextReviewDate ?? .distantFuture) }

        } catch {
            AppLogger.logError("Failed to load review data", error: error, category: AppLogger.data)
        }
    }
}

// MARK: - Word Chip

private struct WordChip: View {
    let word: Word
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(word.english)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            Text(word.chinese)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    SmartReviewCard {
        print("Start review")
    }
    .padding()
    .background(Color(.systemGroupedBackground))
    .modelContainer(for: [Word.self])
}
