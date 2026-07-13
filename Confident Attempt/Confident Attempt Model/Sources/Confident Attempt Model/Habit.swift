import Foundation
import OSLog
import SwiftData

public enum HabitsSchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)

    public static var models: [any PersistentModel.Type] {
        [Habit.self]
    }

    @Model
    public class Habit {
        public var name: String = ""
        public var textDescription: String = ""
        public var symbol: String?
        public private(set) var limit: UInt?
        public private(set) var goal: CompletionGoal = CompletionGoal.daily(number: 1)

        fileprivate var dayResultsInternal: Data = Data()

        private var dayDefaultInternal: UInt?

        private var firstDayData: Data = Data()
        
        
        @Transient
        private var dayResultsCache: [DateComponents: UInt] = [:]
        @Transient
        private var dayResultsHash: Int = 0

        @Transient
        var storedEval: StoredEval? = nil
        @Transient
        var storedDayEval: StoredDayEval? = nil
        @Transient
        var storedPrediction: StoredPrediction? = nil

        fileprivate init(name: String, textDescription: String, symbol: String?, limit: UInt?, goal: CompletionGoal,
                         dayResults: [DateComponents: UInt], firstDay: DateComponents, dayDefault: UInt)
        {
            self.name = name
            self.textDescription = textDescription
            self.limit = limit
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
            limit = if let loadedLimit = try? container.decode(UInt?.self, forKey: .limit) {
                loadedLimit
            } else {
                try container.decode(UInt?.self, forKey: .repetition)
            }
            goal = try container.decode(CompletionGoal.self, forKey: .goal)
            dayResults = try container.decode([DateComponents: UInt].self, forKey: .dayResults)
            if let firstDay = try? container.decode(DateComponents.self, forKey: .firstDay) {
                self.firstDay = firstDay
            } else {
                logger().info("Manually creating first day since it isn't included in the decoder.")
                setFirstDay()
            }
            dayDefault = try container.decode(UInt.self, forKey: .dayDefault)
        }

        public internal(set) var dayResults: [DateComponents: UInt] {
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
                } catch {
                    logger().error("Couldn't encode first day: \(error)")
                }
            }
        }

        func setFirstDay() {
            if let fromData = dayResults.filter({ $0.value > 0 }).map({ $0.key }).sorted().first {
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
                if let limit,
                   limit < newValue
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
    case limit
    case goal
    case dayResults
    case firstDay
    case dayDefault
}

extension Habit: Codable {
    public convenience init?(name: String, textDescription: String, symbol: String? = nil, limit: UInt? = 1,
                             goal: CompletionGoal = .daily(number: 1), firstDay: DateComponents, dayDefault: UInt = 0)
    {
        if !Self.testValues(limit: limit, goal: goal) {
            logger().info("Habit with limit \(String(describing: limit)) and goal \(String(describing: goal)) won't be created!")
            return nil
        }

        self.init(name: name, textDescription: textDescription, symbol: symbol, limit: limit,
                  goal: goal, dayResults: [:], firstDay: firstDay, dayDefault: dayDefault)
    }

    public convenience init(cloneof from: Habit, newName: String, copyData: Bool, firstDay: DateComponents) {
        let (dayResults, firstDay) = if copyData {
            (from.dayResults, from.firstDay)
        } else {
            ([DateComponents: UInt](), firstDay)
        }

        self.init(name: newName, textDescription: from.textDescription, symbol: from.symbol, limit: from.limit,
                  goal: from.goal, dayResults: dayResults, firstDay: firstDay, dayDefault: from.dayDefault)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: HabitCodingKeys.self)

        try container.encode(name, forKey: .name)
        try container.encode(textDescription, forKey: .textDescription)
        try container.encode(symbol, forKey: .symbol)
        try container.encode(limit, forKey: .limit)
        try container.encode(goal, forKey: .goal)
        try container.encode(dayResults, forKey: .dayResults)
        try container.encode(firstDay, forKey: .firstDay)
        try container.encode(dayDefault, forKey: .dayDefault)
    }

    public static func testValues(limit: UInt?, goal: CompletionGoal) -> Bool {
        guard goal.getNumber() > 0 else { return false }

        if let limit {
            guard limit > 0 else { return false }

            if let daily = goal.getAsDailyAlways(), daily > Double(limit) {
                return false
            }
        }

        return true
    }

    public func setLimitAndGoal(lim limit: UInt?, goal: CompletionGoal) {
        guard Self.testValues(limit: limit, goal: goal) else { return }
        if let limit,
           self.limit == nil || self.limit ?? 0 > limit
        {
            dayResults = dayResults.mapValues { value in
                min(value, limit)
            }
        }

        self.limit = limit
        self.goal = goal
    }

    /// Returns the number of days which would need to be lowered to confine to the proposed limit
    public func checkNewLimit(_ limit: UInt) -> UInt {
        if let oldLim = self.limit,
           limit >= oldLim
        {
            return 0
        }

        let days = dayResults.filter { $0.value > limit }.count
        return UInt(days)
    }

    public func getDay(_ day: DateComponents = .now) -> UInt {
        getDayOutside(day, dayResults, dayDefault)
    }

    public func setDay(_ day: DateComponents, to: UInt) {
        switch limit {
        case let .some(limit) where to > limit:
            logger().info("New day value of \(to) is bigger than maximum value (\(limit)), so this is the new value set.")
            dayResults[day.cleaned] = limit
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
}

func getDayOutside(_ day: DateComponents, _ dayResults: [DateComponents: UInt], _ dayDefault: UInt) -> UInt {
    return dayResults[day.cleaned] ?? dayDefault
}
