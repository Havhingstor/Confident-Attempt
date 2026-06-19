import Foundation
import OSLog
import SwiftData

public enum HabitsSchemaV4: VersionedSchema {
    public static let versionIdentifier = Schema.Version(4, 0, 0)

    public static var models: [any PersistentModel.Type] {
        [Habit.self]
    }

    @Model
    public class Habit {
        public var name: String = ""
        public var textDescription: String = ""
        public var symbol: String?
        public private(set) var repetition: UInt?
        public private(set) var goal: CompletionGoal = CompletionGoal.daily(number: 1)

        // TODO: Remove in next version
        fileprivate var dayResults: [DateComponents: UInt]? = [:]

        fileprivate var dayResultsInternal: Data = Data()
        @Transient
        private var dayResultsCache: [DateComponents: UInt] = [:]
        @Transient
        private var dayResultsHash: Int = 0

        private var dayDefaultInternal: UInt?

        private var firstDayData: Data = Data()

        @Transient
        private var storedEval: StoredEval? = nil
        @Transient
        private var storedDayEval: StoredDayEval? = nil
        @Transient
        private var storedPrediction: StoredPrediction? = nil

        fileprivate init(name: String, textDescription: String, symbol: String?, repetition: UInt?, goal: CompletionGoal,
                         dayResults: [DateComponents: UInt], firstDay: DateComponents, dayDefault: UInt)
        {
            self.name = name
            self.textDescription = textDescription
            self.repetition = repetition
            self.goal = goal
            self.symbol = symbol
            newDayResults = dayResults
            self.firstDay = firstDay
            self.dayDefault = dayDefault
        }

        public required init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: HabitCodingKeys.self)

            name = try container.decode(String.self, forKey: .name)
            textDescription = try container.decode(String.self, forKey: .textDescription)
            symbol = try container.decode(String?.self, forKey: .symbol)
            repetition = try container.decode(UInt?.self, forKey: .repetition)
            goal = try container.decode(CompletionGoal.self, forKey: .goal)
            newDayResults = try container.decode([DateComponents: UInt].self, forKey: .dayResults)
            if let firstDay = try? container.decode(DateComponents.self, forKey: .firstDay) {
                self.firstDay = firstDay
            } else {
                logger().info("Manually creating first day since it isn't included in the decoder.")
                setFirstDay()
            }
            dayDefault = try container.decode(UInt.self, forKey: .dayDefault)
        }

        // TODO: Later Version (5 / 6): rename to dayResults
        public internal(set) var newDayResults: [DateComponents: UInt] {
            get {
                if dayResultsInternal.hashValue != dayResultsHash {
                    do {
                        dayResultsCache = try JSONDecoder().decode([DateComponents: UInt].self, from: dayResultsInternal)
                        dayResultsHash = dayResultsInternal.hashValue
                    } catch {
                        logger().error("Couldn't decode day results: \(error)")
                    }
                }
                return dayResultsCache
            }
            set {
                do {
                    dayResultsCache = newValue
                    dayResultsInternal = try JSONEncoder().encode(dayResultsCache)
                    dayResultsHash = dayResultsInternal.hashValue
                } catch {
                    logger().error("Couldn't encode day results: \(error)")
                }
            }
        }

        public internal(set) var firstDay: DateComponents {
            get {
                if let result = try? JSONDecoder().decode(DateComponents.self, from: firstDayData) {
                    return result
                }

                setFirstDay()

                do {
                    return try JSONDecoder().decode(DateComponents.self, from: firstDayData)
                } catch {
                    logger().error("Couldn't decode first day: \(error)")
                    return .now
                }
            }
            set {
                do {
                    firstDayData = try JSONEncoder().encode(newValue)
                    resetStoredEvals(forDay: nil)
                } catch {
                    logger().error("Couldn't encode first day: \(error)")
                }
            }
        }

        func setFirstDay() {
            if let fromData = newDayResults.filter({ $0.value > 0 }).map({ $0.key }).sorted().first {
                firstDay = fromData
            } else {
                logger().info("No completions set for any days, first day is set to today.")
                firstDay = .now
            }
        }

        public var dayDefault: UInt {
            get {
                dayDefaultInternal ?? 0
            }
            set {
                if let repetition,
                   repetition < newValue
                {
                    logger().warning("Won't set new day default: higher than daily maximum!")
                    return
                }

                dayDefaultInternal = if newValue == 0 {
                    nil
                } else {
                    newValue
                }

                resetStoredEvalsAndDay()
            }
        }

        private func resetStoredEvals(forDay: DateComponents?) {
            storedEval = nil
            storedPrediction = nil
            
            if let storedDayEval,
               let forDay,
               storedDayEval.day.cleanEq(forDay) {
                self.storedDayEval = nil
            }
        }
        
        private func resetStoredEvalsAndDay(){
            resetStoredEvals(forDay: nil)
            storedDayEval = nil
        }

        func moveDayResults() {
            guard let dayResults, newDayResults.count == 0 else { return }

            newDayResults = dayResults
            self.dayResults = nil
        }
    }
}

