import Foundation
import SwiftData

@Model
public class Habit {
    public var name: String
    public var textDescription: String
    public var symbol: String?
    public private(set) var repetition: UInt?
    public private(set) var goal: CompletionGoal
    private var dayResults: [DateComponents: UInt] = [:]

    public init?(name: String, textDescription: String, symbol: String? = nil, repetition: UInt? = 1, goal: CompletionGoal = .daily(number: 1)) {
        self.name = name
        self.textDescription = textDescription
        self.repetition = repetition
        self.goal = goal
        self.symbol = symbol

        if !Self.testValues(repetition: repetition, goal: goal) {
            return nil
        }
    }

    public init(cloneof from: Habit, newName: String, copyData: Bool) {
        name = newName
        textDescription = from.textDescription
        repetition = from.repetition
        goal = from.goal
        symbol = from.symbol
        if copyData {
            dayResults = from.dayResults
        }
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

    public func getDay(_ day: DateComponents = Date.now.dc) -> UInt {
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
              let beforeStart = Calendar.current.date(byAdding: from.getAsDateComponents(), to: lastDate)?.dc else { return 0 }

        return dayResults.filter { $0.key > beforeStart && $0.key <= to }.reduce(0) { $0 + UInt($1.value) }
    }

    public func getEvaluation(from: CalculationStart, to: DateComponents) -> Double {
        guard let lastDate = to.asDate,
              let beforeStart = Calendar.current.date(byAdding: from.getAsDateComponents(), to: lastDate)?.dc else { return 0 }

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
}

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

public enum CalculationStart: Codable {
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
}
