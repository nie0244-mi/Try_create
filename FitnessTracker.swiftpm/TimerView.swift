import SwiftUI
import UIKit
import AudioToolbox

// MARK: - TimerView

struct TimerView: View {
    @State private var mode: TimerMode = .hiit

    enum TimerMode { case hiit, rest }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("モード", selection: $mode) {
                    Text("HIIT").tag(TimerMode.hiit)
                    Text("休憩タイマー").tag(TimerMode.rest)
                }
                .pickerStyle(.segmented)
                .padding()

                if mode == .hiit {
                    HIITTimerView()
                } else {
                    SimpleRestTimerView()
                }
            }
            .navigationTitle("タイマー")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - HIIT Timer

struct HIITTimerView: View {

    @AppStorage("hiitSoundEnabled") private var soundEnabled: Bool = true

    // Config
    @State private var workSeconds: Int = 40
    @State private var restSeconds: Int = 20
    @State private var totalRounds: Int = 8
    @State private var showingConfig = false

    // Runtime state
    @State private var phase: TimerPhase = .idle
    @State private var currentRound: Int = 0
    @State private var timeRemaining: Int = 0
    @State private var timerTask: Timer?

    var currentTotal: Int { phase == .work ? workSeconds : restSeconds }

    var progress: Double {
        guard currentTotal > 0 else { return 0 }
        return Double(currentTotal - timeRemaining) / Double(currentTotal)
    }

    var phaseColor: Color {
        switch phase {
        case .work:     return .orange
        case .rest:     return .green
        case .idle:     return Color(.systemGray3)
        case .finished: return .blue
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {

                // ラウンド表示
                if phase != .idle {
                    HStack(spacing: 4) {
                        ForEach(1...totalRounds, id: \.self) { r in
                            Capsule()
                                .fill(r < currentRound ? Color(.systemGray3) :
                                      r == currentRound ? phaseColor : Color(.systemGray6))
                                .frame(height: 8)
                        }
                    }
                    .padding(.horizontal)
                    .animation(.spring(), value: currentRound)
                }

                // メインサークル
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 20)
                    Circle()
                        .trim(from: 0, to: phase == .idle || phase == .finished ? 0 : progress)
                        .stroke(phaseColor,
                                style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: progress)

                    VStack(spacing: 6) {
                        if phase == .finished {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            Text("完了!")
                                .font(.title.bold())
                        } else if phase == .idle {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.orange)
                            Text("開始準備完了")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text(timeString(timeRemaining))
                                .font(.system(size: 72, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(phaseColor)
                            Text(phase == .work ? "ワーク" : "レスト")
                                .font(.title2.bold())
                                .foregroundColor(phaseColor)
                            Text("\(currentRound) / \(totalRounds) ラウンド")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(width: 280, height: 280)

                // コントロールボタン
                HStack(spacing: 20) {
                    if phase != .idle {
                        Button {
                            stopTimer()
                            phase = .idle
                        } label: {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: 52))
                                .foregroundColor(.red)
                        }
                    }

                    Button {
                        if phase == .idle || phase == .finished {
                            startHIIT()
                        } else {
                            skipPhase()
                        }
                    } label: {
                        Image(systemName: phase == .idle || phase == .finished
                              ? "play.circle.fill"
                              : "forward.end.circle.fill")
                            .font(.system(size: 72))
                            .foregroundColor(phaseColor)
                    }
                }

                // 設定パネル
                VStack(spacing: 0) {
                    Button {
                        showingConfig.toggle()
                    } label: {
                        HStack {
                            Label("設定", systemImage: "slider.horizontal.3")
                            Spacer()
                            Text("\(workSeconds)s / \(restSeconds)s × \(totalRounds)ラウンド")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Image(systemName: showingConfig ? "chevron.up" : "chevron.down")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal)

                    if showingConfig {
                        HIITConfigPanel(
                            workSeconds: $workSeconds,
                            restSeconds: $restSeconds,
                            totalRounds: $totalRounds
                        )
                    }
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: Timer Logic

    private func startHIIT() {
        currentRound = 1
        phase = .work
        timeRemaining = workSeconds
        startTicking()
    }

    private func skipPhase() {
        advancePhase()
    }

    private func startTicking() {
        stopTimer()
        timerTask = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
                // 5秒前カウントダウン音
                if soundEnabled && timeRemaining <= 5 && timeRemaining > 0 {
                    AudioServicesPlaySystemSound(1057) // tock
                }
            } else {
                advancePhase()
            }
        }
    }

    private func advancePhase() {
        let gen = UINotificationFeedbackGenerator()

        if phase == .work {
            if currentRound >= totalRounds {
                // 最終ラウンドのワーク → 終了
                stopTimer()
                phase = .finished
                gen.notificationOccurred(.success)
                if soundEnabled { AudioServicesPlaySystemSound(1025) } // 完了音
            } else {
                // レストへ
                phase = .rest
                timeRemaining = restSeconds
                gen.notificationOccurred(.warning)
                if soundEnabled { AudioServicesPlaySystemSound(1054) } // フェーズ切替音
                startTicking()
            }
        } else if phase == .rest {
            // 次のラウンドのワークへ
            currentRound += 1
            phase = .work
            timeRemaining = workSeconds
            gen.notificationOccurred(.warning)
            if soundEnabled { AudioServicesPlaySystemSound(1054) } // フェーズ切替音
            startTicking()
        }
    }

    private func stopTimer() {
        timerTask?.invalidate()
        timerTask = nil
    }

    private func timeString(_ s: Int) -> String {
        String(format: "%d:%02d", s / 60, s % 60)
    }
}

// MARK: - HIIT Config Panel

struct HIITConfigPanel: View {
    @Binding var workSeconds: Int
    @Binding var restSeconds: Int
    @Binding var totalRounds: Int

    let presets: [(String, HIITConfig)] = [
        ("Tabata", .tabata),
        ("スタンダード", .standard),
        ("持久力", .endurance),
    ]

    var body: some View {
        VStack(spacing: 16) {

            // プリセット
            HStack(spacing: 8) {
                ForEach(presets, id: \.0) { name, config in
                    Button(name) {
                        workSeconds  = config.workSeconds
                        restSeconds  = config.restSeconds
                        totalRounds  = config.rounds
                    }
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            // ワーク時間
            TimerSliderRow(label: "ワーク時間", value: $workSeconds, range: 10...120, step: 5, color: .orange)

            // レスト時間
            TimerSliderRow(label: "レスト時間", value: $restSeconds, range: 5...120, step: 5, color: .green)

            // ラウンド数
            TimerSliderRow(label: "ラウンド数", value: $totalRounds, range: 1...20, step: 1, color: .blue, unit: "回")
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

struct TimerSliderRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Double>
    let step: Double
    let color: Color
    var unit: String = "秒"

    init(label: String, value: Binding<Int>, range: ClosedRange<Int>, step: Int, color: Color, unit: String = "秒") {
        self.label = label
        self._value = value
        self.range = Double(range.lowerBound)...Double(range.upperBound)
        self.step = Double(step)
        self.color = color
        self.unit = unit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text("\(value)\(unit)")
                    .font(.subheadline.bold())
                    .foregroundColor(color)
            }
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0) }
                ),
                in: range,
                step: step
            )
            .tint(color)
        }
    }
}

// MARK: - Simple Rest Timer

struct SimpleRestTimerView: View {
    @State private var minutes: Int = 1
    @State private var seconds: Int = 30
    @State private var timeRemaining: Int = 0
    @State private var isRunning = false
    @State private var timerTask: Timer?

