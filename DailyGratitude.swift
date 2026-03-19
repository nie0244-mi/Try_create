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
              let decoded = try? JSONDecoder().decode([GratitudeEntry].self, from: data)
        else { return }
        entries = decoded.sorted { $0.date > $1.date }
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
    }
}

// MARK: - Today View

struct TodayView: View {
    @EnvironmentObject var store: GratitudeStore
    @State private var item1 = ""
    @State private var item2 = ""
    @State private var item3 = ""
    @State private var showSaved = false

    var today: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E)"
        return formatter.string(from: Date())
    }

    var isSavable: Bool {
        !item1.trimmingCharacters(in: .whitespaces).isEmpty &&
        !item2.trimmingCharacters(in: .whitespaces).isEmpty &&
        !item3.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Text("今日の良かったこと")
                            .font(.title)
                            .fontWeight(.bold)
                        Text(today)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 16) {
                        GratitudeInputCard(number: 1, text: $item1)
                        GratitudeInputCard(number: 2, text: $item2)
                        GratitudeInputCard(number: 3, text: $item3)
                    }
                    .padding(.horizontal)

                    Button(action: saveEntry) {
                        HStack {
                            Image(systemName: showSaved ? "checkmark.circle.fill" : "square.and.arrow.down.fill")
                            Text(showSaved ? "保存しました！" : "保存する")
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

                    if !isSavable {
                        Text("3つすべて入力すると保存できます")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer(minLength: 40)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            if let entry = store.todayEntry {
                item1 = entry.items.count > 0 ? entry.items[0] : ""
                item2 = entry.items.count > 1 ? entry.items[1] : ""
                item3 = entry.items.count > 2 ? entry.items[2] : ""
            }
        }
    }

    private func saveEntry() {
        let entry = GratitudeEntry(items: [item1, item2, item3])
        store.saveTodayEntry(entry)
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

    private let emojis = ["1️⃣", "2️⃣", "3️⃣"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(emojis[number - 1])
                    .font(.title2)
                Text("良かったこと \(number)")
                    .font(.headline)
            }

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("今日の良かったことを入力...")
                        .foregroundColor(Color(.placeholderText))
                        .padding(8)
                }
                TextEditor(text: $text)
                    .frame(minHeight: 80)
                    .opacity(text.isEmpty ? 0.99 : 1)
            }
            .padding(4)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
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
                            .foregroundColor(.secondary)
                            .opacity(0.5)
                        Text("まだ記録がありません")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("今日の良かったことを記録してみましょう")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(store.entries) { entry in
                            EntryRow(entry: entry)
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("これまでの記録")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Entry Row

struct EntryRow: View {
    let entry: GratitudeEntry
    @State private var isExpanded = false

    private let emojis = ["1️⃣", "2️⃣", "3️⃣"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.dateString)
                            .font(.headline)
                            .foregroundColor(.primary)
                        HStack(spacing: 4) {
                            Image(systemName: entry.isComplete ? "checkmark.circle.fill" : "pencil.circle")
                                .foregroundColor(entry.isComplete ? .green : .orange)
                            Text(entry.isComplete ? "3つ完了" : "\(entry.items.filter { !$0.isEmpty }.count)/3 記録")
                                .font(.caption)
                                .foregroundColor(entry.isComplete ? .green : .orange)
                        }
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                Divider()
                    .padding(.vertical, 8)
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(0..<entry.items.count, id: \.self) { index in
                        let item = entry.items[index]
                        if !item.trimmingCharacters(in: .whitespaces).isEmpty {
                            HStack(alignment: .top, spacing: 10) {
                                Text(emojis[index])
                                    .font(.subheadline)
                                Text(item)
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(.bottom, 4)
            }
        }
    }
}
