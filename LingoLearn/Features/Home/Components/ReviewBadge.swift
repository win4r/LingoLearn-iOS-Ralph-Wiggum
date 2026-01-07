//
//  ReviewBadge.swift
//  LingoLearn
//
//  Badge showing words due for review
//

import SwiftUI

struct ReviewBadge: View {
    let wordsDueForReview: Int
    let onTap: () -> Void

    @State private var showContent = false
    @State private var pulseAnimation = false
    @State private var glowOpacity: Double = 0
    @State private var iconBounce = false

    private var urgencyLevel: UrgencyLevel {
        switch wordsDueForReview {
        case 1..<10:
            return .low
        case 10..<30:
            return .medium
        default:
            return .high
        }
    }

    private enum UrgencyLevel {
        case low, medium, high

        var colors: [Color] {
            switch self {
            case .low: return [.green, .mint]
            case .medium: return [.orange, .yellow]
            case .high: return [.red, .orange]
            }
        }

        var color: Color {
            colors.first ?? .green
        }

        var icon: String {
            switch self {
            case .low: return "clock.fill"
            case .medium: return "clock.badge.exclamationmark.fill"
            case .high: return "exclamationmark.triangle.fill"
            }
        }

        var message: String {
            switch self {
            case .low: return "别忘了复习哦"
            case .medium: return "需要及时复习"
            case .high: return "紧急！请立即复习"
            }
        }
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.impact()
            onTap()
        }) {
            HStack(spacing: 14) {
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [urgencyLevel.color.opacity(0.4), .clear],
                                center: .center,
                                startRadius: 15,
                                endRadius: 35
                            )
                        )
                        .frame(width: 60, height: 60)
                        .opacity(glowOpacity)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [urgencyLevel.color.opacity(0.2), urgencyLevel.color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)

                    Image(systemName: urgencyLevel.icon)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(
                            LinearGradient(
                                colors: urgencyLevel.colors,
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .symbolEffect(.bounce, value: iconBounce)
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text("待复习单词")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("\(wordsDueForReview)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3)
                            .background(
                                LinearGradient(
                                    colors: urgencyLevel.colors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: urgencyLevel.color.opacity(0.3), radius: 4, y: 2)
                    }

                    Text(urgencyLevel.message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Enhanced chevron
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [urgencyLevel.color.opacity(0.15), urgencyLevel.color.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: urgencyLevel.colors,
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.systemBackground))

                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [urgencyLevel.color.opacity(0.08), urgencyLevel.color.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [urgencyLevel.color.opacity(0.3), urgencyLevel.color.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: urgencyLevel.color.opacity(0.15), radius: 12, y: 4)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("待复习单词\(wordsDueForReview)个,\(urgencyLevel.message)")
        .accessibilityHint("双击开始复习")
        .accessibilityAddTraits(.isButton)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 10)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.4)) {
                showContent = true
            }

            // Icon bounce
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                iconBounce = true
            }

            // Pulse animation for medium and high urgency
            if urgencyLevel == .high || urgencyLevel == .medium {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                    glowOpacity = urgencyLevel == .high ? 0.8 : 0.5
                }
            }
        }
    }
}

#Preview {
    ReviewBadge(wordsDueForReview: 15) {
        print("Tapped")
    }
    .padding()
}
