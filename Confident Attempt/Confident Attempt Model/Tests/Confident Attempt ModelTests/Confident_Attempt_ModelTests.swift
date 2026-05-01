import Confident_Attempt_Model
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
    let baseHabit = Habit(name: "Habit", textDescription: "Some habit", repetition: 3, goal: .daily(number: 2))!

    baseHabit.increaseDay(firstDay, by: 2)
    #expect(baseHabit.getDay(firstDay) == 2)

    baseHabit.setDay(secondDay, to: 4)
    #expect(baseHabit.getDay(secondDay) == 3)

    baseHabit.decreaseDay(thirdDay, by: 1)
    #expect(baseHabit.getDay(thirdDay) == 0)

    #expect(baseHabit.getEvaluationForDay(firstDay) == 1)
    #expect(baseHabit.getEvaluationForDay(secondDay) == 1.5)
    #expect(baseHabit.getEvaluationForDay(thirdDay) == 0)

    let twoDayEvaluation = CalculationStart.days(number: 2)
    let oneMonthEvaluation = CalculationStart.months(number: 1)
    #expect(baseHabit.getTotal(from: twoDayEvaluation, to: thirdDay) == 3)
    #expect(baseHabit.getEvaluation(from: twoDayEvaluation, to: thirdDay) == 0.75)
    #expect(baseHabit.getEvaluation(from: oneMonthEvaluation, to: thirdDay) > 0)
    #expect(baseHabit.getEvaluation(from: oneMonthEvaluation, to: thirdDay) < 0.25)

    let clone1 = Habit(cloneof: baseHabit, newName: "TestName", copyData: true)
    #expect(clone1.getDay(firstDay) == 2)
    #expect(clone1.name == "TestName")

    let clone2 = Habit(cloneof: baseHabit, newName: "NewTestName", copyData: false)
    #expect(clone2.getDay(firstDay) == 0)
    #expect(clone2.name == "NewTestName")

    clone1.setRepetitionAndGoal(rep: 2, goal: .daily(number: 2))
    #expect(clone1.getDay(firstDay) == 2)
    #expect(clone1.getDay(secondDay) == 2)
    #expect(clone1.getDay(thirdDay) == 0)
}

@Test
func illegalHabit() {
    #expect(Habit(name: "A", textDescription: "", repetition: 0) == nil)
    #expect(Habit(name: "A", textDescription: "", goal: .daily(number: 0)) == nil)
    #expect(Habit(name: "A", textDescription: "", repetition: 1, goal: .daily(number: 2)) == nil)
}
