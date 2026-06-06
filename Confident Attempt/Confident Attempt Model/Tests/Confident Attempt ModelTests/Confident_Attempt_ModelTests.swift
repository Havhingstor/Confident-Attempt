@testable import Confident_Attempt_Model
import Foundation
import Testing

@Test
func testGoal() {
    let onceDaily = CompletionGoal.daily(number: 1)
    let twiceWeekly = CompletionGoal.weekly(number: 2)
    let thriceMonthly = CompletionGoal.monthly(number: 3)
    let fourTimesAYear = CompletionGoal.yearly(number: 4)

    let date = DateComponents(year: 2026, month: 3, day: 17)

    #expect(onceDaily.getAsDaily(forDate: date) == 1.0)
    #expect(twiceWeekly.getAsDaily(forDate: date) * 7.0 == 2)
    #expect(thriceMonthly.getAsDaily(forDate: date) * 31.0 == 3)
    #expect(fourTimesAYear.getAsDaily(forDate: date) * 365 == 4)
}

@Test
func habitBasics() {
    let firstDay = DateComponents(year: 2026, month: 3, day: 17)
    let secondDay = DateComponents(year: 2026, month: 3, day: 18)
    let thirdDay = DateComponents(year: 2026, month: 3, day: 19)
    let baseHabit = Habit(name: "Habit", textDescription: "Some habit", repetition: 3, goal: .daily(number: 2), firstDay: firstDay)!

    baseHabit.increaseDay(firstDay, by: 2)
    #expect(baseHabit.getDay(firstDay) == 2)

    baseHabit.setDay(secondDay, to: 4)
    #expect(baseHabit.getDay(secondDay) == 3)

    baseHabit.decreaseDay(thirdDay, by: 1)
    #expect(baseHabit.getDay(thirdDay) == 0)

    #expect(baseHabit.getEvaluationForDay(firstDay) == 1)
    #expect(baseHabit.getEvaluationForDay(firstDay) == 1) // Test caching
    #expect(baseHabit.getEvaluationForDay(secondDay) == 1.5)
    #expect(baseHabit.getEvaluationForDay(thirdDay) == 0)
    #expect(baseHabit.getEvaluationForDay(firstDay) == 1) // Test caching

    let twoDayEvaluation = CalculationStart.days(number: 2)
    let oneMonthEvaluation = CalculationStart.months(number: 1)
    #expect(baseHabit.getTotal(from: twoDayEvaluation, to: thirdDay) == 3)
    #expect(baseHabit.getEvaluation(from: twoDayEvaluation, to: thirdDay) == 0.75)
    #expect(baseHabit.getEvaluation(from: twoDayEvaluation, to: thirdDay) == 0.75) // Test caching
    #expect(baseHabit.getEvaluation(from: oneMonthEvaluation, to: thirdDay) > 0.83)
    #expect(baseHabit.getEvaluation(from: oneMonthEvaluation, to: thirdDay) < 0.84)
    #expect(baseHabit.getEvaluation(from: twoDayEvaluation, to: thirdDay) == 0.75) // Test caching

    let beforeFirstDay = DateComponents(year: 2026, month: 3, day: 16)
    baseHabit.setDay(beforeFirstDay, to: 0)
    #expect(baseHabit.firstDay == firstDay)
    #expect(baseHabit.getEvaluation(from: oneMonthEvaluation, to: thirdDay) == 0.625)
    baseHabit.setFirstDay()
    #expect(baseHabit.firstDay == beforeFirstDay)
    #expect(baseHabit.getEvaluation(from: oneMonthEvaluation, to: thirdDay) == 0.625)

    let clone1 = Habit(cloneof: baseHabit, newName: "TestName", copyData: true, firstDay: firstDay)

    #expect(clone1.getDay(firstDay) == 2)
    #expect(clone1.name == "TestName")

    clone1.setDay(firstDay, to: 1)
    #expect(clone1.getDay(firstDay) == 1)
    #expect(baseHabit.getDay(firstDay) == 2)

    clone1.firstDay.day = 1
    #expect(clone1.firstDay.day == 1)
    #expect(baseHabit.firstDay.day == 16)

    let clone2 = Habit(cloneof: baseHabit, newName: "NewTestName", copyData: false, firstDay: firstDay)
    clone2.dayDefault = 3
    #expect(clone2.getDay(firstDay) == 3)
    #expect(clone2.name == "NewTestName")
    #expect(clone2.getEvaluation(from: twoDayEvaluation, to: thirdDay) == 1.5)

    #expect(clone1.checkNewRepetition(2) == 1)
    clone1.setRepetitionAndGoal(rep: 2, goal: .daily(number: 2))
    #expect(clone1.getDay(firstDay) == 1)
    #expect(clone1.getDay(secondDay) == 2)
    #expect(clone1.getDay(thirdDay) == 0)
}

@Test
func illegalHabit() {
    #expect(Habit(name: "A", textDescription: "", repetition: 0, firstDay: .now) == nil)
    #expect(Habit(name: "A", textDescription: "", goal: .daily(number: 0), firstDay: .now) == nil)
    #expect(Habit(name: "A", textDescription: "", repetition: 1, goal: .daily(number: 2), firstDay: .now) == nil)
}

@Test
func specialEvaluation() {
    let firstDay = DateComponents(year: 2026, month: 5, day: 20)
    let currentDay = DateComponents(year: 2026, month: 6, day: 19)
    let habit = Habit(name: "Test", textDescription: "", repetition: nil, goal: .monthly(number: 5), firstDay: firstDay)!
    habit.setDay(currentDay, to: 5)

    #expect(habit.getEvaluation(from: .months(number: 1), to: currentDay) == 1.0)
    #expect(habit.getEvaluation(from: .months(number: 2), to: currentDay) == 1.0)
    let shortEval = habit.getEvaluation(from: .days(number: 15), to: currentDay)
    #expect(shortEval < 2.07)
    #expect(shortEval > 2.06)
}
