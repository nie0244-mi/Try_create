import SwiftUI

// MARK: - ContentView (Tab Root)
// @main と App エントリーポイントは Swift Playgrounds が自動生成したファイルに任せる

struct ContentView: View {
    @StateObject private var dataStore = DataStore()

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
        .environmentObject(dataStore)
    }
}
