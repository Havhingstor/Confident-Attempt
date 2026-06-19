import Foundation

public extension Habit {
    // MARK: - Helpers
    
    func calculateFirstDay() -> DateComponents {
        if let fromData = newDayResults.filter({ $0.value > 0 }).map({ $0.key }).sorted().first {
            return min(fromData, firstDay)
        } else {
            return firstDay
        }
    }
    
    /// Returns the day before the eval start, does NOT account for first day
    private func getBeforeStartRaw(from: CalculationStart, to: DateComponents) -> DateComponents? {
        guard let lastDate = to.asDate,
              let beforeStart = Calendar.current.date(byAdding: from.getAsDateComponents(), to: lastDate)?.dc else { return nil }
        
        return beforeStart
    }
    
    /// Returns the day before the evaluation in question starts and a flag indicating if this was changed by the calculated first day
    func getDayBeforeEvalStart(from: CalculationStart, to: DateComponents) -> (DateComponents, Bool)? {
        guard let beforeStart = getBeforeStartRaw(from: from, to: to),
              let beforeFirst = calculateFirstDay().addingDays(-1) else { return nil }
        
        if beforeFirst > beforeStart {
            return (beforeFirst, true)
        } else {
            return (beforeStart, false)
        }
    }
    
    private func getProportionOfGoalPeriod(beforeStart: DateComponents, to: DateComponents,
                                           from calcPeriod: CalculationStart, fdEffect influencedByFirstDay: Bool) -> Double?
    {
        if !influencedByFirstDay, calcPeriod.typeEq(rhs: goal) {
            return Double(calcPeriod.getNumber())
        }
    
        guard var totalRemainingDays = to.daysSince(beforeStart) else {
            logger().error("Can't calculate the days between \(to) and \(beforeStart)")
            return nil
        }
        guard var currentStartDate = to.asDate else {
            logger().error("Can't convert \(to) to a date")
            return nil
        }
    
        let oneGoalPeriod: DateComponents!
        var result = 0.0
    
        switch goal {
            case .daily(number: _):
                return Double(totalRemainingDays)
            case .weekly(number: _):
                return Double(totalRemainingDays) / 7.0
            case .monthly(number: _):
                oneGoalPeriod = DateComponents(month: -1)
            case .yearly(number: _):
                oneGoalPeriod = DateComponents(year: -1)
        }
    
        while totalRemainingDays > 0 {
            guard let nextStartDate = Calendar.current.date(byAdding: oneGoalPeriod, to: currentStartDate) else {
                logger().error("Can't calculate a new date adding \(oneGoalPeriod) to \(currentStartDate)")
                return nil
            }
            guard let daysInPeriod = currentStartDate.dc.daysSince(nextStartDate.dc) else {
                logger().error("Can't calculate the number of days between \(currentStartDate) and \(nextStartDate)")
                return nil
            }
        
            if totalRemainingDays >= daysInPeriod {
                result += 1.0
            } else {
                result += Double(totalRemainingDays) / Double(daysInPeriod)
            }
        
            totalRemainingDays -= daysInPeriod
            currentStartDate = nextStartDate
        }
    
        return result
    }
    
    // MARK: - Total
    
    private func getTotal(beforeStart: DateComponents, to: DateComponents) -> UInt {
        let filteredDays = newDayResults.filter { $0.key > beforeStart && $0.key <= to }
        let count = filteredDays.count
        let directlySetValue = filteredDays.reduce(0) { $0 + UInt($1.value) }
        let totalDays = to.daysSince(beforeStart) ?? 0
        
        return directlySetValue + UInt(clamping: totalDays - count) * dayDefault
    }
    
    func getTotal(from: CalculationStart, to: DateComponents) -> UInt {
        guard let (beforeStart, _) = getDayBeforeEvalStart(from: from, to: to) else { return 0 }
        
        return getTotal(beforeStart: beforeStart, to: to)
    }
    
    // MARK: - Expected
    
    private func getExpectedInternal(from: CalculationStart, to: DateComponents) -> (Double?, DateComponents) {
        guard let (beforeStart, fdEffect) = getDayBeforeEvalStart(from: from, to: to) else { return (0, .now) }
        
        guard let encompassedGoalPeriods = getProportionOfGoalPeriod(beforeStart: beforeStart, to: to, from: from, fdEffect: fdEffect) else { return (nil, beforeStart) }
        
        return (Double(goal.getNumber()) * encompassedGoalPeriods, beforeStart)
    }
    
    func getExpected(from: CalculationStart, to: DateComponents) -> Double {
        getExpectedInternal(from: from, to: to).0 ?? 0
    }
    
    // MARK: - Day Eval
    
