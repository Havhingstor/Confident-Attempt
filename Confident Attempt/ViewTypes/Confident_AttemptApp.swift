import Confident_Attempt_Model
import SwiftData
import SwiftUI
import TipKit

@main
struct Confident_AttemptApp: App {
    @State private var preferences: Preferences
    let container: ModelContainer

    init() {
        let prefs = Preferences()
        _preferences = State(initialValue: prefs)
        do {
            container = try ModelContainer(for: Habit.self, migrationPlan: HabitsMigrationPlan.self)
            container.mainContext.undoManager = UndoManager()
        } catch {
            fatalError("Failed to initialize model container: \(error)")
        }
        
        if prefs.retrieveShouldReloadTips() {
            try? Tips.resetDatastore()
        }
        
        try? Tips.configure([
            .cloudKitContainer(.automatic)
        ])
    }

    var body: some Scene {
        WindowGroup {
            ContentView(preferences)
        }
        .modelContainer(container)
    }
}

func getPreviewContainer() -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, configurations: config)
    container.mainContext.undoManager = UndoManager()

    let habit1 = Habit(name: "Test 1", textDescription: "Test", firstDay: .now)
    let habit2 = Habit(name: "Test 2", textDescription: "Test", limit: .none, firstDay: .now)
    let habit3 = Habit(name: "Test 3", textDescription: "Test", limit: 10, firstDay: .now)
    let habit4 = Habit(name: "Test 4", textDescription: "Test", goal: .weekly(number: 3), firstDay: .now)
    container.mainContext.insert(habit1!)
    container.mainContext.insert(habit2!)
    container.mainContext.insert(habit3!)
    container.mainContext.insert(habit4!)
    return container
}
