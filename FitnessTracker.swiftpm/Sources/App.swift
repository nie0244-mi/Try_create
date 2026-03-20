import SwiftUI

@main
struct FitnessTrackerApp: App {
    @StateObject private var dataStore = DataStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
        }
    }
}

// MARK: - ContentView (Tab Root)

struct ContentView: View {
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        TabView {
            WorkoutView()
                .tabItem {
                    Label("トレーニング", systemImage: "dumbbell.fill")
                }

            HistoryView()
                .tabItem {
                    Label("履歴", systemImage: "calendar")
                }

            TimerView()
                .tabItem {
                    Label("タイマー", systemImage: "timer")
                }

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
        }
        .tint(.orange)
    }
}