private enum HabitCodingKeys: CodingKey {
    case name
    case textDescription
    case symbol
    case repetition
    case goal
    case dayResults
    case firstDay
    case dayDefault
}

extension Habit: Codable {
    public convenience init?(name: String, textDescription: String, symbol: String? = nil, repetition: UInt? = 1,
                             goal: CompletionGoal = .daily(number: 1), firstDay: DateComponents, dayDefault: UInt = 0)
    {
        if !Self.testValues(repetition: repetition, goal: goal) {
            logger().info("Habit with repetition \(String(describing: repetition)) and goal \(String(describing: goal)) won't be created!")
            return nil
        }

        self.init(name: name, textDescription: textDescription, symbol: symbol, repetition: repetition,
                  goal: goal, dayResults: [:], firstDay: firstDay, dayDefault: dayDefault)
    }

    public convenience init(cloneof from: Habit, newName: String, copyData: Bool, firstDay: DateComponents) {
        let (dayResults, firstDay) = if copyData {
            (from.newDayResults, from.firstDay)
        } else {
            ([DateComponents: UInt](), firstDay)
        }

        self.init(name: newName, textDescription: from.textDescription, symbol: from.symbol, repetition: from.repetition,
                  goal: from.goal, dayResults: dayResults, firstDay: firstDay, dayDefault: from.dayDefault)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: HabitCodingKeys.self)

