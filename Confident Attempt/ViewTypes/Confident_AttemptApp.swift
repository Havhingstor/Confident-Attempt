import Confident_Attempt_Model
import SwiftData
import SwiftUI

@main
struct Confident_AttemptApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Habit.self)
    }
}
