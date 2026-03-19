import SwiftUI

// MARK: - Model

struct DayRecord: Codable, Identifiable {
    var id = UUID()
    var text1: String
    var text2: String
    var text3: String
}

// MARK: - Store

class RecordStore: ObservableObject {
    @Published var allRecords: [String: [DayRecord]] = [:]
    private let storageKey = "dayRecords_v1"

    init() { load() }

    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    func key(for date: Date) -> String {
        Self.formatter.string(from: date)
    }

    func records(for date: Date) -> [DayRecord] {
        allRecords[key(for: date)] ?? []
    }

    func canAdd(for date: Date) -> Bool {
        records(for: date).count < 3
    }

    func hasRecords(for date: Date) -> Bool {
        !records(for: date).isEmpty
    }

    func add(_ record: DayRecord, for date: Date) {
        let k = key(for: date)
        var list = allRecords[k] ?? []
        guard list.count < 3 else { return }
        list.append(record)
        allRecords[k] = list
        persist()
    }

    func update(_ record: DayRecord, at index: Int, for date: Date) {
        let k = key(for: date)
        guard var list = allRecords[k], index < list.count else { return }
        list[index] = record
        allRecords[k] = list
        persist()
    }

    func delete(at index: Int, for date: Date) {
        let k = key(for: date)
        guard var list = allRecords[k] else { return }
        list.remove(at: index)
        allRecords[k] = list.isEmpty ? nil : list
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(allRecords) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([String: [DayRecord]].self, from: data)
        else { return }
        allRecords = decoded
    }
}

// MARK: - Root
// ※ Swift Playgrounds のデフォルト ContentView と衝突しないよう AppRootView を使用
//   エントリポイント（MyApp.swift 等）で AppRootView() を呼び出してください

struct AppRootView: View {
    @StateObject private var store = RecordStore()

    var body: some View {
        TabView {
            RecordTab(store: store)
                .tabItem { Label("記録", systemImage: "pencil.and.list.clipboard") }
            CalendarTab(store: store)
                .tabItem { Label("カレンダー", systemImage: "calendar") }
        }
    }
}

// MARK: - Record Tab

struct RecordTab: View {
    @ObservedObject var store: RecordStore
    @State private var showingAdd = false
    @State private var showingEdit = false
    @State private var editTarget: (DayRecord, Int)? = nil

    private let today = Date()

    var records: [DayRecord] { store.records(for: today) }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .long
        f.locale = Locale(identifier: "ja_JP")
        return f.string(from: today)
    }

    var body: some View {
        NavigationView {
            Group {
                if records.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                        Text("今日の記録はありません")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                            RecordRow(record: record, number: index + 1)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editTarget = (record, index)
                                    showingEdit = true
                                }
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { store.delete(at: $0, for: today) }
                        }
                    }
                }
            }
            .navigationTitle(formattedDate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Label("追加", systemImage: "plus")
                    }
                    .disabled(!store.canAdd(for: today))
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("\(records.count)/3 件")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
            }
            .sheet(isPresented: $showingAdd) {
                RecordFormView(title: "新しい記録", record: DayRecord(text1: "", text2: "", text3: "")) { r in
                    store.add(r, for: today)
                }
            }
            .sheet(isPresented: $showingEdit) {
                if let (record, index) = editTarget {
                    RecordFormView(title: "記録を編集", record: record) { r in
                        store.update(r, at: index, for: today)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Record Row

struct RecordRow: View {
    let record: DayRecord
    let number: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("記録 \(number)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue)
                    .cornerRadius(4)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            rowLine("1", record.text1)
            rowLine("2", record.text2)
            rowLine("3", record.text3)
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    func rowLine(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 14)
            Text(value.isEmpty ? "（未入力）" : value)
                .foregroundColor(value.isEmpty ? .secondary : .primary)
                .font(.body)
        }
    }
}

// MARK: - Record Form

struct RecordFormView: View {
    let title: String
    @State var record: DayRecord
    let onSave: (DayRecord) -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Int?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("テキスト 1")) {
                    TextField("入力してください", text: $record.text1)
                        .focused($focused, equals: 1)
                        .submitLabel(.next)
                        .onSubmit { focused = 2 }
                }
                Section(header: Text("テキスト 2")) {
                    TextField("入力してください", text: $record.text2)
                        .focused($focused, equals: 2)
                        .submitLabel(.next)
                        .onSubmit { focused = 3 }
                }
                Section(header: Text("テキスト 3")) {
                    TextField("入力してください", text: $record.text3)
                        .focused($focused, equals: 3)
                        .submitLabel(.done)
                        .onSubmit { focused = nil }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSave(record)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear { focused = 1 }
        }
    }
}

