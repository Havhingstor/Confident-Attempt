import SwiftUI
import SwiftData
import Confident_Attempt_Model

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.name) private var items: [Habit]
    
    @State private var relevantPeriod = CalculationStart.months(number: 1)
    @State private var redZone = 0.75
    
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
        NavigationStack {
            List(items) { item in
                HStack {
                    getHabitSymbol(item)
                    VStack(alignment: .leading) {
                        HStack {
                            Text(item.name)
                            
                            Spacer()
                            
                            Text(getHabitGoal(item))
                        }
                        HStack {
                            Text("Completion: \(item.getEvaluation(from: relevantPeriod, to: today).formatted(percentStyle))")
                            
                            Spacer()
                            
                            Text(getHabitText(item))
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
            .navigationTitle("Confident Attempt")
            .toolbar {
                NavigationLink {
                    SettingsView(redZone: $redZone, relevantPeriod: $relevantPeriod)
                } label: {
                    Label("Settings", systemImage: "gear")
                }

                Button("New Habit", systemImage: "plus") {
                    
                }
            }
        }
    }
    
    private func getHabitSymbol(_ habit: Habit) -> some View {
        let number = habit.getDay(today)
        
        var result = Image(systemName: "number.circle.fill")
        
        if number == 0 {
            result = Image(systemName: "xmark.circle.fill")
        } else if let max = habit.maxNum, max == 1 && number == 1 {
            result = Image(systemName: "checkmark.circle.fill")
        } else if number <= 50 {
            result = Image(systemName: "\(number).circle.fill")
        }
        
        if habit.getEvaluationForDay(today) >= 1.0 {
            return result.foregroundStyle(.green)
        } else {
            return result.foregroundStyle(.red)
        }
    }
    
    private func getHabitText(_ habit: Habit) -> String {
        let number = habit.getDay(today)
        
        var result = "Today: \(number)"
        
        if let max = habit.maxNum {
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
    
    private func getHabitGoal(_ habit: Habit) -> String {
        let goal = habit.goal
        let period = switch goal {
            case .daily(let goalNum):
                if goalNum == 1 {
                    "daily"
                } else {
                    "\(goalNum) per day"
                }
            case .weekly(let goalNum):
                if goalNum == 1 {
                    "weekly"
                } else {
                    "\(goalNum) per week"
                }
            case .monthly(let goalNum):
                if goalNum == 1 {
                    "monthly"
                } else {
                    "\(goalNum) per month"
                }
            case .yearly(let goalNum):
                if goalNum == 1 {
                    "yearly"
                } else {
                    "\(goalNum) per year"
                }
        }
        
        return "Goal: \(period)"
    }
    
    private func getForegroundColour(_ habit: Habit) -> Color {
        let eval = habit.getEvaluation(from: relevantPeriod, to: today)
        
        return if eval < redZone {
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
    let container = try! ModelContainer(for: Habit.self, configurations: config)
    
    let habit1 = Habit(name: "Test 1", textDescription: "Test")
    let habit2 = Habit(name: "Test 2", textDescription: "Test", maxNum: .none)
    let habit3 = Habit(name: "Test 3", textDescription: "Test", maxNum: 10)
    let habit4 = Habit(name: "Test 4", textDescription: "Test", goal: .weekly(number: 3))
    container.mainContext.insert(habit1!)
    container.mainContext.insert(habit2!)
    container.mainContext.insert(habit3!)
    container.mainContext.insert(habit4!)
    return container
}
