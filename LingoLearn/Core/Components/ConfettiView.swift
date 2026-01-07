//
//  ConfettiView.swift
//  LingoLearn
//
//  Celebratory confetti animation for achievements
//

import SwiftUI

struct ConfettiPiece: Identifiable {
    let id = UUID()
    var position: CGPoint
    var rotation: Double
    var scale: CGFloat
    var color: Color
    var secondaryColor: Color
    var shape: ConfettiShape
    var velocity: CGPoint
    var rotationSpeed: Double
    var wobble: Double
    var opacity: Double

    enum ConfettiShape: CaseIterable {
        case circle, square, triangle, star, ribbon, heart
    }
}

struct ConfettiView: View {
    @Binding var isActive: Bool
    let duration: Double
    var intensity: ConfettiIntensity = .normal

    @State private var pieces: [ConfettiPiece] = []
    @State private var animationTimer: Timer?
    @State private var elapsedTime: Double = 0

    enum ConfettiIntensity {
        case light, normal, intense

        var pieceCount: Int {
            switch self {
            case .light: return 30
            case .normal: return 60
            case .intense: return 100
            }
        }

        var burstWaves: Int {
            switch self {
            case .light: return 1
            case .normal: return 2
            case .intense: return 3
            }
        }
    }

    private let colorPalettes: [[Color]] = [
        [.red, .orange],
        [.orange, .yellow],
        [.yellow, .green],
        [.green, .mint],
        [.mint, .cyan],
        [.cyan, .blue],
        [.blue, .purple],
        [.purple, .pink],
        [.pink, .red]
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(pieces) { piece in
                    ConfettiPieceView(piece: piece, elapsedTime: elapsedTime)
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    startConfetti(in: geometry.size)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func startConfetti(in size: CGSize) {
        elapsedTime = 0

        // Create initial burst
        pieces = (0..<intensity.pieceCount).map { _ in
            createPiece(in: size, spawnPosition: .center)
        }

        HapticManager.shared.success()

        // Schedule additional bursts for higher intensity
        for wave in 1..<intensity.burstWaves {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(wave) * 0.15) {
                let spawnPos: SpawnPosition = wave % 2 == 0 ? .left : .right
                let additionalPieces = (0..<(intensity.pieceCount / 2)).map { _ in
                    createPiece(in: size, spawnPosition: spawnPos)
                }
                pieces.append(contentsOf: additionalPieces)
                HapticManager.shared.selection()
            }
        }

        // Animate pieces
        let interval: Double = 1.0 / 60.0 // 60 FPS

        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            elapsedTime += interval

            // Update piece positions with physics
            for i in pieces.indices {
                // Apply wobble for more natural movement
                let wobbleOffset = sin(elapsedTime * 8 + pieces[i].wobble) * 0.5

                pieces[i].position.x += pieces[i].velocity.x + wobbleOffset
                pieces[i].position.y += pieces[i].velocity.y
                pieces[i].velocity.y += 0.25 // Gravity (slightly reduced)
                pieces[i].velocity.x *= 0.995 // Air resistance
                pieces[i].rotation += pieces[i].rotationSpeed
                pieces[i].scale *= 0.997

                // Fade out over time
                if elapsedTime > duration * 0.6 {
                    pieces[i].opacity *= 0.97
                }
            }

            // End animation
            if elapsedTime >= duration {
                timer.invalidate()
                withAnimation(.easeOut(duration: 0.2)) {
                    pieces = []
                }
                isActive = false
            }
        }
    }

    private enum SpawnPosition {
        case center, left, right
    }

    private func createPiece(in size: CGSize, spawnPosition: SpawnPosition) -> ConfettiPiece {
        let palette = colorPalettes.randomElement() ?? [.blue, .purple]

        let spawnX: CGFloat
        let velocityX: CGFloat

        switch spawnPosition {
        case .center:
            spawnX = size.width / 2 + CGFloat.random(in: -30...30)
            velocityX = CGFloat.random(in: -10...10)
        case .left:
            spawnX = size.width * 0.2
            velocityX = CGFloat.random(in: 2...12)
        case .right:
            spawnX = size.width * 0.8
            velocityX = CGFloat.random(in: -12...(-2))
        }

        return ConfettiPiece(
            position: CGPoint(x: spawnX, y: size.height * 0.3 + CGFloat.random(in: -20...20)),
            rotation: Double.random(in: 0...360),
            scale: CGFloat.random(in: 0.6...1.4),
            color: palette[0],
            secondaryColor: palette[1],
            shape: ConfettiPiece.ConfettiShape.allCases.randomElement() ?? .circle,
            velocity: CGPoint(
                x: velocityX,
                y: CGFloat.random(in: (-18)...(-8))
            ),
            rotationSpeed: Double.random(in: -12...12),
            wobble: Double.random(in: 0...(.pi * 2)),
            opacity: 1.0
        )
    }
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    let elapsedTime: Double

