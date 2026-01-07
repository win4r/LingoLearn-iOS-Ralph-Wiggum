//
//  PomodoroTimerCard.swift
//  LingoLearn
//
//  Pomodoro technique timer for focused study sessions
//

import SwiftUI

struct PomodoroTimerCard: View {
    @State private var showContent = false
    @State private var isRunning = false
    @State private var isBreak = false
    @State private var timeRemaining: Int = 25 * 60 // 25 minutes
    @State private var completedPomodoros = 0
    @State private var timer: Timer?
    @State private var showSettings = false
    @State private var studyDuration: Int = 25
    @State private var breakDuration: Int = 5

    private var progress: Double {
        let total = isBreak ? breakDuration * 60 : studyDuration * 60
        return Double(total - timeRemaining) / Double(total)
    }

    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.red.opacity(0.3), .clear],
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 16
                                )
                            )
                            .frame(width: 28, height: 28)

                        Image(systemName: "timer")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.red, .orange],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    Text("番茄钟")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                // Completed count
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { index in
                        Image(systemName: index < completedPomodoros ? "circle.fill" : "circle")
                            .font(.caption2)
                            .foregroundStyle(index < completedPomodoros ? .red : .gray.opacity(0.3))
                    }
                }

                // Settings button
                Button(action: {
                    HapticManager.shared.impact()
                    showSettings.toggle()
                }) {
                    Image(systemName: "gearshape")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(6)
                        .background(Circle().fill(Color(.secondarySystemGroupedBackground)))
                }
            }

            // Timer display
            VStack(spacing: 12) {
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 100, height: 100)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: isBreak ? [.green, .mint] : [.red, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: progress)

                    // Time display
                    VStack(spacing: 2) {
                        Text(timeString)
                            .font(.title2)
                            .fontWeight(.bold)
                            .monospacedDigit()

                        Text(isBreak ? "休息中" : "专注学习")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // Controls
                HStack(spacing: 20) {
                    // Reset button
                    Button(action: resetTimer) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color(.secondarySystemGroupedBackground)))
                    }

                    // Play/Pause button
                    Button(action: toggleTimer) {
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: isBreak ? [.green, .mint] : [.red, .orange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .shadow(color: (isBreak ? Color.green : Color.red).opacity(0.3), radius: 8, y: 4)
                    }

                    // Skip button
                    Button(action: skipPhase) {
                        Image(systemName: "forward.end.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color(.secondarySystemGroupedBackground)))
                    }
                }
            }
            .padding(.vertical, 8)

            // Settings panel
            if showSettings {
                VStack(spacing: 12) {
                    Divider()

                    HStack {
                        Text("专注时间")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Picker("", selection: $studyDuration) {
                            Text("15分钟").tag(15)
                            Text("25分钟").tag(25)
                            Text("45分钟").tag(45)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                        .onChange(of: studyDuration) { _, _ in
                            if !isRunning && !isBreak {
                                timeRemaining = studyDuration * 60
                            }
                        }
                    }

                    HStack {
                        Text("休息时间")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Picker("", selection: $breakDuration) {
                            Text("5分钟").tag(5)
                            Text("10分钟").tag(10)
                            Text("15分钟").tag(15)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
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
                        colors: isRunning ? (isBreak ? [.green.opacity(0.3), .mint.opacity(0.2)] : [.red.opacity(0.3), .orange.opacity(0.2)]) : [.gray.opacity(0.15), .gray.opacity(0.1)],
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
            withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
                showContent = true
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showSettings)
    }

    private func toggleTimer() {
        HapticManager.shared.impact()

        if isRunning {
            // Pause
            timer?.invalidate()
            timer = nil
        } else {
            // Start
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    completePhase()
                }
            }
        }
        isRunning.toggle()
    }

    private func resetTimer() {
        HapticManager.shared.impact()
        timer?.invalidate()
        timer = nil
        isRunning = false
        isBreak = false
        timeRemaining = studyDuration * 60
    }

    private func skipPhase() {
        HapticManager.shared.impact()
        completePhase()
    }

    private func completePhase() {
        timer?.invalidate()
        timer = nil
        isRunning = false

        if isBreak {
            // Break completed, start new study session
            isBreak = false
            timeRemaining = studyDuration * 60
        } else {
            // Study session completed
            completedPomodoros += 1
            HapticManager.shared.success()
            SoundService.shared.playComplete()

            // Start break
            isBreak = true
            timeRemaining = breakDuration * 60

            // Auto-start break after a moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if !isRunning {
                    toggleTimer()
                }
            }
        }
    }
}

#Preview {
    PomodoroTimerCard()
        .padding()
        .background(Color(.systemGroupedBackground))
}
