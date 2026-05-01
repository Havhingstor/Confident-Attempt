import Confident_Attempt_Model
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.name) private var items: [Habit]

    @AppStorage("periodScale") private var periodScale = TimeScale.month
    @AppStorage("periodAmount") private var periodAmount = 1
    @AppStorage("redZone") private var redZone = 0.75
    @AppStorage("dayStart") private var dayStart = RawDateComponents()

    @State private var addHabitShown = false
    @State private var editHabit: Habit? = nil
    @State private var deleteHabit: Habit? = nil
    @State private var duplicateHabit: Habit? = nil
    @State private var showDuplicateDialog = false
    @State private var showDeletionDialog = false

    private var calculationPeriod: CalculationStart {
        periodScale.toCalculationStart(withNum: UInt(clamping: periodAmount))
    }

    private var today: DateComponents {
        (Calendar.current.date(byAdding: dayStart.val.invertedTime, to: Date.now) ?? .now).dc
    }

    private var floatStyle: FloatingPointFormatStyle<Double> {
        .number.precision(.fractionLength(0 ... 2))
    }

    private var percentStyle: FloatingPointFormatStyle<Double>.Percent {
        FloatingPointFormatStyle<Double>.Percent().precision(.fractionLength(0)).rounded(rule: .down)
    }

    private func getNewName(_ habit: Habit) -> String {
        var newName = habit.name + " - Copy"

        while true {
            let descriptor = FetchDescriptor<Habit>(
                predicate: #Predicate { habit in
                    habit.name == newName
                }
            )

            if let existing = try? modelContext.fetch(descriptor),
               !existing.isEmpty
            {
                newName += " - Copy"
                continue
            }

            return newName
        }

        return ""
    }

    var body: some View {
        NavigationStack {
            List(items) { item in
                HStack {
                    getHabitSymbol(item)
                    VStack(alignment: .leading) {
                        Image(systemName: item.symbol ?? "book.pages")
                            .font(.title3)
                        Text(item.name)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(getHabitGoal(item))

                        Text(getHabitText(item))

                        Text("Completion: \(item.getEvaluation(from: calculationPeriod, to: today).formatted(percentStyle))")
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
                .contextMenu {
                    Button("Edit") {
                        editHabit = item
                    }
                    Button("Duplicate") {
                        duplicateHabit = item
                        showDuplicateDialog = true
                    }
                    Button("Delete", role: .destructive) {
                        deleteHabit = item
                        showDeletionDialog = true
                    }
                }
            }
            .navigationTitle("Confident Attempt")
            .toolbar {
                NavigationLink {
                    SettingsView(redZone: $redZone, periodScale: $periodScale, periodAmount: $periodAmount, dayStart: $dayStart.val)
                } label: {
                    Label("Settings", systemImage: "gear")
                }
                NavigationLink {
                    HelpView()
                } label: {
                    Label("Help", systemImage: "questionmark")
                }

                Button("New Habit", systemImage: "plus") {
                    addHabitShown = true
                }
            }
            .sheet(isPresented: $addHabitShown) {
                HabitEditView()
            }
            .sheet(item: $editHabit) { habit in
                HabitEditView(editedHabit: habit)
            }
            .alert("Delete Entry \"\(deleteHabit?.name ?? "")\"?", isPresented: $showDeletionDialog) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    guard let deleteHabit else { return }
                    modelContext.delete(deleteHabit)
                }
            }
            .alert("Copy with Data?", isPresented: $showDuplicateDialog) {
                Button("Cancel", role: .cancel) {}
                Button("Copy Data") {
                    guard let duplicateHabit else { return }
                    let newElement = Habit(cloneof: duplicateHabit, newName: getNewName(duplicateHabit), copyData: true)
                    modelContext.insert(newElement)
                }
                Button("Without Data") {
                    guard let duplicateHabit else { return }
                    let newElement = Habit(cloneof: duplicateHabit, newName: getNewName(duplicateHabit), copyData: false)
                    modelContext.insert(newElement)
                }
            }
        }
    }

    private func getHabitSymbol(_ habit: Habit) -> some View {
        let number = habit.getDay(today)

        var result = Image(systemName: "number.circle.fill")

        if number == 0 {
            result = Image(systemName: "xmark.circle.fill")
        } else if let repetition = habit.repetition, repetition == 1 && number == 1 {
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

        if let repetition = habit.repetition {
            if repetition == 1 {
                if number == 1 {
                    result = "Done"
                } else {
                    result = "Yet to do"
                }

                result += " today"
            } else {
                result += " / \(repetition)"
            }
        }

        return result
    }

    private func getHabitGoal(_ habit: Habit) -> String {
        let goal = habit.goal
        let period = switch goal {
        case let .daily(goalNum):
            if goalNum == 1 {
                "daily"
            } else {
                "\(goalNum) per day"
            }
        case let .weekly(goalNum):
            if goalNum == 1 {
                "weekly"
            } else {
                "\(goalNum) per week"
            }
        case let .monthly(goalNum):
            if goalNum == 1 {
                "monthly"
            } else {
                "\(goalNum) per month"
            }
        case let .yearly(goalNum):
            if goalNum == 1 {
                "yearly"
            } else {
                "\(goalNum) per year"
            }
        }

        return "Goal: \(period)"
    }

    private func getForegroundColour(_ habit: Habit) -> Color {
        let eval = habit.getEvaluation(from: calculationPeriod, to: today)

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
    let habit2 = Habit(name: "Test 2", textDescription: "Test", repetition: .none)
    let habit3 = Habit(name: "Test 3", textDescription: "Test", repetition: 10)
    let habit4 = Habit(name: "Test 4", textDescription: "Test", goal: .weekly(number: 3))
    container.mainContext.insert(habit1!)
    container.mainContext.insert(habit2!)
    container.mainContext.insert(habit3!)
    container.mainContext.insert(habit4!)
    return container
}
