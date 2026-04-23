import Testing
import Foundation
import Confident_Attempt_Model

@Test
func testExpected() {
    let onceDaily = ExpectedCompletions.daily(number: 1)
    let twiceWeekly = ExpectedCompletions.weekly(number: 2)
    let thriceMonthly = ExpectedCompletions.monthly(number: 3)
    let fourTimesAYear = ExpectedCompletions.yearly(number: 4)
    
    let date = DateComponents(year: 2026, month: 3, day: 17)
    
    #expect(onceDaily.getAsDaily(forDate: date) == 1.0)
    #expect(twiceWeekly.getAsDaily(forDate: date) * 7.0 == 2)
    #expect(thriceMonthly.getAsDaily(forDate: date) * 31.0 == 3)
    #expect(fourTimesAYear.getAsDaily(forDate: date) * 365 == 4)
}

@Test
func testTaskBasics() {
    let firstDay = DateComponents(year: 2026, month: 3, day: 17)
    let secondDay = DateComponents(year: 2026, month: 3, day: 18)
    let thirdDay = DateComponents(year: 2026, month: 3, day: 19)
    let baseTask = Task(name: "Task", textDescription: "Some task", maxNum: 3, expectedNum: .daily(number: 2))!
    
    baseTask.increaseDay(firstDay, by: 2)
    #expect(baseTask.getDay(firstDay) == 2)
    
    baseTask.setDay(secondDay, to: 3)
    #expect(baseTask.getDay(secondDay) == 3)
    
    baseTask.decreaseDay(thirdDay, by: 1)
    #expect(baseTask.getDay(thirdDay) == 0)
    
    #expect(baseTask.getEvaluationForDay(firstDay) == 1)
    #expect(baseTask.getEvaluationForDay(secondDay) == 1.5)
    #expect(baseTask.getEvaluationForDay(thirdDay) == 0)
    
    let twoDayEvaluation = CalculationStart.days(number: 2)
    let oneMonthEvaluation = CalculationStart.months(number: 1)
    #expect(baseTask.getTotal(from: twoDayEvaluation, to: thirdDay) == 3)
    #expect(baseTask.getEvaluation(from: twoDayEvaluation, to: thirdDay) == 0.75)
    #expect(baseTask.getEvaluation(from: oneMonthEvaluation, to: thirdDay) != 0)
}

@Test
func testIllegalTask() {
    #expect(Task(name: "A", textDescription: "", maxNum: 0) == nil)
    #expect(Task(name: "A", textDescription: "", expectedNum: .daily(number: 0)) == nil)
    #expect(Task(name: "A", textDescription: "", maxNum: 1, expectedNum: .daily(number: 2)) == nil)
}
