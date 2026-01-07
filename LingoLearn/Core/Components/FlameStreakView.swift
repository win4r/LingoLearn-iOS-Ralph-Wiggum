//
//  FlameStreakView.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI

struct FlameStreakView: View {
    let streakCount: Int
    @State private var isAnimating = false
    @State private var flameScale: CGFloat = 1.0
    @State private var flameOpacity: Double = 1.0
    @State private var glowOpacity: Double = 0
    @State private var sparkleRotation: Double = 0
    @State private var appeared = false
    @State private var flameOffset: CGFloat = 0
    @State private var particlePhase: Double = 0

    private var isMilestone: Bool {
        [7, 14, 30, 50, 100, 365].contains(streakCount)
    }

    private var flameColors: [Color] {
        if streakCount >= 100 {
            return [.purple, .blue, .cyan]
        } else if streakCount >= 30 {
            return [.red, .orange, .yellow]
        } else if streakCount >= 7 {
            return [.orange, .yellow, .white]
        } else {
            return [.orange, .red, .orange]
        }
    }

    private var flameColor: LinearGradient {
        LinearGradient(colors: Array(flameColors.prefix(2)), startPoint: .top, endPoint: .bottom)
    }

    private var accentColor: Color {
        flameColors.first ?? .orange
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                // Sparkle ring for milestones
                if isMilestone {
                    ForEach(0..<6, id: \.self) { i in
                        Circle()
                            .fill(flameColors.last ?? .yellow)
                            .frame(width: 4, height: 4)
                            .offset(y: -22)
                            .rotationEffect(.degrees(Double(i) * 60 + sparkleRotation))
                            .opacity(glowOpacity * 0.7)
                    }
                }

                // Rising particles for active streaks
                if streakCount > 0 {
                    ForEach(0..<5, id: \.self) { i in
                        FlameParticle(
                            color: flameColors[i % flameColors.count],
                            delay: Double(i) * 0.3,
                            phase: particlePhase
                        )
                    }
                }

                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accentColor.opacity(0.4), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 30
                        )
                    )
                    .frame(width: 50, height: 50)
                    .opacity(isMilestone ? glowOpacity : 0.3)
                    .scaleEffect(1 + flameOffset * 0.1)

                // Flame icon with enhanced styling and flicker
                Image(systemName: "flame.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(flameColor)
                    .scaleEffect(flameScale + flameOffset * 0.05)
                    .offset(y: flameOffset)
                    .shadow(color: accentColor.opacity(0.5), radius: 6 + flameOffset * 2, y: 2)
                    .symbolEffect(.bounce, value: isAnimating)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(streakCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .contentTransition(.numericText())

                    Text("天")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                // Streak level indicator
                HStack(spacing: 4) {
                    ForEach(0..<min(streakCount, 7), id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                i < streakCount ?
                                    LinearGradient(colors: [accentColor, accentColor.opacity(0.7)], startPoint: .leading, endPoint: .trailing) :
                                    LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: 12, height: 4)
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeOut(duration: 0.3).delay(Double(i) * 0.05), value: appeared)
                    }
                    if streakCount > 7 {
                        Text("+")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(accentColor)
                    }
                }
            }

            // Milestone badge
            if isMilestone {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 24, height: 24)
                        .shadow(color: .orange.opacity(0.4), radius: 4, y: 2)

                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                }
                .scaleEffect(appeared ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.3), value: appeared)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))

                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.12), accentColor.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isMilestone ?
                        LinearGradient(colors: [accentColor.opacity(0.4), accentColor.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [accentColor.opacity(0.15)], startPoint: .top, endPoint: .bottom),
                    lineWidth: isMilestone ? 2 : 1
                )
        )
        .shadow(color: accentColor.opacity(0.1), radius: 8, y: 4)
        .onAppear {
            appeared = true
            if isMilestone {
                startGlowAnimation()
            }
            if streakCount > 0 {
                startFlickerAnimation()
            }
        }
        .onChange(of: streakCount) { oldValue, newValue in
            if newValue > oldValue {
                playIncreaseAnimation()
            }
        }
    }

    private func startGlowAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowOpacity = 0.8
        }
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            sparkleRotation = 360
        }
    }

    private func startFlickerAnimation() {
        // Flame flicker effect
        withAnimation(.easeInOut(duration: 0.15).repeatForever(autoreverses: true)) {
            flameOffset = -1.5
        }
        // Particle animation phase
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            particlePhase = 1
        }
    }

    private func playIncreaseAnimation() {
        HapticManager.shared.success()
        isAnimating = true

        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            flameScale = 1.3
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                flameScale = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isAnimating = false
        }
    }
}

// MARK: - Flame Particle

private struct FlameParticle: View {
    let color: Color
    let delay: Double
    let phase: Double

    @State private var yOffset: CGFloat = 0
    @State private var xOffset: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 1

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 4, height: 4)
            .blur(radius: 1)
            .offset(x: xOffset, y: yOffset)
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
                startAnimation()
            }
            .onChange(of: phase) { _, _ in
                startAnimation()
            }
    }

    private func startAnimation() {
        // Reset position
        yOffset = 0
        xOffset = CGFloat.random(in: -5...5)
        opacity = 0
        scale = 1

        // Animate upward
        withAnimation(.easeOut(duration: 1.5).delay(delay)) {
            yOffset = -35
            xOffset += CGFloat.random(in: -8...8)
            opacity = 0.8
        }

        // Fade out
        withAnimation(.easeIn(duration: 0.5).delay(delay + 1.0)) {
            opacity = 0
            scale = 0.3
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        FlameStreakView(streakCount: 7)
        FlameStreakView(streakCount: 30)
        FlameStreakView(streakCount: 100)
    }
    .padding()
}
