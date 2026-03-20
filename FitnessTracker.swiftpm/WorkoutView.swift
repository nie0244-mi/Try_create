import SwiftUI
import UIKit

// MARK: - WorkoutView

/// シート管理を1つの enum に集約（複数 .sheet による誤発火を防ぐ）
enum WorkoutSheet: Identifiable {
    case logSet(Exercise)
    case restTimer(Int)   // 休憩秒数

    var id: String {
        switch self {
        case .logSet(let e):   return "log-\(e.id)"
        case .restTimer(let s): return "rest-\(s)"
        }
    }
}

struct WorkoutView: View {
    @EnvironmentObject var dataStore: DataStore
    @AppStorage("defaultRestSeconds") private var defaultRestSeconds: Int = 90

    @State private var selectedMuscleGroup: MuscleGroup? = nil
    @State private var searchText = ""
    @State private var activeSheet: WorkoutSheet? = nil
    @State private var pendingTimerSeconds: Int? = nil
    @State private var showingEndConfirm = false

    var filteredExercises: [Exercise] {
        dataStore.exercises.filter { ex in
            let matchGroup = selectedMuscleGroup == nil || ex.muscleGroup == selectedMuscleGroup
            let matchSearch = searchText.isEmpty || ex.name.localizedCaseInsensitiveContains(searchText)
            return matchGroup && matchSearch
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // アクティブセッションバナー
                if let session = dataStore.currentSession, !session.sets.isEmpty {
                    ActiveSessionBanner(session: session)
                }

                // 部位フィルター
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "すべて", color: .orange, isSelected: selectedMuscleGroup == nil) {
                            selectedMuscleGroup = nil
                        }
                        ForEach(MuscleGroup.allCases, id: \.self) { group in
                            FilterChip(label: group.rawValue, color: group.color, isSelected: selectedMuscleGroup == group) {
                                selectedMuscleGroup = (selectedMuscleGroup == group) ? nil : group
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }

                // 種目リスト
                List {
                    ForEach(filteredExercises) { exercise in
                        ExerciseRow(exercise: exercise)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                activeSheet = .logSet(exercise)
                            }
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "種目を検索")
            }
            .navigationTitle("トレーニング")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if dataStore.currentSession != nil {
                        Button("セッション終了") {
                            showingEndConfirm = true
                        }
                        .foregroundColor(.red)
                        .font(.subheadline.bold())
                    }
                }
            }
            .confirmationDialog("セッションを終了しますか？", isPresented: $showingEndConfirm, titleVisibility: .visible) {
                Button("記録して終了", role: .none) { dataStore.endSession() }
                Button("破棄して終了", role: .destructive) { dataStore.discardSession() }
                Button("キャンセル", role: .cancel) {}
            }
            // ★ onDismiss パターンで LogSet → RestTimer の安全な連鎖
            .sheet(item: $activeSheet, onDismiss: {
                guard let seconds = pendingTimerSeconds else { return }
                pendingTimerSeconds = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    activeSheet = .restTimer(seconds)
                }
            }) { sheet in
                switch sheet {
                case .logSet(let exercise):
                    LogSetSheet(
                        exercise: exercise,
                        initialWeight: dataStore.lastWeight(for: exercise.id),
                        initialReps: dataStore.lastReps(for: exercise.id),
                        onLoggedWithTimer: {
                            // pendingTimerSeconds をセットしてから閉じる → onDismiss でタイマー起動
                            pendingTimerSeconds = defaultRestSeconds
                            activeSheet = nil
                        },
                        onLoggedOnly: {
                            // pendingTimerSeconds は nil のまま → タイマーは起動しない
                            activeSheet = nil
                        }
                    )
                case .restTimer(let seconds):
                    RestTimerSheet(totalSeconds: seconds)
                }
            }
        }
    }
}

// MARK: - Active Session Banner

struct ActiveSessionBanner: View {
    let session: WorkoutSession

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "figure.strengthtraining.traditional")
                .foregroundColor(.orange)
            VStack(alignment: .leading, spacing: 1) {
                Text("セッション進行中")
                    .font(.caption.bold())
                    .foregroundColor(.orange)
                Text("\(session.sets.count) セット記録済み")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(session.startedAt, style: .timer)
                .font(.subheadline.monospacedDigit().bold())
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.1))
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? color : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Exercise Row

struct ExerciseRow: View {
    @EnvironmentObject var dataStore: DataStore
    let exercise: Exercise

    var lastWeight: Double { dataStore.lastWeight(for: exercise.id) }
    var lastReps: Int   { dataStore.lastReps(for: exercise.id) }

    var body: some View {
        HStack(spacing: 14) {
            // 部位カラーバー
            RoundedRectangle(cornerRadius: 3)
                .fill(exercise.muscleGroup.color)
                .frame(width: 5, height: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text(exercise.name)
                    .font(.body.bold())
                previousLabel
            }

            Spacer()

            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundColor(exercise.muscleGroup.color)
        }
        .padding(.vertical, 5)
    }

