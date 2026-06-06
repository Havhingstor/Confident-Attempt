import Foundation
import OSLog
import SwiftData

public enum HabitsSchemaV3: VersionedSchema {
    public static let versionIdentifier = Schema.Version(3, 0, 0)

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
        fileprivate var dayResults: [DateComponents: UInt] = [:]
        private var dayDefaultInternal: UInt?

        private var firstDayData: Data = Data()

        fileprivate init(name: String, textDescription: String, symbol: String?, repetition: UInt?, goal: CompletionGoal,
                         dayResults: [DateComponents: UInt], firstDay: DateComponents, dayDefault: UInt)
        {
            self.name = name
            self.textDescription = textDescription
            self.repetition = repetition
            self.goal = goal
            self.symbol = symbol
            self.dayResults = dayResults
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
            dayResults = try container.decode([DateComponents: UInt].self, forKey: .dayResults)
            if let firstDay = try? container.decode(DateComponents.self, forKey: .firstDay) {
                self.firstDay = firstDay
            } else {
                logger().info("Manually creating first day since it isn't included in the decoder.")
                setFirstDay()
            }
        }

        public internal(set) var firstDay: DateComponents {
            get {
                if let result = try? JSONDecoder().decode(DateComponents.self, from: firstDayData) {
                    return result
                }

                setFirstDay()

                return (try? JSONDecoder().decode(DateComponents.self, from: firstDayData)) ?? .now
            }
            set {
                firstDayData = (try? JSONEncoder().encode(newValue)) ?? Data()
            }
        }

        func setFirstDay() {
            if let fromData = dayResults.map({ $0.key }).sorted().first {
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
            }
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
            (from.dayResults, from.firstDay)
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
        try container.encode(dayResults, forKey: .dayResults)
        try container.encode(firstDay, forKey: .firstDay)
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
        if let fromData = dayResults.map({ $0.key }).sorted().first {
            return min(fromData, firstDay)
        } else {
            return firstDay
        }
    }

    public func getDay(_ day: DateComponents = .now) -> UInt {
        return dayResults[day.cleaned] ?? dayDefault
    }

    public func setDay(_ day: DateComponents, to: UInt) {
        switch repetition {
        case let .some(repetition) where to > repetition:
            logger().info("New day value of \(to) is bigger than maximum value (\(repetition)), so this is the new value set.")
            dayResults[day.cleaned] = repetition
        default:
            dayResults[day.cleaned] = to
        }
    }

    public func increaseDay(_ day: DateComponents, by: UInt) {
        let newVal = getDay(day).addWithoutOverflow(by)
        setDay(day, to: newVal)
    }

    public func decreaseDay(_ day: DateComponents, by: UInt) {
        let newVal = getDay(day).subWithoutOverflow(by)

        setDay(day, to: newVal)
    }

    public func getEvaluationForDay(_ day: DateComponents) -> Double {
        return Double(getDay(day)) / goal.getAsDaily(forDate: day)
    }

    /// Returns the day before the evaluation in question starts and a flag indicating if this was changed by the calculated first day
    public func getDayBeforeEvalStart(from: CalculationStart, to: DateComponents) -> (DateComponents, Bool)? {
        guard let lastDate = to.asDate,
              let beforeFirst = calculatedFirstDay.addingDays(-1),
              let beforeStart = Calendar.current.date(byAdding: from.getAsDateComponents(), to: lastDate)?.dc else { return nil }

        if beforeFirst > beforeStart {
            return (beforeFirst, true)
        } else {
            return (beforeStart, false)
        }
    }

    private func getTotal(beforeStart: DateComponents, to: DateComponents) -> UInt {
        let filteredDays = dayResults.filter { $0.key > beforeStart && $0.key <= to }
        let count = filteredDays.count
        let directlySetValue = filteredDays.reduce(0) { $0 + UInt($1.value) }
        let totalDays = to.daysSince(beforeStart) ?? 0

        return directlySetValue + UInt(clamping: totalDays - count) * dayDefault
    }

    public func getTotal(from: CalculationStart, to: DateComponents) -> UInt {
        guard let (beforeStart, _) = getDayBeforeEvalStart(from: from, to: to) else { return 0 }

        return getTotal(beforeStart: beforeStart, to: to)
    }

    public func getEvaluation(from: CalculationStart, to: DateComponents) -> Double {
        guard let (beforeStart, fdEffect) = getDayBeforeEvalStart(from: from, to: to) else { return 0 }

        let encompassedGoalPeriods = getProportionOfGoalPeriod(beforeStart: beforeStart, to: to, from: from, fdEffect: fdEffect)

        let totalGoal = Double(goal.getNumber()) * encompassedGoalPeriods

        guard totalGoal > 0 else {
            logger().error("Couldn't calculate goal. Returning Evaluation 0")
            return 0
        }

        let total = getTotal(beforeStart: beforeStart, to: to)

        return Double(total) / totalGoal
    }

    private func getProportionOfGoalPeriod(beforeStart: DateComponents, to: DateComponents,
                                           from calcPeriod: CalculationStart, fdEffect influencedByFirstDay: Bool) -> Double
    {
        if !influencedByFirstDay && calcPeriod.typeEq(rhs: goal) {
            return Double(calcPeriod.getNumber())
        }

        guard var totalRemainingDays = to.daysSince(beforeStart) else {
            logger().error("Can't calculate the days between \(to) and \(beforeStart)")
            return 0
        }
        guard var currentStartDate = to.asDate else {
            logger().error("Can't convert \(to) to a date")
            return 0
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
                return 0
            }
            guard let daysInPeriod = currentStartDate.dc.daysSince(nextStartDate.dc) else {
                logger().error("Can't calculate the number of days between \(currentStartDate) and \(nextStartDate)")
                return 0
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
            dayResults = dayResults.mapValues { value in
                min(value, repetition)
            }
        }

        self.repetition = repetition
        self.goal = goal
    }

    /// Returns the number of days which would need to be lowered to confine to the proposed repetition
    public func checkNewRepetition(_ repetition: UInt) -> UInt {
        if let oldRep = self.repetition,
           repetition >= oldRep
        {
            return 0
        }

        let days = dayResults.filter { $0.value > repetition }.count
        return UInt(days)
    }
}