    private func getDayEvalIfUsable(day: DateComponents) -> Double? {
        guard let storedDayEval else { return nil }
        
        if storedDayEval.day.cleanEq(day) {
            return storedDayEval.value
        } else {
            return nil
        }
    }
    
    func getEvaluationForDay(_ day: DateComponents) -> Double {
        if let eval = getDayEvalIfUsable(day: day) {
            return eval
        }
        let result = Double(getDay(day)) / goal.getAsDaily(forDate: day)
        storedDayEval = StoredDayEval(day: day, value: result)
        return result
    }
    
    // MARK: - Total Eval
    
    private func getEvalIfUsable(from: CalculationStart, to: DateComponents) -> Double? {
        guard let storedEval else { return nil }
        
        if storedEval.from == from, storedEval.to.cleanEq(to) {
            return storedEval.value
        } else {
            return nil
        }
    }
    
    func getEvaluation(from: CalculationStart, to: DateComponents) -> Double {
        if let result = getEvalIfUsable(from: from, to: to) {
            return result
        }
        
        let (totalGoal, beforeStart) = getExpectedInternal(from: from, to: to)
        
        guard let totalGoal else {
            logger().error("Couldn't calculate goal. Returning Evaluation 0")
            return 0
        }
        
        let total = getTotal(beforeStart: beforeStart, to: to)
        
        let result = Double(total) / totalGoal
        
        storedEval = StoredEval(from: from, to: to, value: result)
        
        return result
    }
    
    // MARK: - Future Eval
    
    /// Calculates the days the user reaches yellow (first value) or green (second value) status if they complete the habit at the minimum number evaluating over 1
    /// Value is nil if the goal can't be reached or is already reached
    func calculateFutureEvals(referenceDate: DateComponents, start: CalculationStart, yellowRatio: Double) -> (yellow: DateComponents?, green: DateComponents?) {
        if let storedPrediction,
           storedPrediction.referenceDate == referenceDate,
           storedPrediction.start == start,
           storedPrediction.yellowRatio == yellowRatio
        {
            return storedPrediction.value
        }
        
        var resultYellow = DateComponents?(nil)
        var resultGreen = DateComponents?(nil)
        
        guard var (beforeStart, fdEffect) = getDayBeforeEvalStart(from: start, to: referenceDate) else { return (nil, nil) }
        var currentEndDate = referenceDate
        
        var currentTotal = getTotal(beforeStart: beforeStart, to: currentEndDate)
        
        // Today should also be set to at least completions
        var completions = UInt(goal.getAsDaily(forDate: currentEndDate).rounded(.up))
        if let rep = repetition, rep < completions {
            completions = rep
        }
        
        let actualValueToday = getDay(referenceDate)
        if completions > actualValueToday {
            currentTotal -= actualValueToday
            currentTotal += completions
        }
        
        outer: while beforeStart < referenceDate {
            // Evaluation of the current date
            guard let encompassedGoalPeriods = getProportionOfGoalPeriod(beforeStart: beforeStart, to: currentEndDate, from: start, fdEffect: fdEffect) else { break }
            let actualGoal = Double(goal.getNumber()) * encompassedGoalPeriods
            
            let ratioToday = Double(currentTotal) / actualGoal
            
            if resultYellow == nil, ratioToday >= yellowRatio {
                resultYellow = currentEndDate
            }
            
            if resultGreen == nil, ratioToday >= 1.0 {
                resultGreen = currentEndDate
            }
            
            if resultYellow != nil, resultGreen != nil {
                break
            }
            
            // Calculation of the next date
            
            guard let nextEndDate = currentEndDate.addingDays(1) else { break }
            currentEndDate = nextEndDate
            
            var bsIter = beforeStart
            if fdEffect {
                guard let (next, nextFDEffect) = getDayBeforeEvalStart(from: start, to: currentEndDate) else { break }
                beforeStart = next
                fdEffect = nextFDEffect
            } else {
                guard let next = getBeforeStartRaw(from: start, to: currentEndDate) else { break }
                beforeStart = next
            }
            
            // beforeStart might jump various distances >= 0 so we need to sum all the completions that fell out
            var fellOut = UInt(0)
            
            while bsIter < beforeStart {
                guard let next = bsIter.addingDays(1) else { break outer }
                bsIter = next
                
                fellOut += getDay(bsIter)
            }
            
            var completions = UInt(goal.getAsDaily(forDate: currentEndDate).rounded(.up))
            if let rep = repetition, rep < completions {
                completions = rep
            }
            
            let newIn = max(getDay(currentEndDate), completions)
            
            currentTotal -= fellOut
            currentTotal += newIn
        }
        
        storedPrediction = StoredPrediction(referenceDate: referenceDate, start: start, yellowRatio: yellowRatio, value: (resultYellow, resultGreen))
        
        return (resultYellow, resultGreen)
    }
}
