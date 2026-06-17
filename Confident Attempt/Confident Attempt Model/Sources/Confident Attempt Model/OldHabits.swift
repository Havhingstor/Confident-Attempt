import Foundation
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
        public var repetition: UInt?
        public var goal: CompletionGoal = CompletionGoal.daily(number: 1)
        public var dayResults: [DateComponents: UInt] = [:]

        public init(name: String, textDescription: String, symbol: String?,
                    repetition: UInt?, goal: CompletionGoal, dayResults: [DateComponents: UInt])
        {
            self.name = name
            self.textDescription = textDescription
            self.repetition = repetition
            self.goal = goal
            self.symbol = symbol
            self.dayResults = dayResults
        }
    }
}

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
        public var dayResults: [DateComponents: UInt] = [:]

        private var firstDayData: Data = Data()

        public init(name: String, textDescription: String, symbol: String?, repetition: UInt?,
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

        public func setFirstDay() {
            if let fromData = dayResults.map({ $0.key }).sorted().first {
                firstDay = fromData
            } else {
                logger().info("No completions set for any days, first day is set to today.")
                firstDay = .now
            }
        }
    }
}

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

        @Transient
        private var storedEval: StoredEval? = nil
        @Transient
        private var storedDayEval: StoredDayEval? = nil

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
                storedEval = nil
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

                resetStoredEvals()
            }
        }

        private func resetStoredEvals() {
            storedEval = nil
            storedDayEval = nil
        }
    }
}
