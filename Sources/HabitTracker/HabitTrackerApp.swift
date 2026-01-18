import SwiftUI

@main
struct HabitTrackerApp: App {
    @StateObject private var store = HabitStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
        .windowStyle(.automatic)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Habit") {
                    NotificationCenter.default.post(name: .createNewHabit, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandMenu("Habit") {
                Button("View Analytics") {
                    NotificationCenter.default.post(name: .showAnalytics, object: nil)
                }
                .keyboardShortcut("a", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Reset All Data...") {
                    store.resetAllData()
                }
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let createNewHabit = Notification.Name("createNewHabit")
    static let showAnalytics = Notification.Name("showAnalytics")
}
