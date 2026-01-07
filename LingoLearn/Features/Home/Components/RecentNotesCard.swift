//
//  RecentNotesCard.swift
//  LingoLearn
//
//  Shows words with personal notes for quick reference
//

import SwiftUI
import SwiftData

struct RecentNotesCard: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Word> { !$0.personalNote.isEmpty },
        sort: \Word.lastStudiedDate,
        order: .reverse
    )
    private var wordsWithNotes: [Word]

    @State private var showContent = false
    @State private var selectedWord: Word?
    @State private var editingNote = ""

    var body: some View {
        Group {
            if !wordsWithNotes.isEmpty {
                notesCard
            }
        }
    }

    private var notesCard: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.yellow.opacity(0.3), .clear],
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 16
                                )
                            )
                            .frame(width: 28, height: 28)

                        Image(systemName: "note.text")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    Text("学习笔记")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                Text("\(wordsWithNotes.count)条")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Notes list
            VStack(spacing: 10) {
                ForEach(wordsWithNotes.prefix(3)) { word in
                    NoteRow(word: word) {
                        selectedWord = word
                        editingNote = word.personalNote
                    }
                }

                if wordsWithNotes.count > 3 {
                    HStack {
                        Spacer()
                        Text("还有 \(wordsWithNotes.count - 3) 条笔记")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.top, 4)
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
                        colors: [.yellow.opacity(0.2), .orange.opacity(0.15)],
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
            withAnimation(.easeOut(duration: 0.4).delay(0.48)) {
                showContent = true
            }
        }
        .sheet(item: $selectedWord) { word in
            NoteEditSheet(word: word, note: $editingNote) {
                word.personalNote = editingNote
                try? modelContext.save()
                HapticManager.shared.success()
            }
        }
    }
}

// MARK: - Note Row

private struct NoteRow: View {
    let word: Word
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.impact()
            onTap()
        }) {
            HStack(spacing: 12) {
                // Word info
                VStack(alignment: .leading, spacing: 3) {
                    Text(word.english)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(word.personalNote)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // Edit indicator
                Image(systemName: "pencil.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.yellow)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Note Edit Sheet

private struct NoteEditSheet: View {
    let word: Word
    @Binding var note: String
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Word info
                VStack(spacing: 8) {
                    Text(word.english)
                        .font(.title)
                        .fontWeight(.bold)

                    Text(word.phonetic)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(word.chinese)
                        .font(.headline)
                        .foregroundStyle(.orange)
                }
                .padding(.top)

                // Note editor
                VStack(alignment: .leading, spacing: 8) {
                    Label("个人笔记", systemImage: "note.text")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    TextEditor(text: $note)
                        .frame(minHeight: 150)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        )
                        .focused($isFocused)
                }

                // Quick suggestions
                VStack(alignment: .leading, spacing: 8) {
                    Text("快速添加")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            QuickNoteChip(text: "易混淆") { appendToNote("易混淆: ") }
                            QuickNoteChip(text: "联想记忆") { appendToNote("联想记忆: ") }
                            QuickNoteChip(text: "同义词") { appendToNote("同义词: ") }
                            QuickNoteChip(text: "反义词") { appendToNote("反义词: ") }
                            QuickNoteChip(text: "例句") { appendToNote("例句: ") }
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("编辑笔记")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }

    private func appendToNote(_ text: String) {
        if note.isEmpty {
            note = text
        } else {
            note += "\n" + text
        }
        HapticManager.shared.impact()
    }
}

// MARK: - Quick Note Chip

private struct QuickNoteChip: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.yellow)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.yellow.opacity(0.15))
                )
        }
    }
}

#Preview {
    RecentNotesCard()
        .padding()
        .background(Color(.systemGroupedBackground))
        .modelContainer(for: Word.self)
}
