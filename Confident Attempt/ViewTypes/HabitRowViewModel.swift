import SwiftUI
import Confident_Attempt_Model
import SwiftData

extension HabitRowView {
    @Observable
    class ViewModel {
        var habit: Habit
        var superViewModel: ContentView.ViewModel
        var showEditor = false
        var showDeletionAlert = false
        var showDuplicateAlert = false
        
        init(_ habit: Habit, _ superViewModel: ContentView.ViewModel) {
            self.habit = habit
            self.superViewModel = superViewModel
        }
        
        private var percentStyle: FloatingPointFormatStyle<Double>.Percent {
            FloatingPointFormatStyle<Double>.Percent().precision(.fractionLength(0)).rounded(rule: .down)
        }
        
        var name: String {
            habit.name
        }
        
        var dayValue: UInt {
            habit.getDay(referenceDate)
        }
        
        var evaluationToday: Double {
            habit.getEvaluationForDay(referenceDate)
        }
        
        var referenceDate: DateComponents {
            superViewModel.referenceDate
        }
        
        var preferences: Preferences {
            superViewModel.preferences
        }
        
        var calculationPeriod: CalculationStart {
            superViewModel.calculationPeriod
        }
        
        var completionSymbol: some View {
            var result = Image(systemName: "number.circle.fill")
            
            if dayValue == 0 {
                result = Image(systemName: "xmark.circle.fill")
            } else if let repetition = habit.repetition, repetition == 1 && dayValue == 1 {
                result = Image(systemName: "checkmark.circle.fill")
            } else if dayValue <= 50 {
                result = Image(systemName: "\(dayValue).circle.fill")
            }
            
            if evaluationToday >= 1.0 {
                return result.foregroundStyle(.green)
            } else {
                return result.foregroundStyle(.red)
            }
        }
        
        var habitSymbol: some View {
            Image(systemName: habit.symbol ?? "book.pages")
                .font(.title3)
        }
        
        var text: String {
            var result = "referenceDate: \(dayValue)"
            
            if let repetition = habit.repetition {
                if repetition == 1 {
                    if dayValue == 1 {
                        result = "Done"
                    } else {
                        result = "Yet to do"
                    }
                    
                    result += " referenceDate"
                } else {
                    result += " / \(repetition)"
                }
            }
            
            return result
        }
        
        var goal: String {
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
        
        var completionText: String {
            "Completion: \(habit.getEvaluation(from: calculationPeriod, to: referenceDate).formatted(percentStyle))"
        }
        
        var foregroundColour: Color {
            let eval = habit.getEvaluation(from: calculationPeriod, to: referenceDate)
            
            return if eval < preferences.redZone {
                .red
            } else if eval >= 1.0 {
                .green
            } else {
                .primary
            }
        }
        
        func getNewName(_ habit: Habit, context: ModelContext) -> String {
            var newName = habit.name + " - Copy"
            
            while true {
                let descriptor = FetchDescriptor<Habit>(
                    predicate: #Predicate { habit in
                        habit.name == newName
                    }
                )
                
                if let existing = try? context.fetch(descriptor),
                   !existing.isEmpty
                {
                newName += " - Copy"
                continue
                }
                
                return newName
            }
            
            return ""
        }
    
        func setBadge(context: ModelContext) {
            superViewModel.setBadge(context: context)
        }
        
        func delete(context: ModelContext) {
            context.delete(habit)
        }
        
        func duplicateWithCopy(context: ModelContext) {
            let newElement = Habit(cloneof: habit, newName: getNewName(habit, context: context), copyData: true)
            context.insert(newElement)
        }
        
        func duplicateWithoutCopy(context: ModelContext) {
            let newElement = Habit(cloneof: habit, newName: getNewName(habit, context: context), copyData: false)
            context.insert(newElement)
        }
        
        func increase() {
            habit.increaseDay(referenceDate, by: 1)
        }
        
        func decrease() {
            habit.decreaseDay(referenceDate, by: 1)
        }
    }
}
