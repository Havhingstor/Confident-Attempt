import Confident_Attempt_Model
import SwiftUI

extension DetailsView {
    @Observable
    class ViewModel {
        var superViewModel: HabitRowView.ViewModel
        var selectedDate: DateComponents?
        var visibleComponentsCalendar: DateComponents

        var habit: Habit {
            superViewModel.habit
        }

        var calculationPeriod: CalculationStart {
            superViewModel.calculationPeriod
        }

        var referenceDate: DateComponents {
            superViewModel.referenceDate
        }

        var goal: String {
            superViewModel.goal
        }

        var evaluationText: String {
            superViewModel.evaluationText
        }

        var evaluationColour: Color {
            superViewModel.foregroundColour
        }

        var dayColour: Color {
            habit.getEvaluationForDay(selectedDate ?? .now) >= 1.0 ? .green : .red
        }

        init(_ superViewModel: HabitRowView.ViewModel) {
            self.superViewModel = superViewModel
            selectedDate = nil
            visibleComponentsCalendar = .now
        }

        var total: UInt {
            habit.getTotal(from: calculationPeriod, to: referenceDate)
        }

        var timePeriodString: String {
            guard let firstDay = habit.getBeforeStart(from: calculationPeriod, to: referenceDate)?.addingDays(1),
                  let daysInBetween = referenceDate.daysSince(firstDay),
                  let firstDayDate = firstDay.asDate else { return "" }

            let totalDays = UInt(clamping: daysInBetween + 1)

            let totalDaysStr = numberAsText(totalDays)
            let daysStr = totalDays == 1 ? "day" : "days"

            return "Since \(firstDayDate.formatted(date: .complete, time: .omitted))\n(\(totalDaysStr) \(daysStr)):"
        }

        var selectedDayString: String {
            guard let date = selectedDate?.asDate else { return "" }
            return "On \(date.formatted(date: .complete, time: .omitted)):"
        }

        var selectedDayCompletionsString: String {
            guard let selectedDate else { return "" }
            return "Completions: \(habit.getDay(selectedDate))"
        }

        var maximumString: String {
            if let max = habit.repetition {
                return "Maximum: \(max) per day"
            } else {
                return ""
            }
        }

        var dateSelected: Bool {
            selectedDate != nil
        }

        var hasMax: Bool {
            habit.repetition != nil
        }

        /// The first returned list is of days where the user has done enough, the second are the remaining days
        func getDayCompletions() -> (Set<DateComponents>, Set<DateComponents>) {
            var achieved = Set<DateComponents>()
            var remaining = Set<DateComponents>()

            var month = visibleComponentsCalendar
            month.day = 1
            month.hour = 0
            month.minute = 0
            month.second = 0

            if let beginning = month.asDate,
               let beforeStart = Calendar.current.date(byAdding: .day, value: -1, to: beginning),
               let afterEnd = Calendar.current.date(byAdding: .month, value: 1, to: beginning)
            {
                for date in Calendar.current.dates(byAdding: .day, value: 1, startingAt: beforeStart, in: beginning ..< afterEnd) {
                    let components = date.dc
                    if habit.getEvaluationForDay(components) >= 1.0 {
                        achieved.insert(components)
                    } else {
                        remaining.insert(components)
                    }
                }
            }

            return (achieved, remaining)
        }

        func showSelection() {
            visibleComponentsCalendar = selectedDate ?? .now
        }

        func showToday() {
            visibleComponentsCalendar = referenceDate
        }

        func increaseSelected() {
            guard let selectedDate else { return }

            habit.increaseDay(selectedDate, by: 1)
        }

        func decreaseSelected() {
            guard let selectedDate else { return }

            habit.decreaseDay(selectedDate, by: 1)
        }

        func loadDatesCorrectly() {
            selectedDate = referenceDate
            showSelection()
        }
    }
}
