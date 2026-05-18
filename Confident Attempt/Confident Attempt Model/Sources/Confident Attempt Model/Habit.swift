import Foundation
import SwiftData

public enum HabitsSchemaV2: VersionedSchema {
    public static let versionIdentifier = Schema.Version(2, 0, 0)

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

        private var firstDayData: Data = Data()

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

        fileprivate init(name: String, textDescription: String, symbol: String?, repetition: UInt?,
                         goal: CompletionGoal, dayResults: [DateComponents: UInt], firstDay: DateComponents)
        {
            self.name = name
            self.textDescription = textDescription
            self.repetition = repetition
            self.goal = goal
            self.symbol = symbol
            self.dayResults = dayResults
            self.firstDay = firstDay
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
                setFirstDay()
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

extension HabitsSchemaV2.Habit: Codable {
    public convenience init?(name: String, textDescription: String, symbol: String? = nil, repetition: UInt? = 1,
                             goal: CompletionGoal = .daily(number: 1), firstDay: DateComponents)
    {
        if !Self.testValues(repetition: repetition, goal: goal) {
            return nil
        }

        self.init(name: name, textDescription: textDescription, symbol: symbol, repetition: repetition,
                  goal: goal, dayResults: [:], firstDay: firstDay)
    }

    public convenience init(cloneof from: HabitsSchemaV2.Habit, newName: String, copyData: Bool) {
        let dayResults = if copyData {
            from.dayResults
        } else {
            [DateComponents: UInt]()
        }

        self.init(name: newName, textDescription: from.textDescription, symbol: from.symbol,
                  repetition: from.repetition, goal: from.goal, dayResults: dayResults, firstDay: from.firstDay)
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

    func setFirstDay() {
        if let fromData = dayResults.map({ $0.key }).sorted().first {
            firstDay = fromData
        } else {
            firstDay = .now
        }
    }

    public var calculatedFirstDay: DateComponents {
        if let fromData = dayResults.map({ $0.key }).sorted().first {
            return min(fromData, firstDay)
        } else {
            return firstDay
        }
    }

    public func getDay(_ day: DateComponents = .now) -> UInt {
        return dayResults[day] ?? 0
    }

    public func setDay(_ day: DateComponents, to: UInt) {
        switch repetition {
        case let .some(repetition) where to > repetition:
            dayResults[day] = repetition
        default:
            dayResults[day] = to
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

    public func getTotal(from: CalculationStart, to: DateComponents) -> UInt {
        guard let lastDate = to.asDate,
              let beforeFirst = calculatedFirstDay.addingDays(-1),
              var beforeStart = Calendar.current.date(byAdding: from.getAsDateComponents(), to: lastDate)?.dc else { return 0 }

        beforeStart = max(beforeFirst, beforeStart)

        return dayResults.filter { $0.key > beforeStart && $0.key <= to }.reduce(0) { $0 + UInt($1.value) }
    }

    public func getEvaluation(from: CalculationStart, to: DateComponents) -> Double {
        guard let lastDate = to.asDate,
              let beforeFirst = calculatedFirstDay.addingDays(-1),
              var beforeStart = Calendar.current.date(byAdding: from.getAsDateComponents(), to: lastDate)?.dc else { return 0 }

        beforeStart = max(beforeFirst, beforeStart)

        let totalEvaluation = dayResults.filter { $0.key > beforeStart && $0.key <= to }.reduce(0) { $0 + getEvaluationForDay($1.key) }

        let totalDays = to.daysSince(beforeStart)
        guard let totalDays, totalDays > 0 else { return 0 }

        return totalEvaluation / Double(totalDays)
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
