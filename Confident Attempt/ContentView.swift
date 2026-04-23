import SwiftUI
import SwiftData
import Confident_Attempt_Model

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Task.name) private var items: [Task]
    
    private var relevantPeriod = CalculationStart.months(number: 1)
    private var expectedOverall = 0.75

    private var today: DateComponents {
        Date.now.dc
    }
    
    private var floatStyle: FloatingPointFormatStyle<Double> {
        .number.precision(.fractionLength(0...2))
    }
    
    private var percentStyle: FloatingPointFormatStyle<Double>.Percent {
        FloatingPointFormatStyle<Double>.Percent().precision(.fractionLength(0))
    }
    
    var body: some View {
        List(items) { item in
            HStack {
                getTaskSymbol(item)
                VStack(alignment: .leading) {
                    HStack {
                        Text(item.name)
                        
                        Spacer()
                        
                        Text(getTaskExpected(item))
                    }
                    HStack {
                        Text("Completion: \(item.getEvaluation(from: relevantPeriod, to: today).formatted(percentStyle))")
                        
                        Spacer()
                        
                        Text(getTaskText(item))
                    }
                }
            }
            .foregroundStyle(getForegroundColour(item))
            .swipeActions(edge: .trailing) {
                Button("Decrease", systemImage: "minus.circle") {
                    withAnimation {
                        item.decreaseDay(today, by: 1)
                    }
                }
            }
            .swipeActions(edge: .leading) {
                Button("Increase", systemImage: "plus.circle") {
                    withAnimation {
                        item.increaseDay(today, by: 1)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Button("New Task", systemImage: "plus") {
                    
                }
            }
        }
    }
    
    private func getTaskSymbol(_ task: Task) -> some View {
        let number = task.getDay(today)
        
        var result = Image(systemName: "number.circle.fill")
        
        if number == 0 {
            result = Image(systemName: "xmark.circle.fill")
        } else if let max = task.maxNum, max == 1 && number == 1 {
            result = Image(systemName: "checkmark.circle.fill")
        } else if number <= 50 {
            result = Image(systemName: "\(number).circle.fill")
        }
        
        if task.getEvaluationForDay(today) >= 1.0 {
            return result.foregroundStyle(.green)
        } else {
            return result.foregroundStyle(.red)
        }
    }
    
    private func getTaskText(_ task: Task) -> String {
        let number = task.getDay(today)
        
        var result = "Today: \(number)"
        
        if let max = task.maxNum {
            if max == 1 {
                if number == 1 {
                    result = "Done"
                } else {
                    result = "Yet to do"
                }
                
                result += " today"
            } else {
                result += " / \(max)"
            }
        }
        
        return result
    }
    
    private func getTaskExpected(_ task: Task) -> String {
        let expected = task.expectedNum
        let period = switch expected {
            case .daily(let expectedNum):
                "\(expectedNum) daily"
            case .weekly(let expectedNum):
                "\(expectedNum) weekly"
            case .monthly(let expectedNum):
                "\(expectedNum) monthly"
            case .yearly(let expectedNum):
                "\(expectedNum) yearly"
        }
        
        return "Expected: \(period)"
    }
    
    private func getForegroundColour(_ task: Task) -> Color {
        let eval = task.getEvaluation(from: relevantPeriod, to: today)
        
        return if eval < expectedOverall {
            .red
        } else if eval >= 1.0 {
            .green
        } else {
            .primary
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
    let task2 = Task(name: "Test 2", textDescription: "Test", maxNum: .none)
    let task3 = Task(name: "Test 3", textDescription: "Test", maxNum: 10)
    let task4 = Task(name: "Test 4", textDescription: "Test", expectedNum: .weekly(number: 3))
    container.mainContext.insert(task1!)
    container.mainContext.insert(task2!)
    container.mainContext.insert(task3!)
    container.mainContext.insert(task4!)
    return container
}
