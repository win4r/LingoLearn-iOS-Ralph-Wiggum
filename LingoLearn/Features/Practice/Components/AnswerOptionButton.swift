//
//  AnswerOptionButton.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI

enum AnswerState {
    case normal
    case selected
    case correct
    case wrong
    case disabled
    case missed  // For multi-select: correct answer that wasn't selected
}

struct AnswerOptionButton: View {
    let text: String
    let state: AnswerState
    let action: () -> Void

    @State private var isPressed = false
    @State private var showResultAnimation = false
    @State private var glowOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -100
    @State private var appeared = false

    private var backgroundColor: LinearGradient {
        switch state {
        case .normal:
            return LinearGradient(colors: [Color(.systemBackground)], startPoint: .top, endPoint: .bottom)
        case .selected:
            return LinearGradient(
                colors: [Color.accentColor.opacity(0.18), Color.accentColor.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .correct:
            return LinearGradient(
                colors: [Color.green.opacity(0.18), Color.mint.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .wrong:
            return LinearGradient(
                colors: [Color.red.opacity(0.18), Color.orange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .disabled:
            return LinearGradient(colors: [Color.gray.opacity(0.05)], startPoint: .top, endPoint: .bottom)
        case .missed:
            return LinearGradient(
                colors: [Color.orange.opacity(0.15), Color.yellow.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var stateColors: [Color] {
        switch state {
        case .normal: return [.gray.opacity(0.3)]
        case .selected: return [.accentColor, .accentColor.opacity(0.7)]
        case .correct: return [.green, .mint]
        case .wrong: return [.red, .orange]
        case .disabled: return [.gray.opacity(0.2)]
        case .missed: return [.orange, .yellow]
        }
    }

    private var borderGradient: LinearGradient {
        switch state {
        case .normal:
            return LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
        case .selected:
            return LinearGradient(colors: [.accentColor, .accentColor.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
        case .correct:
            return LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
        case .wrong:
            return LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
        case .disabled:
            return LinearGradient(colors: [Color.gray.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
        case .missed:
            return LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
        }
    }

    private var icon: String? {
        switch state {
        case .correct:
            return "checkmark.circle.fill"
        case .wrong:
            return "xmark.circle.fill"
        case .selected:
            return "circle.fill"
        case .missed:
            return "exclamationmark.circle.fill"
        default:
            return nil
        }
    }

    private var iconGradient: LinearGradient {
        switch state {
        case .correct:
            return LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom)
        case .wrong:
            return LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom)
        case .selected:
            return LinearGradient(colors: [.accentColor, .accentColor.opacity(0.7)], startPoint: .top, endPoint: .bottom)
        case .missed:
            return LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)
        default:
            return LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
        }
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.impact()
            action()
        }) {
            ZStack {
                // Shimmer effect for correct answers
                if state == .correct {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.3), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 50)
                        .offset(x: shimmerOffset)
                        .mask(RoundedRectangle(cornerRadius: 14))
                }

                HStack(spacing: 14) {
                    // Option indicator with enhanced styling
                    ZStack {
                        // Glow for selected/result states
                        if state != .normal && state != .disabled {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [stateColors.first?.opacity(0.3) ?? .clear, .clear],
                                        center: .center,
                                        startRadius: 5,
                                        endRadius: 20
                                    )
                                )
                                .frame(width: 36, height: 36)
                                .opacity(glowOpacity)
                        }

                        Circle()
                            .stroke(
                                state == .normal ?
                                    LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .top, endPoint: .bottom) :
                                    LinearGradient(colors: stateColors, startPoint: .top, endPoint: .bottom),
                                lineWidth: state == .normal ? 2 : 0
                            )
                            .frame(width: 26, height: 26)

                        if state != .normal && state != .disabled {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: stateColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 26, height: 26)
                                .scaleEffect(showResultAnimation ? 1.0 : 0.5)
                                .opacity(showResultAnimation ? 1.0 : 0)
                        }

                        if let icon = icon {
                            Image(systemName: icon)
                                .foregroundStyle(.white)
                                .font(.system(size: state == .selected ? 10 : 14, weight: .bold))
                                .scaleEffect(showResultAnimation ? 1.0 : 0.5)
                                .opacity(showResultAnimation ? 1.0 : 0)
                        }
                    }
                    .frame(width: 26, height: 26)

                    Text(text)
                        .font(.body)
                        .fontWeight(state == .correct || state == .selected ? .semibold : .regular)
                        .foregroundStyle(state == .disabled ? .secondary : .primary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    // Result badge for correct/wrong
                    if state == .correct {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.caption2.weight(.bold))
                            Text("正确")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                        .shadow(color: .green.opacity(0.4), radius: 4, y: 2)
                        .scaleEffect(showResultAnimation ? 1.0 : 0.5)
                        .opacity(showResultAnimation ? 1.0 : 0)
                    } else if state == .wrong {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.caption2.weight(.bold))
                            Text("错误")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                        .shadow(color: .red.opacity(0.4), radius: 4, y: 2)
                        .scaleEffect(showResultAnimation ? 1.0 : 0.5)
                        .opacity(showResultAnimation ? 1.0 : 0)
                    } else if state == .missed {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2.weight(.bold))
                            Text("漏选")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                        .shadow(color: .orange.opacity(0.4), radius: 4, y: 2)
                        .scaleEffect(showResultAnimation ? 1.0 : 0.5)
                        .opacity(showResultAnimation ? 1.0 : 0)
                    } else if state == .normal {
                        // Subtle chevron for normal state
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .opacity(appeared ? 1 : 0)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemBackground))

                    RoundedRectangle(cornerRadius: 14)
                        .fill(backgroundColor)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(borderGradient, lineWidth: state == .normal ? 1.5 : 2)
            )
            .shadow(
                color: state == .correct ? .green.opacity(0.25) :
                       state == .wrong ? .red.opacity(0.25) :
                       state == .missed ? .orange.opacity(0.25) :
                       state == .selected ? .accentColor.opacity(0.2) : .black.opacity(0.03),
                radius: state == .normal ? 4 : 10,
                y: state == .normal ? 2 : 4
            )
        }
        .buttonStyle(AnswerButtonStyle())
        .disabled(state == .disabled || state == .correct || state == .wrong || state == .missed)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(state == .normal ? "双击选择此答案" : "")
        .accessibilityAddTraits(state == .correct ? .isSelected : [])
        .onChange(of: state) { oldValue, newValue in
            if newValue == .correct || newValue == .wrong || newValue == .selected || newValue == .missed {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    showResultAnimation = true
                }

                // Glow animation for result states
                if newValue == .correct || newValue == .wrong || newValue == .missed {
                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        glowOpacity = 0.8
                    }
                }

                // Shimmer for correct
                if newValue == .correct {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        shimmerOffset = 400
                    }
                }
            } else {
                showResultAnimation = false
                glowOpacity = 0
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                appeared = true
            }

            if state == .correct || state == .wrong || state == .selected || state == .missed {
                showResultAnimation = true
            }
        }
    }

    private var accessibilityLabel: String {
        switch state {
        case .normal:
            return "答案选项: \(text)"
        case .selected:
            return "已选择: \(text)"
        case .correct:
            return "正确答案: \(text)"
        case .wrong:
            return "错误答案: \(text)"
        case .disabled:
            return "答案选项: \(text), 不可选择"
        case .missed:
            return "漏选答案: \(text)"
        }
    }
}

// MARK: - Answer Button Style

struct AnswerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 16) {
        AnswerOptionButton(text: "Hello", state: .normal, action: {})
        AnswerOptionButton(text: "Selected", state: .selected, action: {})
        AnswerOptionButton(text: "Correct Answer", state: .correct, action: {})
        AnswerOptionButton(text: "Wrong Answer", state: .wrong, action: {})
        AnswerOptionButton(text: "Missed Answer", state: .missed, action: {})
        AnswerOptionButton(text: "Disabled", state: .disabled, action: {})
    }
    .padding()
}
