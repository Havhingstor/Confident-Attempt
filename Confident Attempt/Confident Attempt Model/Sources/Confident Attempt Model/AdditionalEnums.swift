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
