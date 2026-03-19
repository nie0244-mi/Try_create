import SwiftUI

// MARK: - Data Model

struct GratitudeEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    var items: [String]

    init(id: UUID = UUID(), date: Date = Date(), items: [String] = ["", "", ""]) {
        self.id = id
        self.date = date
        self.items = items
    }

    var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    var isComplete: Bool {
        items.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count == 3
    }
}

// MARK: - Store

class GratitudeStore: ObservableObject {
    @Published var entries: [GratitudeEntry] = []

    private let saveKey = "gratitude_entries"

    init() {
        load()
    }

    var todayEntry: GratitudeEntry? {
        entries.first { Calendar.current.isDateInToday($0.date) }
    }

    func saveTodayEntry(_ entry: GratitudeEntry) {
        if let index = entries.firstIndex(where: { Calendar.current.isDateInToday($0.date) }) {
            entries[index] = entry
        } else {
            entries.insert(entry, at: 0)
        }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([GratitudeEntry].self, from: data) else { return }
        entries = decoded.sorted { $0.date > $1.date }
    }
}

// MARK: - Main App

@main
struct DailyGratitudeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(GratitudeStore())
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject var store: GratitudeStore
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("今日", systemImage: "sun.max.fill")
                }
                .tag(0)

            HistoryView()
                .tabItem {
                    Label("記録", systemImage: "calendar")
                }
                .tag(1)
        }
        .accentColor(.orange)
    }
}

// MARK: - Today View

struct TodayView: View {
    @EnvironmentObject var store: GratitudeStore
    @State private var items: [String] = ["", "", ""]
    @State private var showSaved = false
    @FocusState private var focusedField: Int?

    var today: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E)"
        return formatter.string(from: Date())
    }

    var isSavable: Bool {
        items.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count == 3
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Text("✨ 今日の良かったこと")
                            .font(.title)
                            .fontWeight(.bold)
                        Text(today)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Input Cards
                    VStack(spacing: 16) {
                        ForEach(0..<3) { index in
                            GratitudeInputCard(
                                number: index + 1,
                                text: $items[index],
                                isFocused: focusedField == index,
                                onSubmit: {
                                    if index < 2 {
                                        focusedField = index + 1
                                    } else {
                                        focusedField = nil
                                    }
                                }
                            )
                            .focused($focusedField, equals: index)
                        }
                    }
                    .padding(.horizontal)

                    // Save Button
                    Button {
                        saveEntry()
                    } label: {
                        HStack {
                            if showSaved {
                                Image(systemName: "checkmark.circle.fill")
                                Text("保存しました！")
                            } else {
                                Image(systemName: "square.and.arrow.down.fill")
                                Text("保存する")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isSavable ? Color.orange : Color.gray.opacity(0.4))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    .disabled(!isSavable || showSaved)
                    .animation(.easeInOut, value: showSaved)

                    if !isSavable {
                        Text("3つすべて入力すると保存できます")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer(minLength: 40)
                }
            }
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground))
        }
        .navigationViewStyle(.stack)
        .onAppear {
            if let entry = store.todayEntry {
                items = entry.items
            }
        }
    }

    private func saveEntry() {
        let entry = GratitudeEntry(items: items)
        store.saveTodayEntry(entry)
        focusedField = nil
        withAnimation {
            showSaved = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSaved = false
            }
        }
    }
}

// MARK: - Gratitude Input Card

struct GratitudeInputCard: View {
    let number: Int
    @Binding var text: String
    var isFocused: Bool
    var onSubmit: () -> Void

    var numberEmoji: String {
        ["1️⃣", "2️⃣", "3️⃣"][number - 1]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(numberEmoji)
                    .font(.title2)
                Text("良かったこと \(number)")
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            TextField("今日の良かったことを入力...", text: $text, axis: .vertical)
                .lineLimit(3...6)
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? Color.orange : Color.clear, lineWidth: 2)
                )
                .submitLabel(number < 3 ? .next : .done)
                .onSubmit(onSubmit)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - History View

struct HistoryView: View {
    @EnvironmentObject var store: GratitudeStore

    var body: some View {
        NavigationView {
            Group {
                if store.entries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "note.text")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("まだ記録がありません")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("今日の良かったことを記録してみましょう")
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(store.entries) { entry in
                            EntryRow(entry: entry)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("これまでの記録")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Entry Row

struct EntryRow: View {
    let entry: GratitudeEntry
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.dateString)
                            .font(.headline)
                            .foregroundColor(.primary)
                        if entry.isComplete {
                            Label("3つ完了", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Label("\(entry.items.filter { !$0.isEmpty }.count)/3 記録", systemImage: "pencil.circle")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            // Expanded Content
            if isExpanded {
                Divider()
                    .padding(.vertical, 8)
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(entry.items.enumerated()), id: \.offset) { index, item in
                        if !item.trimmingCharacters(in: .whitespaces).isEmpty {
                            HStack(alignment: .top, spacing: 10) {
                                Text(["1️⃣", "2️⃣", "3️⃣"][index])
                                    .font(.subheadline)
                                Text(item)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(.bottom, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