    @ViewBuilder
    var previousLabel: some View {
        if lastWeight > 0 {
            Text("前回: \(formatWeight(lastWeight))kg × \(lastReps)rep")
                .font(.caption)
                .foregroundColor(.secondary)
        } else if lastReps != 10 || dataStore.sessions.contains(where: { $0.sets.contains(where: { $0.exerciseId == exercise.id }) }) {
            Text("前回: \(lastReps)rep")
                .font(.caption)
                .foregroundColor(.secondary)
        } else {
            Text(exercise.muscleGroup.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", w) : String(format: "%.1f", w)
    }
}

// MARK: - Log Set Sheet

struct LogSetSheet: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss

    let exercise: Exercise
    let initialWeight: Double
    let initialReps: Int
    let onLoggedWithTimer: () -> Void
    let onLoggedOnly: () -> Void

    @State private var weight: Double
    @State private var reps: Int

    init(exercise: Exercise, initialWeight: Double, initialReps: Int,
         onLoggedWithTimer: @escaping () -> Void,
         onLoggedOnly: @escaping () -> Void) {
        self.exercise = exercise
        self.initialWeight = initialWeight
        self.initialReps = initialReps
        self.onLoggedWithTimer = onLoggedWithTimer
        self.onLoggedOnly = onLoggedOnly
        _weight = State(initialValue: initialWeight)
        _reps = State(initialValue: max(1, initialReps))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // 種目ヘッダー
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(exercise.muscleGroup.color)
                            .frame(width: 6, height: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.name)
                                .font(.title2.bold())
                            Text(exercise.muscleGroup.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if exercise.isBodyweight {
                            Label("自重", systemImage: "figure.stand")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(.systemGray6))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal)

                    // 重量（自重以外）
                    if !exercise.isBodyweight {
                        WeightStepper(weight: $weight)
                    }

                    // レップ数
                    RepsStepper(reps: $reps)

                    // 記録ボタン（タイマーあり / なし）
                    VStack(spacing: 10) {
                        Button { logSet(startTimer: true) } label: {
                            Label("記録してタイマー開始", systemImage: "timer")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(exercise.muscleGroup.color)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Button { logSet(startTimer: false) } label: {
                            Text("記録のみ")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(Color(.systemGray6))
                                .foregroundColor(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
                .padding(.top, 16)
            }
            .navigationTitle("セット記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
    }

    private func logSet(startTimer: Bool) {
        let newSet = WorkoutSet(
            exerciseId: exercise.id,
            weight: exercise.isBodyweight ? 0 : weight,
            reps: reps
        )
        dataStore.addSet(newSet)

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // dismiss() を使わず親の state を直接変更してシート切替（誤発火防止）
        if startTimer {
            onLoggedWithTimer()
        } else {
            onLoggedOnly()   // activeSheet = nil → シートが閉じるだけ
        }
    }
}

// MARK: - Weight Stepper

struct WeightStepper: View {
    @Binding var weight: Double

    private let steps: [Double] = [0.5, 1.0, 2.5, 5.0]
    @State private var stepIndex = 2  // default: 2.5kg

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("重量 (kg)")
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .padding(.horizontal)

            HStack(spacing: 24) {
                Button {
                    weight = max(0, weight - steps[stepIndex])
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                }

                Text(formatWeight(weight))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .frame(minWidth: 130)
                    .multilineTextAlignment(.center)

                Button {
                    weight += steps[stepIndex]
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal)

            // ステップ選択
            HStack(spacing: 0) {
                ForEach(0..<steps.count, id: \.self) { i in
                    Button {
                        stepIndex = i
                    } label: {
                        Text(stepLabel(steps[i]))
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(stepIndex == i ? Color.orange : Color(.systemGray5))
                            .foregroundColor(stepIndex == i ? .white : .secondary)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)
        }
        .padding(.vertical, 14)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w)) kg" : String(format: "%.1f kg", w)
    }

    private func stepLabel(_ s: Double) -> String {
        s.truncatingRemainder(dividingBy: 1) == 0 ? "±\(Int(s))" : "±\(s)"
    }
}

// MARK: - Reps Stepper

struct RepsStepper: View {
    @Binding var reps: Int

    private let quickReps = [5, 8, 10, 12, 15, 20]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("レップ数")
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .padding(.horizontal)

            HStack(spacing: 24) {
                Button {
                    reps = max(1, reps - 1)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                }

                Text("\(reps) rep")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .frame(minWidth: 130)
                    .multilineTextAlignment(.center)

                Button {
                    reps += 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)

            // クイック選択
            HStack(spacing: 6) {
                ForEach(quickReps, id: \.self) { n in
                    Button("\(n)") {
                        reps = n
                    }
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(reps == n ? Color.blue : Color(.systemGray5))
                    .foregroundColor(reps == n ? .white : .secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 14)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }
}

// MARK: - Rest Timer Sheet

struct RestTimerSheet: View {
    @Environment(\.dismiss) var dismiss

    let totalSeconds: Int
    @State private var timeRemaining: Int
    @State private var isRunning = true
    @State private var timerTask: Timer?

    init(totalSeconds: Int) {
        self.totalSeconds = totalSeconds
        _timeRemaining = State(initialValue: totalSeconds)
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 1 }
        return Double(totalSeconds - timeRemaining) / Double(totalSeconds)
    }

    var body: some View {
        VStack(spacing: 28) {
            Text("休憩タイマー")
                .font(.title2.bold())
                .padding(.top, 8)

            // 円形プログレス
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 18)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color.green,
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                VStack(spacing: 4) {
                    Text(timeString(timeRemaining))
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("残り時間")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 240, height: 240)

            // 時間追加ボタン
            HStack(spacing: 12) {
                ForEach([15, 30, 60], id: \.self) { sec in
                    Button("+\(sec)秒") {
                        timeRemaining += sec
                    }
                    .font(.subheadline.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
                }
            }

            // スキップ
            Button {
                dismiss()
            } label: {
                Text("スキップ")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    private func startTimer() {
        timerTask = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard timeRemaining > 0 else {
                stopTimer()
                let gen = UINotificationFeedbackGenerator()
                gen.notificationOccurred(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { dismiss() }
                return
            }
            timeRemaining -= 1
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
