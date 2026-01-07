//
//  StudyReminderCard.swift
//  LingoLearn
//
//  Shows time since last study and encourages users to study
//

import SwiftUI

struct StudyReminderCard: View {
    let lastStudyDate: Date?
    let onStartLearning: () -> Void

    @State private var showContent = false

    private var timeSinceLastStudy: String {
        guard let lastStudy = lastStudyDate else {
            return "还没开始学习"
        }

        let now = Date()
        let interval = now.timeIntervalSince(lastStudy)

        if interval < 60 {
            return "刚刚学习过"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)分钟前学习"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)小时前学习"
        } else {
            let days = Int(interval / 86400)
            if days == 1 {
                return "昨天学习过"
            } else {
                return "\(days)天前学习"
            }
        }
    }

    private var urgencyLevel: UrgencyLevel {
        guard let lastStudy = lastStudyDate else {
            return .high
        }

        let hours = Date().timeIntervalSince(lastStudy) / 3600

        if hours < 12 {
            return .low
        } else if hours < 24 {
            return .medium
        } else {
            return .high
        }
    }

    private enum UrgencyLevel {
        case low, medium, high

        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            }
        }

        var icon: String {
            switch self {
            case .low: return "checkmark.circle.fill"
            case .medium: return "clock.fill"
            case .high: return "exclamationmark.triangle.fill"
            }
        }

        var message: String {
            switch self {
            case .low: return "保持良好的学习节奏！"
            case .medium: return "该复习了，保持连续学习！"
            case .high: return "快来学习吧，别让记忆流失！"
            }
        }
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.impact()
            SoundService.shared.playTap()
            onStartLearning()
        }) {
            HStack(spacing: 14) {
                // Icon with urgency indicator
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [urgencyLevel.color.opacity(0.2), urgencyLevel.color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: urgencyLevel.icon)
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [urgencyLevel.color, urgencyLevel.color.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .symbolEffect(.pulse, options: .repeating.speed(0.5), value: urgencyLevel == .high)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(timeSinceLastStudy)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        Spacer()

                        // Quick start button
                        HStack(spacing: 4) {
                            Text("开始")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            LinearGradient(
                                colors: [urgencyLevel.color, urgencyLevel.color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                    }

                    Text(urgencyLevel.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(urgencyLevel.color.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 10)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                showContent = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(timeSinceLastStudy), \(urgencyLevel.message)")
        .accessibilityHint("双击开始学习")
    }
}

#Preview("Just Studied") {
    StudyReminderCard(lastStudyDate: Date()) {
        print("Start learning")
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Hours Ago") {
    StudyReminderCard(lastStudyDate: Date().addingTimeInterval(-18 * 3600)) {
        print("Start learning")
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Days Ago") {
    StudyReminderCard(lastStudyDate: Date().addingTimeInterval(-3 * 86400)) {
        print("Start learning")
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Never Studied") {
    StudyReminderCard(lastStudyDate: nil) {
        print("Start learning")
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