// MARK: - Calendar Tab

struct CalendarTab: View {
    @ObservedObject var store: RecordStore
    @State private var displayMonth = Date()
    @State private var selectedDate: Date? = nil

    private let cal = Calendar.current
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]

    var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy年 M月"
        f.locale = Locale(identifier: "ja_JP")
        return f.string(from: displayMonth)
    }

    var calendarDays: [Date?] {
        let comps = cal.dateComponents([.year, .month], from: displayMonth)
        guard let firstDay = cal.date(from: comps) else { return [] }
        let offset = cal.component(.weekday, from: firstDay) - 1
        let range = cal.range(of: .day, in: .month, for: firstDay)!
        var days: [Date?] = Array(repeating: nil, count: offset)
        for d in range {
            days.append(cal.date(byAdding: .day, value: d - 1, to: firstDay))
        }
        // Pad to complete weeks
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    func changeMonth(_ delta: Int) {
        displayMonth = cal.date(byAdding: .month, value: delta, to: displayMonth) ?? displayMonth
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Month navigation
                HStack {
                    Button { changeMonth(-1) } label: {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    Spacer()
                    Text(monthTitle)
                        .font(.title2.weight(.bold))
                    Spacer()
                    Button { changeMonth(1) } label: {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)

                // Weekday headers
                HStack(spacing: 0) {
                    ForEach(Array(weekdays.enumerated()), id: \.offset) { i, day in
                        Text(day)
                            .frame(maxWidth: .infinity)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(i == 0 ? .red : i == 6 ? .blue : .secondary)
                    }
                }
                .padding(.horizontal, 4)

                Divider()

                // Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                    ForEach(calendarDays.indices, id: \.self) { i in
                        if let date = calendarDays[i] {
                            let weekday = cal.component(.weekday, from: date)
                            DayCell(
                                date: date,
                                recordCount: store.records(for: date).count,
                                isToday: cal.isDateInToday(date),
                                isSelected: selectedDate.map { cal.isDate($0, inSameDayAs: date) } ?? false,
                                weekday: weekday
                            )
                            .onTapGesture { selectedDate = date }
                        } else {
                            Color.clear.frame(height: 52)
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.top, 4)

                Divider().padding(.top, 8)

                // Detail panel
                if let date = selectedDate {
                    DayDetailView(date: date, store: store)
                } else {
                    Spacer()
                    Text("日付をタップすると記録を確認できます")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                    Spacer()
                }
            }
            .navigationTitle("カレンダー")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let recordCount: Int
    let isToday: Bool
    let isSelected: Bool
    let weekday: Int

    var day: Int { Calendar.current.component(.day, from: date) }

    var textColor: Color {
        if isSelected { return .white }
        if weekday == 1 { return .red }
        if weekday == 7 { return .blue }
        return .primary
    }

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                if isSelected {
                    Circle().fill(Color.blue)
                } else if isToday {
                    Circle().stroke(Color.blue, lineWidth: 2)
                }
                Text("\(day)")
                    .font(.body)
                    .foregroundColor(textColor)
            }
            .frame(width: 36, height: 36)

            // Record dots (up to 3)
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i < recordCount
                              ? (isSelected ? Color.white : Color.blue)
                              : Color.clear)
                        .frame(width: 5, height: 5)
                }
            }
        }
        .frame(height: 52)
    }
}

// MARK: - Day Detail

struct DayDetailView: View {
    let date: Date
    @ObservedObject var store: RecordStore

    var records: [DayRecord] { store.records(for: date) }

    var dateTitle: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.locale = Locale(identifier: "ja_JP")
        return f.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(dateTitle)
                    .font(.headline)
                Spacer()
                Text("\(records.count)/3 件")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            if records.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.title)
                            .foregroundColor(.secondary)
                        Text("記録なし")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    Spacer()
                }
            } else {
                List {
                    ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                        RecordRow(record: record, number: index + 1)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}
