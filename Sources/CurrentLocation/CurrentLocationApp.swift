import SwiftUI

@main
struct CurrentLocationApp: App {
    @StateObject private var tracker = LocationTracker()

    var body: some Scene {
        WindowGroup {
            ContentView(tracker: tracker)
        }
    }
}