    private var shimmerOpacity: Double {
        (sin(elapsedTime * 10 + piece.wobble) + 1) / 4 + 0.5
    }

    var body: some View {
        shapeView
            .frame(width: 12 * piece.scale, height: piece.shape == .ribbon ? 20 * piece.scale : 12 * piece.scale)
            .rotationEffect(.degrees(piece.rotation))
            .rotation3DEffect(.degrees(piece.rotation * 0.5), axis: (x: 1, y: 0, z: 0))
            .position(piece.position)
            .opacity(piece.opacity * shimmerOpacity)
    }

    @ViewBuilder
    private var shapeView: some View {
        switch piece.shape {
        case .circle:
            Circle()
                .fill(
                    RadialGradient(
                        colors: [piece.color, piece.secondaryColor],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 10
                    )
                )
        case .square:
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [piece.color, piece.secondaryColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        case .triangle:
            Triangle()
                .fill(
                    LinearGradient(
                        colors: [piece.color, piece.secondaryColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        case .star:
            Star(corners: 5, smoothness: 0.45)
                .fill(
                    LinearGradient(
                        colors: [piece.color, piece.secondaryColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        case .ribbon:
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [piece.color, piece.secondaryColor, piece.color],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        case .heart:
            Heart()
                .fill(
                    LinearGradient(
                        colors: [piece.color, piece.secondaryColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }
}

// Custom shapes for confetti
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct Star: Shape {
    let corners: Int
    let smoothness: CGFloat

    func path(in rect: CGRect) -> Path {
        guard corners >= 2 else { return Path() }

        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        var currentAngle = -CGFloat.pi / 2
        let angleAdjustment = .pi * 2 / CGFloat(corners * 2)
        let innerX = center.x * smoothness
        let innerY = center.y * smoothness

        var path = Path()

        for corner in 0..<corners * 2 {
            let sinAngle = sin(currentAngle)
            let cosAngle = cos(currentAngle)
            let bottom: CGFloat

            if corner.isMultiple(of: 2) {
                bottom = center.x * cosAngle + center.x
                let point = CGPoint(x: bottom, y: center.y * sinAngle + center.y)
                if corner == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            } else {
                bottom = innerX * cosAngle + center.x
                let point = CGPoint(x: bottom, y: innerY * sinAngle + center.y)
                path.addLine(to: point)
            }

            currentAngle += angleAdjustment
        }

        path.closeSubpath()
        return path
    }
}

// Heart shape for confetti
struct Heart: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width / 2, y: height))

        path.addCurve(
            to: CGPoint(x: 0, y: height / 4),
            control1: CGPoint(x: width / 2 - width / 4, y: height * 3 / 4),
            control2: CGPoint(x: 0, y: height / 2)
        )

        path.addArc(
            center: CGPoint(x: width / 4, y: height / 4),
            radius: width / 4,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )

        path.addArc(
            center: CGPoint(x: width * 3 / 4, y: height / 4),
            radius: width / 4,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )

        path.addCurve(
            to: CGPoint(x: width / 2, y: height),
            control1: CGPoint(x: width, y: height / 2),
            control2: CGPoint(x: width / 2 + width / 4, y: height * 3 / 4)
        )

        return path
    }
}

/// A modifier to easily add confetti to any view
struct ConfettiModifier: ViewModifier {
    @Binding var isActive: Bool
    var duration: Double = 3.0
    var intensity: ConfettiView.ConfettiIntensity = .normal

    func body(content: Content) -> some View {
        ZStack {
            content
            ConfettiView(isActive: $isActive, duration: duration, intensity: intensity)
        }
    }
}

extension View {
    func confetti(
        isActive: Binding<Bool>,
        duration: Double = 3.0,
        intensity: ConfettiView.ConfettiIntensity = .normal
    ) -> some View {
        modifier(ConfettiModifier(isActive: isActive, duration: duration, intensity: intensity))
    }
}

// MARK: - Milestone Celebration View

struct MilestoneCelebrationView: View {
    let milestone: Int
    @Binding var isShowing: Bool

    @State private var showContent = false
    @State private var iconScale: CGFloat = 0.3
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 0
    @State private var showConfetti = false

    private var milestoneEmoji: String {
        switch milestone {
        case 7: return "flame.fill"
        case 30: return "crown.fill"
        case 100: return "trophy.fill"
        case 365: return "sparkles"
        default: return "star.fill"
        }
    }

    private var milestoneTitle: String {
        switch milestone {
        case 7: return "坚持一周!"
        case 30: return "坚持一个月!"
        case 100: return "传奇百日!"
        case 365: return "整整一年!"
        default: return "里程碑达成!"
        }
    }

    private var milestoneSubtitle: String {
        switch milestone {
        case 7: return "你已经连续学习7天，习惯正在形成"
        case 30: return "30天的坚持，你的词汇量大幅提升"
        case 100: return "100天！你是真正的学习达人"
        case 365: return "一年的坚持，你已经成为词汇大师"
        default: return "继续保持，你做得很棒!"
        }
    }

    private var milestoneColors: [Color] {
        switch milestone {
        case 7: return [.orange, .red]
        case 30: return [.purple, .pink]
        case 100: return [.yellow, .orange]
        case 365: return [.blue, .cyan]
        default: return [.green, .teal]
        }
    }

    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(showContent ? 0.5 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Celebration content
            VStack(spacing: 24) {
                // Animated icon with rings
                ZStack {
                    // Expanding rings
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: milestoneColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 100 + CGFloat(i) * 30, height: 100 + CGFloat(i) * 30)
                            .scaleEffect(ringScale + CGFloat(i) * 0.1)
                            .opacity(ringOpacity - Double(i) * 0.2)
                    }

                    // Icon background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: milestoneColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: milestoneColors.first?.opacity(0.5) ?? .clear, radius: 20)

                    // Icon
                    Image(systemName: milestoneEmoji)
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                        .scaleEffect(iconScale)
                }

                // Title
                VStack(spacing: 8) {
                    Text(milestoneTitle)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: milestoneColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text(milestoneSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                // Streak count badge
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(milestone)天连续学习")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(.systemGray6))
                )
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.8)

                // Dismiss button
                Button(action: dismiss) {
                    Text("太棒了!")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: milestoneColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: milestoneColors.first?.opacity(0.4) ?? .clear, radius: 8, y: 4)
                }
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.8)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.2), radius: 30, y: 10)
            )
            .scaleEffect(showContent ? 1 : 0.8)
            .opacity(showContent ? 1 : 0)

            // Confetti overlay
            ConfettiView(isActive: $showConfetti, duration: 3.5, intensity: .intense)
        }
        .onChange(of: isShowing) { _, newValue in
            if newValue {
                showCelebration()
            }
        }
        .onAppear {
            if isShowing {
                showCelebration()
            }
        }
    }

