//
//  OnboardingHint.swift
//  LingoLearn
//
//  First-time user tutorial hints
//

import SwiftUI
import Combine

// MARK: - Onboarding Manager

class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()

    private let hasSeenSwipeHintKey = "hasSeenSwipeHint"
    private let hasSeenSearchHintKey = "hasSeenSearchHint"
    private let hasSeenFavoriteHintKey = "hasSeenFavoriteHint"

    @Published var showSwipeHint: Bool = false
    @Published var showSearchHint: Bool = false
    @Published var showFavoriteHint: Bool = false

    private init() {
        loadHintStates()
    }

    private func loadHintStates() {
        showSwipeHint = !UserDefaults.standard.bool(forKey: hasSeenSwipeHintKey)
        showSearchHint = !UserDefaults.standard.bool(forKey: hasSeenSearchHintKey)
        showFavoriteHint = !UserDefaults.standard.bool(forKey: hasSeenFavoriteHintKey)
    }

    func dismissSwipeHint() {
        UserDefaults.standard.set(true, forKey: hasSeenSwipeHintKey)
        showSwipeHint = false
    }

    func dismissSearchHint() {
        UserDefaults.standard.set(true, forKey: hasSeenSearchHintKey)
        showSearchHint = false
    }

    func dismissFavoriteHint() {
        UserDefaults.standard.set(true, forKey: hasSeenFavoriteHintKey)
        showFavoriteHint = false
    }

    func resetAllHints() {
        UserDefaults.standard.removeObject(forKey: hasSeenSwipeHintKey)
        UserDefaults.standard.removeObject(forKey: hasSeenSearchHintKey)
        UserDefaults.standard.removeObject(forKey: hasSeenFavoriteHintKey)
        loadHintStates()
    }
}

// MARK: - Onboarding Hint View

struct OnboardingHint: View {
    let icon: String
    let title: String
    let message: String
    let color: Color
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var pulseAnimation = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Animated icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [color.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 30
                            )
                        )
                        .frame(width: 50, height: 50)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0.5 : 1.0)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.2), color.opacity(0.1)],
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

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button(action: {
                    HapticManager.shared.selection()
                    withAnimation(.easeOut(duration: 0.2)) {
                        showContent = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onDismiss()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
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
                        colors: [color.opacity(0.3), color.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: color.opacity(0.15), radius: 12, y: 4)
        .scaleEffect(showContent ? 1 : 0.8)
        .opacity(showContent ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showContent = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
}

// MARK: - Swipe Gesture Hint

struct SwipeGestureHint: View {
    @StateObject private var onboarding = OnboardingManager.shared
    @State private var arrowOffset: CGFloat = 0

    var body: some View {
        if onboarding.showSwipeHint {
            VStack(spacing: 16) {
                OnboardingHint(
                    icon: "hand.draw",
                    title: "滑动手势提示",
                    message: "左滑 = 不认识，右滑 = 认识，上滑 = 收藏，下滑 = 太简单",
                    color: .blue,
                    onDismiss: {
                        onboarding.dismissSwipeHint()
                    }
                )

                // Animated gesture preview
                HStack(spacing: 24) {
                    GestureArrow(direction: .left, label: "不认识", color: .red)
                    GestureArrow(direction: .up, label: "收藏", color: .yellow)
                    GestureArrow(direction: .right, label: "认识", color: .green)
                    GestureArrow(direction: .down, label: "太简单", color: .cyan)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            }
            .padding(.horizontal)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

private struct GestureArrow: View {
    enum Direction {
        case left, right, up, down

        var systemImage: String {
            switch self {
            case .left: return "arrow.left"
            case .right: return "arrow.right"
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            }
        }
    }

    let direction: Direction
    let label: String
    let color: Color

    @State private var isAnimating = false

    private var offset: (x: CGFloat, y: CGFloat) {
        let amount: CGFloat = isAnimating ? 5 : 0
        switch direction {
        case .left: return (-amount, 0)
        case .right: return (amount, 0)
        case .up: return (0, -amount)
        case .down: return (0, amount)
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: direction.systemImage)
                    .font(.subheadline.bold())
                    .foregroundStyle(color)
                    .offset(x: offset.x, y: offset.y)
            }

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - View Modifier for Hints

struct OnboardingHintModifier: ViewModifier {
    let hintType: HintType
    @StateObject private var onboarding = OnboardingManager.shared

    enum HintType {
        case swipe
        case search
        case favorite
    }

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                switch hintType {
                case .swipe:
                    if onboarding.showSwipeHint {
                        SwipeGestureHint()
                            .padding(.top, 8)
                    }
                case .search:
                    EmptyView()
                case .favorite:
                    EmptyView()
                }
            }
    }
}

extension View {
    func onboardingHint(_ type: OnboardingHintModifier.HintType) -> some View {
        modifier(OnboardingHintModifier(hintType: type))
    }
}

#Preview {
    VStack(spacing: 20) {
        OnboardingHint(
            icon: "hand.draw",
            title: "滑动手势提示",
            message: "左滑 = 不认识，右滑 = 认识，上滑 = 收藏，下滑 = 太简单",
            color: .blue,
            onDismiss: {}
        )

        SwipeGestureHint()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
