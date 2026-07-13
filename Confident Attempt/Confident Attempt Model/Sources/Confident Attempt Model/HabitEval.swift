import Foundation

public extension Habit {
    // MARK: - Helpers
    
    func calculateFirstDay() -> DateComponents {
        if let fromData = dayResults.filter({ $0.value > 0 }).map({ $0.key }).sorted().first {
            return min(fromData, firstDay)
        } else {
            return firstDay
        }
    }
    
    /// Returns the day before the evaluation in question starts and a flag indicating if this was changed by the calculated first day
    func getDayBeforeEvalStart(from: CalculationStart, to: DateComponents) -> (DateComponents, Bool)? {
        return getDayBeforeEvalStartOutside(from, to, dayResults, calculateFirstDay())
    }

    // MARK: - Expected
    
    func getExpected(from: CalculationStart, to: DateComponents) -> Double {
        getExpectedOutside(from, to, goal, dayResults, calculateFirstDay()).0 ?? 0
    }
    
    // MARK: - Total

    func getTotal(from: CalculationStart, to: DateComponents) -> UInt {
        getTotalOutside(from, to, dayResults, dayDefault, calculateFirstDay())
    }
    
    // MARK: - Day Eval
    
    private func getEvaluationForDayInternal(_ day: DateComponents) -> StoredDayEval {
        let dayVal = getDay(day)
        var base = StoredDayEval(dayResult: dayVal, day: day, goal: goal)
        
        if let storedDayEval, storedDayEval.equalsBase(base) {
            logger().info("Did load DayEval from cache")
            return storedDayEval
        }

        fillStoredDayEval(&base)
        
        return base
    }
    
    func getEvaluationForDay(_ day: DateComponents) -> Double {
        let result = getEvaluationForDayInternal(day)
        storedDayEval = result
        
        return result.value
    }
    
    // MARK: - Total Eval
    
    private func getEvaluationInternal(from: CalculationStart, to: DateComponents) -> StoredEval {
        // Generate manually (don't use the stored hash) because we need to make sure it actually loaded the most recent changes
        let dayResults = dayResults
        let dayResultsHash = dayResults.hashValue
        var base = StoredEval(from: from, to: to, dayResultsHash: dayResultsHash, goal: goal, firstDay: calculateFirstDay(), dayDefault: dayDefault)
        
        if let storedEval, storedEval.equalsBase(base) {
            logger().info("Did load Total Eval from cache")
            return storedEval
        }
        
        fillStoredEval(&base, dayResults)
        
        return base
    }
    
    func getEvaluation(from: CalculationStart, to: DateComponents) -> Double {
        let result = getEvaluationInternal(from: from, to: to)
        
        storedEval = result
        
        return result.value
    }
    
    // MARK: - Future Eval
    
    private func calculateFutureEvalsInternal(referenceDate: DateComponents, start: CalculationStart, yellowRatio: Double) -> StoredPrediction {
        let dayResults = dayResults
        var base = StoredPrediction(referenceDate: referenceDate, start: start, yellowRatio: yellowRatio, goal: goal,
                                    dayResultsHash: dayResults.hashValue, limit: limit, dayDefault: dayDefault, firstDay: calculateFirstDay())
        
        if let storedPrediction,
           storedPrediction.equalsBase(base)
        {
            logger().info("Did load Prediction from cache")
            return storedPrediction
        }
        
        fillStoredPrediction(&base, dayResults)
        
        return base
    }
    
    /// Calculates the days the user reaches yellow (first value) or green (second value) status if they complete the habit at the minimum number evaluating over 1
    /// Value is nil if the goal can't be reached or is already reached
    func calculateFutureEvals(referenceDate: DateComponents, start: CalculationStart, yellowRatio: Double) -> (yellow: DateComponents?, green: DateComponents?) {
        let result = calculateFutureEvalsInternal(referenceDate: referenceDate, start: start, yellowRatio: yellowRatio)
        
        storedPrediction = result
        
        return result.value
    }
}

// MARK: - Day Eval Outside

private func fillStoredDayEval(_ base: inout StoredDayEval) {
    base.value = Double(base.dayResult) / base.goal.getAsDaily(forDate: base.day)
}

// MARK: - Total Eval Outside

private func fillStoredEval(_ base: inout StoredEval, _ dayResults: [DateComponents: UInt]) {
    let (totalGoal, beforeStart) = getExpectedOutside(base.from, base.to, base.goal, dayResults, base.firstDay)
    
    guard let totalGoal else {
        logger().error("Couldn't calculate goal. Returning Evaluation 0")
        return
    }
    
    let total = getTotalOutside(beforeStart, base.to, dayResults, base.dayDefault)
    
    base.value = Double(total) / totalGoal
}

// MARK: - Future Eval Outside

