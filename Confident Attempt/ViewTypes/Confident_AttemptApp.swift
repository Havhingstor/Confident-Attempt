import Confident_Attempt_Model
import SwiftData
import SwiftUI

@main
struct Confident_AttemptApp: App {
    @State private var preferences = Preferences()
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Habit.self, migrationPlan: HabitsMigrationPlan.self)
        } catch {
            fatalError("Failed to initialize model container.")
        }
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

    let habit1 = Habit(name: "Test 1", textDescription: "Test")
    let habit2 = Habit(name: "Test 2", textDescription: "Test", repetition: .none)
    let habit3 = Habit(name: "Test 3", textDescription: "Test", repetition: 10)
    let habit4 = Habit(name: "Test 4", textDescription: "Test", goal: .weekly(number: 3))
    container.mainContext.insert(habit1!)
    container.mainContext.insert(habit2!)
    container.mainContext.insert(habit3!)
    container.mainContext.insert(habit4!)
    return container
}