        try container.encode(name, forKey: .name)
        try container.encode(textDescription, forKey: .textDescription)
        try container.encode(symbol, forKey: .symbol)
        try container.encode(repetition, forKey: .repetition)
        try container.encode(goal, forKey: .goal)
        try container.encode(newDayResults, forKey: .dayResults)
        try container.encode(firstDay, forKey: .firstDay)
        try container.encode(dayDefault, forKey: .dayDefault)
    }

    public static func testValues(repetition: UInt?, goal: CompletionGoal) -> Bool {
        guard goal.getNumber() > 0 else { return false }

        if let repetition {
            guard repetition > 0 else { return false }

            if let daily = goal.getAsDailyAlways(), daily > Double(repetition) {
                return false
            }
        }

        return true
    }

    public var calculatedFirstDay: DateComponents {
        if let fromData = newDayResults.filter({ $0.value > 0 }).map({ $0.key }).sorted().first {
            return min(fromData, firstDay)
        } else {
            return firstDay
        }
    }

    public func getDay(_ day: DateComponents = .now) -> UInt {
        return newDayResults[day.cleaned] ?? dayDefault
    }

    public func setDay(_ day: DateComponents, to: UInt) {
        switch repetition {
        case let .some(repetition) where to > repetition:
            logger().info("New day value of \(to) is bigger than maximum value (\(repetition)), so this is the new value set.")
            newDayResults[day.cleaned] = repetition
        default:
            newDayResults[day.cleaned] = to
        }

        resetStoredEvals(forDay: day)
    }

    public func increaseDay(_ day: DateComponents, by: UInt) {
        let newVal = getDay(day).addWithoutOverflow(by)
        setDay(day, to: newVal)
    }

    public func decreaseDay(_ day: DateComponents, by: UInt) {
        let newVal = getDay(day).subWithoutOverflow(by)

        setDay(day, to: newVal)
    }

    private func getDayEvalIfUsable(day: DateComponents) -> Double? {
        guard let storedDayEval else { return nil }

        if storedDayEval.day.cleanEq(day) {
            return storedDayEval.value
        } else {
            return nil
        }
    }

    public func getEvaluationForDay(_ day: DateComponents) -> Double {
        if let eval = getDayEvalIfUsable(day: day) {
            return eval
        }
        let result = Double(getDay(day)) / goal.getAsDaily(forDate: day)
        storedDayEval = StoredDayEval(day: day, value: result)
        return result
    }

    /// Returns the day before the evaluation in question starts and a flag indicating if this was changed by the calculated first day
    public func getDayBeforeEvalStart(from: CalculationStart, to: DateComponents) -> (DateComponents, Bool)? {
        guard let beforeStart = getBeforeStartRaw(from: from, to: to),
              let beforeFirst = calculatedFirstDay.addingDays(-1) else { return nil }

        if beforeFirst > beforeStart {
            return (beforeFirst, true)
        } else {
            return (beforeStart, false)
        }
    }
    
    /// Returns the day before the eval start, does NOT account for first day
    private func getBeforeStartRaw(from: CalculationStart, to: DateComponents) -> DateComponents? {
        guard let lastDate = to.asDate,
              let beforeStart = Calendar.current.date(byAdding: from.getAsDateComponents(), to: lastDate)?.dc else { return nil }
        
        return beforeStart
    }

    private func getTotal(beforeStart: DateComponents, to: DateComponents) -> UInt {
        let filteredDays = newDayResults.filter { $0.key > beforeStart && $0.key <= to }
        let count = filteredDays.count
        let directlySetValue = filteredDays.reduce(0) { $0 + UInt($1.value) }
        let totalDays = to.daysSince(beforeStart) ?? 0

        return directlySetValue + UInt(clamping: totalDays - count) * dayDefault
    }

    public func getTotal(from: CalculationStart, to: DateComponents) -> UInt {
        guard let (beforeStart, _) = getDayBeforeEvalStart(from: from, to: to) else { return 0 }

        return getTotal(beforeStart: beforeStart, to: to)
    }
    
    public func getExpected(from: CalculationStart, to: DateComponents) -> Double {
        getExpectedInternal(from: from, to: to).0 ?? 0
    }
    
    private func getExpectedInternal(from: CalculationStart, to: DateComponents) -> (Double?, DateComponents) {
        guard let (beforeStart, fdEffect) = getDayBeforeEvalStart(from: from, to: to) else { return (0, .now) }
        
        guard let encompassedGoalPeriods = getProportionOfGoalPeriod(beforeStart: beforeStart, to: to, from: from, fdEffect: fdEffect) else {return (nil, beforeStart)}
        
        return (Double(goal.getNumber()) * encompassedGoalPeriods, beforeStart)
    }

    private func getEvalIfUsable(from: CalculationStart, to: DateComponents) -> Double? {
        guard let storedEval else { return nil }

        if storedEval.from == from, storedEval.to.cleanEq(to) {
            return storedEval.value
        } else {
            return nil
        }
    }

    public func getEvaluation(from: CalculationStart, to: DateComponents) -> Double {
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
    
    /// Calculates the days the user reaches yellow (first value) or green (second value) status if they complete the habit at the minimum number evaluating over 1
    /// Value is nil if the goal can't be reached or is already reached
    public func calculateFutureEvals(referenceDate: DateComponents, start: CalculationStart, yellowRatio: Double) -> (yellow: DateComponents?, green: DateComponents?) {
        if let storedPrediction,
           storedPrediction.referenceDate == referenceDate,
           storedPrediction.start == start,
           storedPrediction.yellowRatio == yellowRatio {
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
            guard let encompassedGoalPeriods = getProportionOfGoalPeriod(beforeStart: beforeStart, to: currentEndDate, from: start, fdEffect: fdEffect) else {break}
            let actualGoal = Double(goal.getNumber()) * encompassedGoalPeriods
            
            let ratioToday = Double(currentTotal) / actualGoal
            
            if resultYellow == nil && ratioToday >= yellowRatio {
                resultYellow = currentEndDate
            }
            
            if resultGreen == nil && ratioToday >= 1.0 {
                resultGreen = currentEndDate
            }
            
            if resultYellow != nil && resultGreen != nil {
                break
            }
            
            // Calculation of the next date
            
            guard let nextEndDate = currentEndDate.addingDays(1) else {break}
            currentEndDate = nextEndDate
            
            var bsIter = beforeStart
            if fdEffect {
                guard let (next, nextFDEffect) = getDayBeforeEvalStart(from: start, to: currentEndDate) else {break}
                beforeStart = next
                fdEffect = nextFDEffect
            } else {
                guard let next = getBeforeStartRaw(from: start, to: currentEndDate) else {break}
                beforeStart = next
            }
            
            // beforeStart might jump various distances >= 0 so we need to sum all the completions that fell out
            var fellOut = UInt(0)
            
            while bsIter < beforeStart {
                guard let next = bsIter.addingDays(1) else {break outer}
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

    private func getProportionOfGoalPeriod(beforeStart: DateComponents, to: DateComponents,
                                           from calcPeriod: CalculationStart, fdEffect influencedByFirstDay: Bool) -> Double?
    {
        if !influencedByFirstDay && calcPeriod.typeEq(rhs: goal) {
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

    public func setRepetitionAndGoal(rep repetition: UInt?, goal: CompletionGoal) {
        guard Self.testValues(repetition: repetition, goal: goal) else { return }
        if let repetition,
           self.repetition == nil || self.repetition ?? 0 > repetition
        {
            newDayResults = newDayResults.mapValues { value in
                min(value, repetition)
            }
        }

        self.repetition = repetition
        self.goal = goal

        resetStoredEvalsAndDay()
    }

    /// Returns the number of days which would need to be lowered to confine to the proposed repetition
    public func checkNewRepetition(_ repetition: UInt) -> UInt {
        if let oldRep = self.repetition,
           repetition >= oldRep
        {
            return 0
        }

        let days = newDayResults.filter { $0.value > repetition }.count
        return UInt(days)
    }
}