private func fillStoredPrediction(_ base: inout StoredPrediction, _ dayResults: [DateComponents: UInt]) {
    var resultYellow = DateComponents?(nil)
    var resultGreen = DateComponents?(nil)
    
    let start = base.start
    let referenceDate = base.referenceDate
    let goal = base.goal
    let limit = base.limit
    let yellowRatio = base.yellowRatio
    let dayDefault = base.dayDefault
    let firstDay = base.firstDay
    
    guard var (beforeStart, fdEffect) = getDayBeforeEvalStartOutside(start, referenceDate, dayResults, firstDay) else { return }
    var currentEndDate = referenceDate
    
    var currentTotal = getTotalOutside(beforeStart, currentEndDate, dayResults, dayDefault)
    
    // Today should also be set to at least completions
    var completions = UInt(goal.getAsDaily(forDate: currentEndDate).rounded(.up))
    if let lim = limit, lim < completions {
        completions = lim
    }
    
    let actualValueToday = getDayOutside(referenceDate, dayResults, dayDefault)
    if completions > actualValueToday {
        currentTotal -= actualValueToday
        currentTotal += completions
    }
    
    outer: while beforeStart < referenceDate {
        // Evaluation of the current date
        guard let encompassedGoalPeriods = getProportionOfGoalPeriod(beforeStart, currentEndDate, start, fdEffect, base.goal) else { break }
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
            guard let (next, nextFDEffect) = getDayBeforeEvalStartOutside(start, currentEndDate, dayResults, firstDay) else { break }
            beforeStart = next
            fdEffect = nextFDEffect
        } else {
            guard let next = getBeforeStartRaw(start, currentEndDate) else { break }
            beforeStart = next
        }
        
        // beforeStart might jump various distances >= 0 so we need to sum all the completions that fell out
        var fellOut = UInt(0)
        
        while bsIter < beforeStart {
            guard let next = bsIter.addingDays(1) else { break outer }
            bsIter = next
            
            fellOut += getDayOutside(bsIter, dayResults, dayDefault)
        }
        
        var completions = UInt(goal.getAsDaily(forDate: currentEndDate).rounded(.up))
        if let lim = limit, lim < completions {
            completions = lim
        }
        
        let newIn = max(getDayOutside(currentEndDate, dayResults, dayDefault), completions)
        
        currentTotal -= fellOut
        currentTotal += newIn
    }
    
    base.value = (resultYellow, resultGreen)
}

// MARK: - Expected Outside

private func getExpectedOutside(_ from: CalculationStart, _ to: DateComponents, _ goal: CompletionGoal,
                                _ dayResults: [DateComponents: UInt], _ firstDay: DateComponents) -> (Double?, DateComponents)
{
    guard let (beforeStart, fdEffect) = getDayBeforeEvalStartOutside(from, to, dayResults, firstDay) else { return (0, .now) }
    
    guard let encompassedGoalPeriods = getProportionOfGoalPeriod(beforeStart, to, from, fdEffect, goal)
    else { return (nil, beforeStart) }
    
    return (Double(goal.getNumber()) * encompassedGoalPeriods, beforeStart)
}

// MARK: - Total Outside

private func getTotalOutside(_ beforeStart: DateComponents, _ to: DateComponents, _ dayResults: [DateComponents: UInt], _ dayDefault: UInt) -> UInt {
    let filteredDays = dayResults.filter { $0.key > beforeStart && $0.key <= to }
    let count = filteredDays.count
    let directlySetValue = filteredDays.reduce(0) { $0 + UInt($1.value) }
    let totalDays = to.daysSince(beforeStart) ?? 0
    
    return directlySetValue + UInt(clamping: totalDays - count) * dayDefault
}

private func getTotalOutside(_ from: CalculationStart, _ to: DateComponents,
                             _ dayResults: [DateComponents: UInt], _ dayDefault: UInt, _ firstDay: DateComponents) -> UInt
{
    guard let (beforeStart, _) = getDayBeforeEvalStartOutside(from, to, dayResults, firstDay) else { return 0 }
    
    return getTotalOutside(beforeStart, to, dayResults, dayDefault)
}

// MARK: - Helpers Outside

/// Returns the day before the eval start, does NOT account for first day
private func getBeforeStartRaw(_ from: CalculationStart, _ to: DateComponents) -> DateComponents? {
    guard let lastDate = to.asDate,
          let beforeStart = Calendar.current.date(byAdding: from.getAsDateComponents(), to: lastDate)?.dc else { return nil }
    
    return beforeStart
}

/// Returns the day before the evaluation in question starts and a flag indicating if this was changed by the calculated first day
private func getDayBeforeEvalStartOutside(_ from: CalculationStart, _ to: DateComponents,
                                          _ dayResults: [DateComponents: UInt], _ firstDay: DateComponents) -> (DateComponents, Bool)?
{
    guard let beforeStart = getBeforeStartRaw(from, to),
          let beforeFirst = firstDay.addingDays(-1) else { return nil }
    
    if beforeFirst > beforeStart {
        return (beforeFirst, true)
    } else {
        return (beforeStart, false)
    }
}

private func getProportionOfGoalPeriod(_ beforeStart: DateComponents, _ to: DateComponents, _ calcPeriod: CalculationStart,
                                       _ influencedByFirstDay: Bool, _ goal: CompletionGoal) -> Double?
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
