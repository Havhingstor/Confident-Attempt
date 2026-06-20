import Confident_Attempt_Model
import OSLog
import SwiftData
import SwiftUI

extension HabitRowView {
    @Observable
    class ViewModel {
        var habit: Habit
        var superViewModel: ContentView.ViewModel
        var showEditor = false
        var showDetails = false
        var showDeletionAlert = false
        var showDuplicateAlert = false

        init(_ habit: Habit, _ superViewModel: ContentView.ViewModel) {
            self.habit = habit
            self.superViewModel = superViewModel
        }

        var percentStyle: FloatingPointFormatStyle<Double>.Percent {
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

        var text: LocalizedStringKey {
            if let repetition = habit.repetition {
                if repetition == 1 {
                    if dayValue == 1 {
                        return "row.today.done"
                    } else {
                        return "row.today.not-done"
                    }
                } else {
                    return "row.today.\(dayValue)-\(repetition)"
                }
            }
            
            return ""
        }

        var goal: LocalizedStringKey {
            let goal = habit.goal
            switch goal {
            case let .daily(goalNum):
                if goalNum == 1 {
                    return "row.goal.daily"
                } else {
                    return "row.goal.daily-\(goalNum)"
                }
            case let .weekly(goalNum):
                if goalNum == 1 {
                    return "row.goal.weekly"
                } else {
                    return "row.goal.weekly-\(goalNum)"
                }
            case let .monthly(goalNum):
                if goalNum == 1 {
                    return "row.goal.monthly"
                } else {
                    return "row.goal.monthly-\(goalNum)"
                }
            case let .yearly(goalNum):
                if goalNum == 1 {
                    return "row.goal.yearly"
                } else {
                    return "row.goal.yearly-\(goalNum)"
                }
            }
        }

        var evaluationText: LocalizedStringKey {
            "row.evaluation-\(habit.getEvaluation(from: calculationPeriod, to: referenceDate).formatted(percentStyle))"
        }

        var foregroundColour: Color {
            let eval = habit.getEvaluation(from: calculationPeriod, to: referenceDate)

            return if eval < preferences.redZone {
                .red
            } else if eval >= 1.0 {
                .green
            } else {
                .yellow
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
        }

        func setBadgeNow(context: ModelContext) {
            superViewModel.setBadgeNow(context: context)
        }

        func delete(context: ModelContext) {
            context.delete(habit)

            do {
                try context.save()
            } catch let err {
                logger().error("Can't save model context at the moment: \(err)")
            }
        }

        func duplicateWithCopy(context: ModelContext) {
            let newElement = Habit(cloneof: habit, newName: getNewName(habit, context: context), copyData: true, firstDay: referenceDate)
            context.insert(newElement)

            do {
                try context.save()
            } catch let err {
                logger().error("Can't save model context at the moment: \(err)")
            }
        }

        func duplicateWithoutCopy(context: ModelContext) {
            let newElement = Habit(cloneof: habit, newName: getNewName(habit, context: context), copyData: false, firstDay: referenceDate)
            context.insert(newElement)

            do {
                try context.save()
            } catch let err {
                logger().error("Can't save model context at the moment: \(err)")
            }
        }

        func increase() {
            habit.increaseDay(referenceDate, by: 1)
        }

        func decrease() {
            habit.decreaseDay(referenceDate, by: 1)
        }
    }
}
