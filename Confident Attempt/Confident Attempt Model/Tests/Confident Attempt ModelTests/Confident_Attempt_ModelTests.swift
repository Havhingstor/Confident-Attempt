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
    let startDate = DateComponents(year: 2026, month: 3, day: 17)
    let baseTask = Task(name: "Task", textDescription: "Some task", firstDay: startDate, maxNum: 3, expectedNum: .daily(number: 2))
    
    baseTask.increaseDay(0, by: 2)
    #expect(baseTask.getDay(0) == 2)
    
    baseTask.setDay(1, to: 3)
    #expect(baseTask.getDay(1) == 3)
    
    baseTask.decreaseDay(2, by: 1)
    #expect(baseTask.getDay(2) == 0)
    
    baseTask.setDay(startDate, to: 3)
    #expect(baseTask.getDay(0) == 3)
    
    let secondDay = DateComponents(year: 2026, month: 3, day: 18)
    baseTask.decreaseDay(secondDay, by: 1)
    #expect(baseTask.getDay(secondDay) == 2)
    
    baseTask.increaseDay(DateComponents(year: 2026, month: 3, day: 19), by: 4)
    #expect(baseTask.getDay(2) == 3)
    
    #expect(baseTask.getEvaluationForDay(0) == 1.5)
    #expect(baseTask.getEvaluationForDay(secondDay) == 1)
    #expect(baseTask.getEvaluationForDay(2) == 1.5)
    
    let thirdDay = DateComponents(year: 2026, month: 3, day: 18)
    let twoDayEvaluation = CalculationStart.days(number: 2)
    let oneMonthEvaluation = CalculationStart.months(number: 1)
    #expect(baseTask.getTotal(from: twoDayEvaluation, to: thirdDay) == 5)
    #expect(baseTask.getEvaluation(from: twoDayEvaluation, to: thirdDay) == 1.25)
    #expect(baseTask.getEvaluation(from: oneMonthEvaluation, to: thirdDay) != 0)
}