    var totalConfiguredSeconds: Int { minutes * 60 + seconds }

    var progress: Double {
        guard totalConfiguredSeconds > 0 else { return 0 }
        return 1.0 - Double(timeRemaining) / Double(totalConfiguredSeconds)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {

                // 円形プログレス
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 18)
                    if isRunning || timeRemaining > 0 {
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.green,
                                    style: StrokeStyle(lineWidth: 18, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: progress)
                    }

                    VStack(spacing: 6) {
                        Text(timeString(isRunning || timeRemaining > 0 ? timeRemaining : totalConfiguredSeconds))
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(isRunning ? .green : .primary)
                        if !isRunning {
                            Text("タップして開始")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(width: 260, height: 260)
                .onTapGesture {
                    if isRunning {
                        pauseTimer()
                    } else {
                        startTimer()
                    }
                }

                // 時間設定（停止時のみ）
                if !isRunning {
                    VStack(spacing: 16) {
                        HStack(spacing: 0) {
                            TimePicker(label: "分", value: $minutes, range: 0...59)
                            Text(":")
                                .font(.title.bold())
                            TimePicker(label: "秒", value: $seconds, range: 0...59)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)
                }

                // ボタン
                HStack(spacing: 16) {
                    if isRunning || timeRemaining > 0 {
                        Button {
                            stopTimer()
                        } label: {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.red)
                        }
                    }

                    Button {
                        isRunning ? pauseTimer() : startTimer()
                    } label: {
                        Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.green)
                    }
                }

                // クイック追加（実行中のみ）
                if isRunning {
                    HStack(spacing: 12) {
                        ForEach([15, 30, 60], id: \.self) { s in
                            Button("+\(s)秒") {
                                timeRemaining += s
                            }
                            .font(.subheadline.bold())
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .clipShape(Capsule())
                        }
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
    }

    private func startTimer() {
        if timeRemaining == 0 {
            timeRemaining = totalConfiguredSeconds
        }
        isRunning = true
        timerTask = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard timeRemaining > 0 else {
                stopTimer()
                let gen = UINotificationFeedbackGenerator()
                gen.notificationOccurred(.success)
                return
            }
            timeRemaining -= 1
        }
    }

    private func pauseTimer() {
        isRunning = false
        timerTask?.invalidate()
        timerTask = nil
    }

    private func stopTimer() {
        isRunning = false
        timerTask?.invalidate()
        timerTask = nil
        timeRemaining = 0
    }

    private func timeString(_ s: Int) -> String {
        String(format: "%d:%02d", s / 60, s % 60)
    }
}

// MARK: - Time Picker Component

struct TimePicker: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        VStack(spacing: 2) {
            Picker(label, selection: $value) {
                ForEach(range, id: \.self) { n in
                    Text(String(format: "%02d", n)).tag(n)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 80, height: 100)
            .clipped()
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
