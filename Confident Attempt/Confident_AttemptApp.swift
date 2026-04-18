import SwiftUI
import Confident_Attempt_Model
import SwiftData

@main
struct Confident_AttemptApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Task.self)
    }
}
