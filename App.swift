import SwiftUI

@main
struct DailyGratitudeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(GratitudeStore())
        }
    }
}