    private func showCelebration() {
        HapticManager.shared.success()
        showConfetti = true

        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            showContent = true
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.1)) {
            iconScale = 1.0
        }

        withAnimation(.easeOut(duration: 1).delay(0.2)) {
            ringScale = 1.2
            ringOpacity = 0.6
        }

        // Ring pulse animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.5)) {
            ringOpacity = 0.3
        }
    }

    private func dismiss() {
        HapticManager.shared.impact()
        withAnimation(.easeOut(duration: 0.3)) {
            showContent = false
            ringOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isShowing = false
        }
    }
}

// MARK: - Milestone Celebration Modifier

struct MilestoneCelebrationModifier: ViewModifier {
    @Binding var isShowing: Bool
    let milestone: Int

    func body(content: Content) -> some View {
        ZStack {
            content
            if isShowing {
                MilestoneCelebrationView(milestone: milestone, isShowing: $isShowing)
            }
        }
    }
}

extension View {
    func milestoneCelebration(isShowing: Binding<Bool>, milestone: Int) -> some View {
        modifier(MilestoneCelebrationModifier(isShowing: isShowing, milestone: milestone))
    }

    func goalCelebration(isShowing: Binding<Bool>) -> some View {
        modifier(GoalCelebrationModifier(isShowing: isShowing))
    }
}

