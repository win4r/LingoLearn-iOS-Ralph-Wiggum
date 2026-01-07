//
//  MasteryCelebration.swift
//  LingoLearn
//
//  Celebration animation when a word reaches mastered status
//

import SwiftUI

struct MasteryCelebration: View {
    @Binding var isShowing: Bool
    let wordEnglish: String

    @State private var showContent = false
    @State private var starScale: CGFloat = 0
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 1
    @State private var particlesVisible = false

    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(showContent ? 0.4 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Celebration content
            VStack(spacing: 24) {
                // Star burst animation
                ZStack {
                    // Expanding rings
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.yellow.opacity(0.6), .orange.opacity(0.4)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 120 + CGFloat(i * 40), height: 120 + CGFloat(i * 40))
                            .scaleEffect(ringScale)
                            .opacity(ringOpacity * (1 - Double(i) * 0.3))
                    }

                    // Particles
                    ForEach(0..<12, id: \.self) { i in
                        MasteryParticle(
                            angle: Double(i) * 30,
                            delay: Double(i) * 0.05,
                            isVisible: particlesVisible
                        )
                    }

                    // Central star
                    ZStack {
                        // Glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.yellow.opacity(0.5), .clear],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 70
                                )
                            )
                            .frame(width: 140, height: 140)
                            .scaleEffect(starScale)

                        // Star background
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .scaleEffect(starScale)

                        // Star icon
                        Image(systemName: "star.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.white)
                            .scaleEffect(starScale)
                            .shadow(color: .orange.opacity(0.5), radius: 10)
                    }
                }

                // Text content
                VStack(spacing: 12) {
                    Text("单词已掌握！")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text(wordEnglish)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    Text("恭喜！这个单词已经牢牢记住了")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                // Continue button
                Button(action: dismiss) {
                    Text("继续学习")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .orange.opacity(0.4), radius: 10, y: 5)
                }
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.8)
            }
            .padding(40)
        }
        .opacity(isShowing ? 1 : 0)
        .onAppear {
            if isShowing {
                playAnimation()
            }
        }
        .onChange(of: isShowing) { _, newValue in
            if newValue {
                playAnimation()
            }
        }
    }

    private func playAnimation() {
        // Reset states
        showContent = false
        starScale = 0
        ringScale = 0.5
        ringOpacity = 1
        particlesVisible = false

        // Star entrance
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            starScale = 1
            showContent = true
        }

        // Ring expansion
        withAnimation(.easeOut(duration: 0.8)) {
            ringScale = 1.5
            ringOpacity = 0
        }

        // Particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            particlesVisible = true
        }

        // Haptic feedback
        HapticManager.shared.success()
        SoundService.shared.playComplete()
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            showContent = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isShowing = false
        }
    }
}

// MARK: - Mastery Particle

private struct MasteryParticle: View {
    let angle: Double
    let delay: Double
    let isVisible: Bool

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var rotation: Double = 0

    private var particleIcon: String {
        let icons = ["star.fill", "sparkle", "star.fill", "heart.fill"]
        return icons[Int(angle / 30) % icons.count]
    }

    var body: some View {
        Image(systemName: particleIcon)
            .font(.caption)
            .foregroundStyle(
                LinearGradient(
                    colors: [.yellow, .orange],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .offset(
                x: CGFloat(cos(angle * .pi / 180)) * (60 + offset),
                y: CGFloat(sin(angle * .pi / 180)) * (60 + offset)
            )
            .rotationEffect(.degrees(rotation))
            .opacity(isVisible ? opacity : 0)
            .scaleEffect(isVisible ? 1 : 0)
            .onChange(of: isVisible) { _, visible in
                if visible {
                    withAnimation(.easeOut(duration: 0.8).delay(delay)) {
                        offset = 80
                        opacity = 0
                        rotation = Double.random(in: -180...180)
                    }
                }
            }
    }
}

// MARK: - View Modifier

struct MasteryCelebrationModifier: ViewModifier {
    @Binding var isShowing: Bool
    let wordEnglish: String

    func body(content: Content) -> some View {
        ZStack {
            content

            if isShowing {
                MasteryCelebration(isShowing: $isShowing, wordEnglish: wordEnglish)
                    .zIndex(1000)
            }
        }
    }
}

extension View {
    func masteryCelebration(isShowing: Binding<Bool>, wordEnglish: String) -> some View {
        modifier(MasteryCelebrationModifier(isShowing: isShowing, wordEnglish: wordEnglish))
    }
}

#Preview {
    ZStack {
        Color.blue
            .ignoresSafeArea()

        MasteryCelebration(isShowing: .constant(true), wordEnglish: "Accomplish")
    }
}
