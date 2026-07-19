import Foundation

public enum CompletionGoal: Codable, Equatable {
    case daily(number: UInt)
    case weekly(number: UInt)
    case monthly(number: UInt)
    case yearly(number: UInt)

    public func getAsDaily(forDate: DateComponents) -> Double {
        switch self {
        case let .daily(number):
            Double(number)
        case let .weekly(number):
            Double(number) / 7.0
        case let .monthly(number):
            Double(number) / Double(forDate.daysInMonth())
        case let .yearly(number):
            Double(number) / Double(forDate.daysInYear())
        }
    }

    public func getAsDailyAlways() -> Double? {
        switch self {
        case let .daily(number):
            Double(number)
        case let .weekly(number):
            Double(number) / 7.0
        case .monthly:
            nil
        case .yearly:
            nil
        }
    }

    public func getNumber() -> UInt {
        switch self {
        case let .daily(number):
            number
        case let .weekly(number):
            number
        case let .monthly(number):
            number
        case let .yearly(number):
            number
        }
    }

    public mutating func setNumber(to: UInt) {
        switch self {
        case .daily:
            self = .daily(number: to)
        case .weekly:
            self = .weekly(number: to)
        case .monthly:
            self = .monthly(number: to)
        case .yearly:
            self = .yearly(number: to)
        }
    }
}

public enum CalculationStart: Codable, Equatable {
    case days(number: UInt)
    case weeks(number: UInt)
    case months(number: UInt)
    case years(number: UInt)

    func getAsDateComponents() -> DateComponents {
        switch self {
        case let .days(number):
            DateComponents(day: -Int(number))
        case let .weeks(number):
            DateComponents(day: -Int(number * 7))
        case let .months(number):
            DateComponents(month: -Int(number))
        case let .years(number):
            DateComponents(year: -Int(number))
        }
    }

    public func getNumber() -> UInt {
        switch self {
        case let .days(number):
            number
        case let .weeks(number):
            number
        case let .months(number):
            number
        case let .years(number):
            number
        }
    }

    public mutating func setNumber(to: UInt) {
        switch self {
        case .days:
            self = .days(number: to)
        case .weeks:
            self = .weeks(number: to)
        case .months:
            self = .months(number: to)
        case .years:
            self = .years(number: to)
        }
    }

    func typeEq(rhs: CompletionGoal) -> Bool {
        let rhsNum = rhs.getNumber()
        return switch self {
        case .days:
            rhs == .daily(number: rhsNum)
        case .weeks:
            rhs == .weekly(number: rhsNum)
        case .months:
            rhs == .monthly(number: rhsNum)
        case .years:
            rhs == .yearly(number: rhsNum)
        }
    }
}

struct StoredEval {
    var from: CalculationStart
    var to: DateComponents
    var dayResultsHash: Int
    var goal: CompletionGoal
    var firstDay: DateComponents
    var dayDefault: UInt
    var value: Double

    init(from: CalculationStart, to: DateComponents, dayResultsHash: Int, goal: CompletionGoal, firstDay: DateComponents, dayDefault: UInt) {
        self.from = from
        self.to = to
        self.dayResultsHash = dayResultsHash
        self.goal = goal
        self.firstDay = firstDay
        self.dayDefault = dayDefault
        self.value = 0
    }

    func equalsBase(_ other: StoredEval) -> Bool {
        from == other.from &&
            to.cleanEq(other.to) &&
            dayResultsHash == other.dayResultsHash &&
            goal == other.goal &&
            firstDay.cleanEq(other.firstDay) &&
            dayDefault == other.dayDefault
    }
}

struct StoredDayEval {
    var dayResult: UInt
    var day: DateComponents
    var goal: CompletionGoal
    var value: Double

    init(dayResult: UInt, day: DateComponents, goal: CompletionGoal) {
        self.dayResult = dayResult
        self.day = day
        self.goal = goal
        self.value = 0
    }

    func equalsBase(_ other: StoredDayEval) -> Bool {
        dayResult == other.dayResult &&
            day.cleanEq(other.day) &&
            goal == other.goal
    }
}

struct StoredPrediction {
    var referenceDate: DateComponents
    var start: CalculationStart
    var yellowRatio: Double
    var goal: CompletionGoal
    var dayResultsHash: Int
    var limit: UInt?
    var dayDefault: UInt
    var firstDay: DateComponents
    var value: (DateComponents?, DateComponents?)

    init(referenceDate: DateComponents, start: CalculationStart, yellowRatio: Double, goal: CompletionGoal, dayResultsHash: Int, limit: UInt?, dayDefault: UInt, firstDay: DateComponents) {
        self.referenceDate = referenceDate
        self.start = start
        self.yellowRatio = yellowRatio
        self.goal = goal
        self.dayResultsHash = dayResultsHash
        self.limit = limit
        self.dayDefault = dayDefault
        self.firstDay = firstDay
        self.value = (nil, nil)
    }

    func equalsBase(_ other: StoredPrediction) -> Bool {
        referenceDate.cleanEq(other.referenceDate) &&
            start == other.start &&
            yellowRatio == other.yellowRatio &&
            goal == other.goal &&
            dayResultsHash == other.dayResultsHash &&
            limit == other.limit &&
            dayDefault == other.dayDefault &&
            firstDay == other.firstDay
    }
}
