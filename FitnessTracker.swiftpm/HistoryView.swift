import SwiftUI

// MARK: - HistoryView

struct HistoryView: View {
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        NavigationStack {
            WorkoutCalendarView()
                .navigationTitle("履歴")
        }
    }
}

// MARK: - Workout Calendar View

struct WorkoutCalendarView: View {
    @EnvironmentObject var dataStore: DataStore

    @State private var currentMonth: Date = {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.year, .month], from: Date()))!
    }()
    @State private var selectedDate: Date? = nil

    private let cal = Calendar.current
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    // 当月にトレーニングがある日のセット (yyyy-M-d 形式)
    private var workoutDayKeys: Set<String> {
        Set(dataStore.sessions.map { dayKey($0.startedAt) })
    }

    // 選択日のセッション
    private var selectedSessions: [WorkoutSession] {
        guard let date = selectedDate else { return [] }
        let key = dayKey(date)
        return dataStore.sessions
            .filter { dayKey($0.startedAt) == key }
            .sorted { $0.startedAt < $1.startedAt }
    }

    // カレンダーグリッド用（先頭の空白 nil 込み）
    private var gridDays: [Date?] {
        guard let range = cal.range(of: .day, in: .month, for: currentMonth) else { return [] }
        let firstWeekday = cal.component(.weekday, from: currentMonth) - 1 // 0=日
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range {
            var comps = cal.dateComponents([.year, .month], from: currentMonth)
            comps.day = day
            days.append(cal.date(from: comps))
        }
        return days
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // 月ナビゲーション
                HStack {
                    Button { shiftMonth(-1) } label: {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.title2).foregroundColor(.orange)
                    }
                    Spacer()
                    Text(currentMonth.formatted(.dateTime.year().month()))
                        .font(.title2.bold())
                    Spacer()
                    Button { shiftMonth(1) } label: {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title2).foregroundColor(.orange)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)

                // 曜日ヘッダー
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(weekdays, id: \.self) { w in
                        Text(w)
                            .font(.caption.bold())
                            .foregroundColor(w == "日" ? .red : w == "土" ? .blue : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 4)
                    }

                    // 日付セル
                    ForEach(0..<gridDays.count, id: \.self) { i in
                        if let date = gridDays[i] {
                            DayCell(
                                day: cal.component(.day, from: date),
                                weekdayIndex: (i) % 7,
                                hasWorkout: workoutDayKeys.contains(dayKey(date)),
                                isToday: dayKey(date) == dayKey(Date()),
                                isSelected: selectedDate.map { dayKey($0) == dayKey(date) } ?? false
                            ) {
                                selectedDate = (selectedDate.map { dayKey($0) == dayKey(date) } ?? false)
                                    ? nil : date
                            }
                        } else {
                            Color.clear.frame(height: 52)
                        }
                    }
                }
                .padding(.horizontal, 8)

                Divider().padding(.top, 12)

                // 選択日のセッション or 空状態
                if let date = selectedDate {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(date.formatted(.dateTime.month().day().weekday()))
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.vertical, 10)

                        if selectedSessions.isEmpty {
                            ContentUnavailableView(
                                "記録なし",
                                systemImage: "figure.run",
                                description: Text("この日のトレーニングはありません")
                            )
                            .padding(.top, 20)
                        } else {
                            ForEach(selectedSessions) { session in
                                NavigationLink(destination: SessionDetailView(session: session)) {
                                    SessionRow(session: session)
                                        .padding(.horizontal)
                                        .padding(.vertical, 6)
                                }
                                .buttonStyle(.plain)
                                Divider().padding(.leading)
                            }
                        }
                    }
                } else if dataStore.sessions.isEmpty {
                    ContentUnavailableView(
                        "記録なし",
                        systemImage: "calendar.badge.plus",
                        description: Text("トレーニングを記録すると\nここに表示されます")
                    )
                    .padding(.top, 20)
                } else {
                    // 最近のセッションを表示
                    VStack(alignment: .leading, spacing: 0) {
                        Text("最近のトレーニング")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.vertical, 10)

                        ForEach(dataStore.sessions.prefix(5)) { session in
                            NavigationLink(destination: SessionDetailView(session: session)) {
                                SessionRow(session: session)
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.leading)
                        }
                    }
                }
            }
        }
    }

    private func dayKey(_ date: Date) -> String {
        let c = cal.dateComponents([.year, .month, .day], from: date)
        return "\(c.year!)-\(c.month!)-\(c.day!)"
    }

    private func shiftMonth(_ delta: Int) {
        if let d = cal.date(byAdding: .month, value: delta, to: currentMonth) {
            currentMonth = d
            selectedDate = nil
        }
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let day: Int
    let weekdayIndex: Int  // 0=日, 6=土
    let hasWorkout: Bool
    let isToday: Bool
    let isSelected: Bool
    let action: () -> Void

    private var dayColor: Color {
        if isSelected { return .white }
        if weekdayIndex == 0 { return .red }
        if weekdayIndex == 6 { return .blue }
        return .primary
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text("\(day)")
                    .font(.system(size: 16, weight: isToday ? .bold : .regular))
                    .foregroundColor(dayColor)
                    .frame(width: 36, height: 36)
                    .background(
                        isSelected ? Color.orange :
                        isToday    ? Color.orange.opacity(0.15) :
                        Color.clear
                    )
                    .clipShape(Circle())

                // トレーニングあり ドット
                Circle()
                    .fill(hasWorkout
                          ? (isSelected ? Color.white : Color.orange)
                          : Color.clear)
                    .frame(width: 5, height: 5)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Session Row

struct SessionRow: View {
    @EnvironmentObject var dataStore: DataStore
    let session: WorkoutSession

    var exerciseNames: String {
        let ids = Array(Set(session.sets.map { $0.exerciseId }))
        let names = ids.prefix(3).compactMap { dataStore.exercise(for: $0)?.name }
        let suffix = ids.count > 3 ? " 他\(ids.count - 3)種目" : ""
        return names.joined(separator: " · ") + suffix
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.startedAt, style: .time)
                    .font(.subheadline.bold())
                Spacer()
                if let dur = session.duration {
                    Label(formatDuration(dur), systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(exerciseNames.isEmpty ? "種目なし" : exerciseNames)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)

            HStack(spacing: 16) {
                StatBadge(icon: "list.bullet", value: "\(session.sets.count)", label: "セット")
                if session.totalVolume > 0 {
                    StatBadge(icon: "scalemass", value: formatVolume(session.totalVolume), label: "総ボリューム")
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        return m < 60 ? "\(m)分" : String(format: "%d時間%02d分", m / 60, m % 60)
    }

    private func formatVolume(_ v: Double) -> String {
        v >= 1000 ? String(format: "%.1f t", v / 1000) : "\(Int(v)) kg"
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2)
            Text(value).font(.caption.bold())
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .foregroundColor(.primary)
    }
}

// MARK: - Session Detail

struct SessionDetailView: View {
    @EnvironmentObject var dataStore: DataStore
    let session: WorkoutSession

    private var setsByExercise: [(Exercise, [WorkoutSet])] {
        let ids = session.sets.reduce(into: [UUID]()) { r, s in
            if !r.contains(s.exerciseId) { r.append(s.exerciseId) }
        }
        return ids.compactMap { id -> (Exercise, [WorkoutSet])? in
            guard let ex = dataStore.exercise(for: id) else { return nil }
            return (ex, session.sets.filter { $0.exerciseId == id })
        }
    }

    /// SNS 共有用テキストを生成
    private var shareText: String {
        var lines: [String] = []
        lines.append("💪 \(session.startedAt.formatted(.dateTime.year().month().day()))")
        if let dur = session.duration {
            lines.append("⏱ \(formatDuration(dur))")
        }
        lines.append("")
        for (exercise, sets) in setsByExercise {
            lines.append("▸ \(exercise.name)")
            for (i, set) in sets.enumerated() {
                if set.weight > 0 {
                    lines.append("  セット\(i+1): \(formatWeight(set.weight))kg × \(set.reps)rep")
                } else {
                    lines.append("  セット\(i+1): \(set.reps)rep")
                }
            }
        }
        if session.totalVolume > 0 {
            lines.append("")
            lines.append("総ボリューム: \(Int(session.totalVolume))kg")
        }
        lines.append("")
        lines.append("#筋トレ #トレーニング記録")
        return lines.joined(separator: "\n")
    }

    var body: some View {
        List {
            Section("サマリー") {
                LabeledContent("開始時刻", value: session.startedAt.formatted(.dateTime.hour().minute()))
                if let dur = session.duration {
                    LabeledContent("トレーニング時間", value: formatDuration(dur))
                }
                LabeledContent("総セット数", value: "\(session.sets.count)")
                if session.totalVolume > 0 {
                    LabeledContent("総ボリューム", value: "\(Int(session.totalVolume)) kg")
                }
            }

            ForEach(setsByExercise, id: \.0.id) { exercise, sets in
                Section {
                    ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                        HStack {
                            Text("セット \(index + 1)")
                                .font(.subheadline).foregroundColor(.secondary)
                                .frame(width: 60, alignment: .leading)
                            Spacer()
                            if set.weight > 0 {
                                Text("\(formatWeight(set.weight)) kg").font(.subheadline.bold())
                                Text("×").foregroundColor(.secondary)
                            }
                            Text("\(set.reps) rep").font(.subheadline.bold())
                        }
                    }
                } header: {
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(exercise.muscleGroup.color)
                            .frame(width: 4, height: 16)
                        Text(exercise.name)
                    }
                }
            }
        }
        .navigationTitle(session.startedAt.formatted(.dateTime.month().day()))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        return m < 60 ? "\(m)分" : String(format: "%d時間%02d分", m / 60, m % 60)
    }

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : String(format: "%.1f", w)
    }
}
