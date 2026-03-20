import SwiftUI

// MARK: - HistoryView

struct HistoryView: View {
    @EnvironmentObject var dataStore: DataStore

    private var groupedSessions: [(Date, [WorkoutSession])] {
        let dict = Dictionary(grouping: dataStore.sessions) { session in
            Calendar.current.startOfDay(for: session.startedAt)
        }
        return dict.sorted { $0.key > $1.key }
    }

    var body: some View {
        NavigationStack {
            Group {
                if dataStore.sessions.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("記録なし")
                            .font(.title2.bold())
                        Text("トレーニングを記録すると\nここに表示されます")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    List {
                        ForEach(groupedSessions, id: \.0) { date, sessions in
                            Section {
                                ForEach(sessions) { session in
                                    NavigationLink(destination: SessionDetailView(session: session)) {
                                        SessionRow(session: session)
                                    }
                                }
                                .onDelete { indexSet in
                                    indexSet.forEach { i in
                                        dataStore.deleteSession(id: sessions[i].id)
                                    }
                                }
                            } header: {
                                Text(date.formatted(.dateTime.year().month().day().weekday()))
                                    .font(.subheadline.bold())
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("履歴")
        }
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
            Image(systemName: icon)
                .font(.caption2)
            Text(value)
                .font(.caption.bold())
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .foregroundColor(.primary)
    }
}

// MARK: - Session Detail

struct SessionDetailView: View {
    @EnvironmentObject var dataStore: DataStore
    let session: WorkoutSession

    private var setsByExercise: [(Exercise, [WorkoutSet])] {
        let exerciseIds = session.sets.reduce(into: [UUID]()) { result, set in
            if !result.contains(set.exerciseId) { result.append(set.exerciseId) }
        }
        return exerciseIds.compactMap { id -> (Exercise, [WorkoutSet])? in
            guard let ex = dataStore.exercise(for: id) else { return nil }
            let sets = session.sets.filter { $0.exerciseId == id }
            return (ex, sets)
        }
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
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(width: 60, alignment: .leading)
                            Spacer()
                            if set.weight > 0 {
                                Text("\(formatWeight(set.weight)) kg")
                                    .font(.subheadline.bold())
                                Text("×")
                                    .foregroundColor(.secondary)
                            }
                            Text("\(set.reps) rep")
                                .font(.subheadline.bold())
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
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        return m < 60 ? "\(m)分" : String(format: "%d時間%02d分", m / 60, m % 60)
    }

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : String(format: "%.1f", w)
    }
}
