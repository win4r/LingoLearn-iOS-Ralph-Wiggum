//
//  FavoriteWordsCard.swift
//  LingoLearn
//
//  Quick access to favorite words on home screen
//

import SwiftUI
import SwiftData

struct FavoriteWordsCard: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Word> { $0.isFavorite }, sort: \Word.lastStudiedDate, order: .reverse)
    private var favoriteWords: [Word]

    @State private var showContent = false
    @State private var selectedWord: Word?
    @StateObject private var speechService = SpeechService.shared

    var body: some View {
        Group {
            if !favoriteWords.isEmpty {
                favoriteCard
            }
        }
    }

    private var favoriteCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.pink.opacity(0.3), .clear],
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 16
                                )
                            )
                            .frame(width: 28, height: 28)

                        Image(systemName: "heart.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.pink, .red],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    Text("收藏单词")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                // Count badge
                Text("\(favoriteWords.count)个")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            // Horizontal scroll of favorite words
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(favoriteWords.prefix(10)) { word in
                        FavoriteWordChip(word: word, speechService: speechService) {
                            selectedWord = word
                        }
                    }

                    if favoriteWords.count > 10 {
                        VStack {
                            Text("+\(favoriteWords.count - 10)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.pink)
                            Text("更多")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 60, height: 70)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.pink.opacity(0.1))
                        )
                    }
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
                    LinearGradient(
                        colors: [.pink.opacity(0.3), .red.opacity(0.2)],
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
            withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                showContent = true
            }
        }
        .sheet(item: $selectedWord) { word in
            FavoriteWordDetailSheet(word: word)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("收藏单词,共\(favoriteWords.count)个")
    }
}

// MARK: - Favorite Word Chip

private struct FavoriteWordChip: View {
    let word: Word
    @ObservedObject var speechService: SpeechService
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticManager.shared.impact()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 6) {
                // English word
                Text(word.english)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                // Phonetic
                Text(word.phonetic)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                // Chinese meaning
                Text(word.chinese)
                    .font(.caption)
                    .foregroundStyle(.pink)
                    .lineLimit(1)
            }
            .frame(width: 90, alignment: .leading)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.pink.opacity(0.08), .red.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.pink.opacity(0.15), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
        .contextMenu {
            Button {
                speechService.speak(text: word.english)
            } label: {
                Label("播放发音", systemImage: "speaker.wave.2.fill")
            }

            Button {
                UIPasteboard.general.string = word.english
                HapticManager.shared.success()
            } label: {
                Label("复制单词", systemImage: "doc.on.doc")
            }
        }
    }
}

// MARK: - Favorite Word Detail Sheet

private struct FavoriteWordDetailSheet: View {
    let word: Word
    @Environment(\.dismiss) private var dismiss
    @StateObject private var speechService = SpeechService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Word header
                    VStack(spacing: 12) {
                        Text(word.english)
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text(word.phonetic)
                            .font(.title3)
                            .foregroundStyle(.secondary)

                        Button(action: {
                            HapticManager.shared.impact()
                            speechService.speak(text: word.english)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: speechService.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                                    .symbolEffect(.variableColor, options: .repeating.speed(0.5), value: speechService.isSpeaking)
                                Text("播放发音")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.top)

                    // Meaning section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(word.partOfSpeech)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.purple)
                                .clipShape(Capsule())

                            Spacer()
                        }

                        Text(word.chinese)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )

                    // Example section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("例句", systemImage: "text.quote")
                            .font(.headline)

                        Text(word.exampleSentence)
                            .font(.body)

                        Text(word.exampleTranslation)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )

                    // Stats section
                    HStack(spacing: 20) {
                        StatBadge(icon: "book.fill", value: "\(word.timesStudied)", label: "学习次数", color: .blue)
                        StatBadge(icon: word.masteryLevel.icon, value: word.masteryLevel.displayName, label: "掌握度", color: word.masteryLevel.color)
                        StatBadge(icon: "star.fill", value: "\(word.difficulty)", label: "难度", color: .orange)
                    }
                }
                .padding()
            }
            .navigationTitle("单词详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

#Preview {
    FavoriteWordsCard()
        .padding()
        .background(Color(.systemGroupedBackground))
        .modelContainer(for: [Word.self])
}
