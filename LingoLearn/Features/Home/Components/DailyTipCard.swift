//
//  DailyTipCard.swift
//  LingoLearn
//
//  Daily learning tip card for home screen
//

import SwiftUI

struct DailyTipCard: View {
    @State private var showContent = false
    @State private var tipIndex: Int = 0

    private let tips: [(icon: String, title: String, tip: String, color: Color)] = [
        ("brain.head.profile", "间隔复习", "利用艾宾浩斯遗忘曲线，在遗忘前及时复习，记忆效果翻倍！", .purple),
        ("clock.fill", "最佳时间", "早晨和睡前是记忆的黄金时段，大脑更容易形成长期记忆。", .blue),
        ("text.quote", "情境记忆", "把单词放在例句中学习，比死记硬背效果好3倍！", .green),
        ("speaker.wave.2.fill", "多感官学习", "边听边读边写，调动多种感官，记忆更牢固。", .orange),
        ("arrow.triangle.2.circlepath", "主动回忆", "看到单词先想意思，比直接看答案更能加深记忆。", .teal),
        ("figure.walk", "碎片时间", "利用等车、排队等碎片时间，每天多学10个单词！", .pink),
        ("moon.stars.fill", "睡眠巩固", "睡前复习的内容，大脑会在睡眠中自动巩固。", .indigo),
    ]

    private var currentTip: (icon: String, title: String, tip: String, color: Color) {
        tips[tipIndex % tips.count]
    }

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [currentTip.color.opacity(0.2), currentTip.color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: currentTip.icon)
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [currentTip.color, currentTip.color.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("💡 今日小贴士")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(currentTip.title)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            LinearGradient(
                                colors: [currentTip.color, currentTip.color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }

                Text(currentTip.tip)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(currentTip.color.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 10)
        .onAppear {
            // Use day of year to select tip (changes daily)
            let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
            tipIndex = dayOfYear % tips.count

            withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
                showContent = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("今日学习小贴士: \(currentTip.title), \(currentTip.tip)")
    }
}

#Preview {
    VStack {
        DailyTipCard()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
