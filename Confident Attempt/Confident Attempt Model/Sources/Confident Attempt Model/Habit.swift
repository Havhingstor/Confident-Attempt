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
        public private(set) var limit: UInt?
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
        var storedEval: StoredEval? = nil
        @Transient
        var storedDayEval: StoredDayEval? = nil
        @Transient
        var storedPrediction: StoredPrediction? = nil
        
        @Transient
        private var firstDayHash: Int = 0

        fileprivate init(name: String, textDescription: String, symbol: String?, limit: UInt?, goal: CompletionGoal,
                         dayResults: [DateComponents: UInt], firstDay: DateComponents, dayDefault: UInt)
        {
            self.name = name
            self.textDescription = textDescription
            self.limit = limit
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
            limit = try container.decode(UInt?.self, forKey: .limit)
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
                        resetStoredEvalsAndDay()
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

                resetStoredEvalsAndDay()
            }
        }

        private func resetStoredEvals(forDay: DateComponents?) {
            storedEval = nil
            storedPrediction = nil

            if let storedDayEval,
               let forDay,
               storedDayEval.day.cleanEq(forDay)
            {
                self.storedDayEval = nil
            }
        }

        private func resetStoredEvalsAndDay() {
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
            (from.newDayResults, from.firstDay)
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
        try container.encode(newDayResults, forKey: .dayResults)
        try container.encode(firstDay, forKey: .firstDay)
        try container.encode(dayDefault, forKey: .dayDefault)
    }
    
    /// Should be manually called with onChange for first day if this value can be set from the outside (like iCloud)
    public func resetForFirstDay() {
        resetStoredEvals(forDay: nil)
    }
    
    /// Should be manually called with onChange for day default if this value can be set from the outside (like iCloud)
    public func resetForDayDefault() {
        resetStoredEvalsAndDay()
    }
    
    /// Should be manually called with onChange for limit / goal if this value can be set from the outside (like iCloud)
    public func resetForLimGoal() {
        resetStoredEvalsAndDay()
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
            newDayResults = newDayResults.mapValues { value in
                min(value, limit)
            }
        }

        self.limit = limit
        self.goal = goal

        resetStoredEvalsAndDay()
    }

    /// Returns the number of days which would need to be lowered to confine to the proposed limit
    public func checkNewLimit(_ limit: UInt) -> UInt {
        if let oldLim = self.limit,
           limit >= oldLim
        {
            return 0
        }

        let days = newDayResults.filter { $0.value > limit }.count
        return UInt(days)
    }

    public func getDay(_ day: DateComponents = .now) -> UInt {
        return newDayResults[day.cleaned] ?? dayDefault
    }

    public func setDay(_ day: DateComponents, to: UInt) {
        switch limit {
        case let .some(limit) where to > limit:
            logger().info("New day value of \(to) is bigger than maximum value (\(limit)), so this is the new value set.")
            newDayResults[day.cleaned] = limit
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
}
