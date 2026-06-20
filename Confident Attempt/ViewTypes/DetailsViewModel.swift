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

        var goal: LocalizedStringKey {
            superViewModel.goal
        }

        var evaluationText: LocalizedStringKey {
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

        var expectedStyle: FloatingPointFormatStyle<Double> {
            return FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0)).rounded(rule: .up)
        }

        var expectedText: LocalizedStringKey {
            let expected = habit.getExpected(from: calculationPeriod, to: referenceDate)
            return "details.expected-\(expected.formatted(expectedStyle))"
        }

        var timePeriodString: LocalizedStringKey {
            guard let (dayBefore, _) = habit.getDayBeforeEvalStart(from: calculationPeriod, to: referenceDate),
                  let firstDay = dayBefore.addingDays(1),
                  let daysInBetween = referenceDate.daysSince(firstDay),
                  let firstDayDate = firstDay.asDate else { return "" }

            let totalDays = UInt(clamping: daysInBetween + 1)

            let totalDaysStr = numberAsText(totalDays)

            return "details.since-\(firstDayDate.formatted(date: .complete, time: .omitted))-\(totalDaysStr)-\(totalDays)"
        }

        var selectedDayString: LocalizedStringKey {
            guard let date = selectedDate?.asDate else { return "" }
            return "details.on-\(date.formatted(date: .complete, time: .omitted))"
        }

        var selectedDayCompletionsString: LocalizedStringKey {
            guard let selectedDate else { return "" }
            return "details.completions-\(habit.getDay(selectedDate))"
        }

        var maximumString: LocalizedStringKey {
            if let max = habit.repetition {
                return "details.maximum-\(max)"
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

        /// Calculates the days the user reaches yellow (first value) or green (second value) status if they complete the habit at the minimum number evaluating over 1
        /// Value is nil if the goal can't be reached or is already reached
        func getDayPredictionResults() -> (DateComponents?, DateComponents?) {
            let redZone = superViewModel.preferences.redZone
            return habit.calculateFutureEvals(referenceDate: referenceDate, start: calculationPeriod, yellowRatio: redZone)
        }
    }
}