// MARK: - Goal Celebration View

struct GoalCelebrationView: View {
    @Binding var isShowing: Bool

    @State private var showContent = false
    @State private var iconScale: CGFloat = 0.3
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 0
    @State private var showConfetti = false

    private let celebrationColors: [Color] = [.green, .mint]

    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(showContent ? 0.5 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Celebration content
            VStack(spacing: 24) {
                // Animated icon with rings
                ZStack {
                    // Expanding rings
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: celebrationColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 100 + CGFloat(i) * 30, height: 100 + CGFloat(i) * 30)
                            .scaleEffect(ringScale + CGFloat(i) * 0.1)
                            .opacity(ringOpacity - Double(i) * 0.2)
                    }

                    // Icon background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: celebrationColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: celebrationColors.first?.opacity(0.5) ?? .clear, radius: 20)

                    // Icon
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                        .scaleEffect(iconScale)
                }

                // Title
                VStack(spacing: 8) {
                    Text("目标达成!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: celebrationColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("恭喜你完成了今天的学习目标")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                // Encouragement badge
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.yellow)
                    Text("继续保持，明天再创佳绩!")
                        .fontWeight(.medium)
                }
                .font(.caption)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(.systemGray6))
                )
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.8)

                // Dismiss button
                Button(action: dismiss) {
                    Text("继续学习")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: celebrationColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: celebrationColors.first?.opacity(0.4) ?? .clear, radius: 8, y: 4)
                }
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.8)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.2), radius: 30, y: 10)
            )
            .scaleEffect(showContent ? 1 : 0.8)
            .opacity(showContent ? 1 : 0)

            // Confetti overlay
            ConfettiView(isActive: $showConfetti, duration: 3.5, intensity: .intense)
        }
        .onChange(of: isShowing) { _, newValue in
            if newValue {
                showCelebration()
            }
        }
        .onAppear {
            if isShowing {
                showCelebration()
            }
        }
    }

    private func showCelebration() {
        HapticManager.shared.success()
        SoundService.shared.playComplete()
        showConfetti = true

        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            showContent = true
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.1)) {
            iconScale = 1.0
        }

        withAnimation(.easeOut(duration: 1).delay(0.2)) {
            ringScale = 1.2
            ringOpacity = 0.6
        }

        // Ring pulse animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.5)) {
            ringOpacity = 0.3
        }
    }

    private func dismiss() {
        HapticManager.shared.impact()
        withAnimation(.easeOut(duration: 0.3)) {
            showContent = false
            ringOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isShowing = false
        }
    }
}

struct GoalCelebrationModifier: ViewModifier {
    @Binding var isShowing: Bool

    func body(content: Content) -> some View {
        ZStack {
            content
            if isShowing {
                GoalCelebrationView(isShowing: $isShowing)
            }
        }
    }
}

#Preview("Confetti") {
    struct PreviewWrapper: View {
        @State private var showConfetti = false

        var body: some View {
            VStack {
                Button("Celebrate!") {
                    showConfetti = true
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .confetti(isActive: $showConfetti)
        }
    }

    return PreviewWrapper()
}

#Preview("Milestone 7 Days") {
    struct PreviewWrapper: View {
        @State private var showMilestone = true

        var body: some View {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
                .milestoneCelebration(isShowing: $showMilestone, milestone: 7)
        }
    }

    return PreviewWrapper()
}

#Preview("Milestone 30 Days") {
    struct PreviewWrapper: View {
        @State private var showMilestone = true

        var body: some View {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
                .milestoneCelebration(isShowing: $showMilestone, milestone: 30)
        }
    }

    return PreviewWrapper()
}

#Preview("Milestone 100 Days") {
    struct PreviewWrapper: View {
        @State private var showMilestone = true

        var body: some View {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
                .milestoneCelebration(isShowing: $showMilestone, milestone: 100)
        }
    }

    return PreviewWrapper()
}
