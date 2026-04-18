import SwiftUI
import SwiftData
import Confident_Attempt_Model

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Task]

    var body: some View {
        List(items) { item in
            HStack {
                Text(item.name)
            }
        }
        .toolbar {
            ToolbarItem {
                Button("New Task", systemImage: "plus") {
                    
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(getContainer())
}

func getContainer() -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Task.self, configurations: config)
    
    let task1 = Task(name: "Test 1", textDescription: "Test")
    let task2 = Task(name: "Test 2", textDescription: "Test")
    let task3 = Task(name: "Test 3", textDescription: "Test")
    let task4 = Task(name: "Test 4", textDescription: "Test")
    container.mainContext.insert(task1)
    container.mainContext.insert(task2)
    container.mainContext.insert(task3)
    container.mainContext.insert(task4)
    return container
}
