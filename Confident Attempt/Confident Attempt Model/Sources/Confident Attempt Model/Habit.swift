import SwiftData
import Foundation

@Model
public class Habit {
    public var name: String
    public var textDescription: String
    public private(set) var repetition: UInt8?
    public private(set) var goal: CompletionGoal
    private var dayResults: [DateComponents: UInt8] = [:]
    
    public init?(name: String, textDescription: String, repetition: UInt8? = 1, goal: CompletionGoal = .daily(number: 1)) {
        self.name = name
        self.textDescription = textDescription
        self.repetition = repetition
        self.goal = goal
        
        if !Self.testValues(repetition: repetition, goal: goal) {
            return nil
        }
    }
    
    public init(cloneof from: Habit, newName: String, copyData: Bool) {
        self.name = newName
        self.textDescription = from.textDescription
        self.repetition = from.repetition
        self.goal = from.goal
        if copyData {
            self.dayResults = from.dayResults
        }
    }
    
    public static func testValues(repetition: UInt8?, goal: CompletionGoal) -> Bool {
        guard goal.getNumber() > 0 else {return false}
        
        if let repetition {
            guard repetition > 0 else {return false}
            
            if let daily = goal.getAsDailyAlways(), daily > Double(repetition) {
                return false
            }
        }
        
        return true
    }
    
    public func getDay(_ day: DateComponents = Date.now.dc) -> UInt8 {
        return dayResults[day] ?? 0
    }
    
    public func setDay(_ day: DateComponents, to: UInt8) {
        switch repetition {
            case let .some(repetition) where to > repetition:
                dayResults[day] = repetition
            default:
                dayResults[day] = to
        }
    }
    
    public func increaseDay(_ day: DateComponents, by: UInt8) {
        let newVal = getDay(day).addWithoutOverflow(by)
        setDay(day, to: newVal)
    }
    
    public func decreaseDay(_ day: DateComponents, by: UInt8) {
        let newVal = getDay(day).subWithoutOverflow(by)
        
        setDay(day, to: newVal)
    }
    
    public func getEvaluationForDay(_ day: DateComponents) -> Double {
        return Double(getDay(day)) / self.goal.getAsDaily(forDate: day)
    }
    
    public func getTotal(from: CalculationStart, to: DateComponents) -> UInt {
        guard let lastDate = to.asDate,
              let beforeStart = Calendar.current.date(byAdding: from.getAsDateComponents(), to: lastDate)?.dc else {return 0}
        
        return dayResults.filter({$0.key > beforeStart && $0.key <= to}).reduce(0, {$0 + UInt($1.value)})
    }
    
    public func getEvaluation(from: CalculationStart, to: DateComponents) -> Double {
        guard let lastDate = to.asDate,
              let beforeStart = Calendar.current.date(byAdding: from.getAsDateComponents(), to: lastDate)?.dc else {return 0}
        
        let totalEvaluation = dayResults.filter({$0.key > beforeStart && $0.key <= to}).reduce(0, {$0 + getEvaluationForDay($1.key)})
        
        let totalDays = to.daysSince(beforeStart)
        guard let totalDays, totalDays > 0 else {return 0}
        
        return totalEvaluation / Double(totalDays)
    }
    
    public func setRepetitionAndGoal(rep repetition: UInt8?, goal: CompletionGoal) {
        guard Self.testValues(repetition: repetition, goal: goal) else {return}
        if let repetition,
           self.repetition == nil || self.repetition ?? 0 > repetition {
            dayResults = dayResults.mapValues { value in
                min(value, repetition)
            }
        }
            
        self.repetition = repetition
        self.goal = goal
    }
}

public enum CompletionGoal: Codable, Equatable {
    case daily(number: UInt8)
    case weekly(number: UInt8)
    case monthly(number: UInt8)
    case yearly(number: UInt8)
    
    public func getAsDaily(forDate: DateComponents) -> Double {
        switch self {
            case .daily(let number):
                Double(number)
            case .weekly(let number):
                Double(number) / 7.0
            case .monthly(let number):
                Double(number) / Double(forDate.daysInMonth())
            case .yearly(let number):
                Double(number) / Double(forDate.daysInYear())
        }
    }
    
    public func getAsDailyAlways() -> Double? {
        switch self {
            case .daily(let number):
                Double(number)
            case .weekly(let number):
                Double(number) / 7.0
            case .monthly(_):
                nil
            case .yearly(_):
                nil
        }
    }
    
    public func getNumber() -> UInt8 {
        switch self {
            case .daily(let number):
                number
            case .weekly(let number):
                number
            case .monthly(let number):
                number
            case .yearly(let number):
                number
        }
    }
    
    mutating public func setNumber(to: UInt8) {
        switch self {
            case .daily(_):
                self = .daily(number: to)
            case .weekly(_):
                self = .weekly(number: to)
            case .monthly(_):
                self = .monthly(number: to)
            case .yearly(_):
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
            case .days(let number):
                DateComponents(day: -Int(number))
            case .weeks(let number):
                DateComponents(day: -Int(number * 7))
            case .months(let number):
                DateComponents(month: -Int(number))
            case .years(let number):
                DateComponents(year: -Int(number))
        }
    }
    
    public func getNumber() -> UInt {
        switch self {
            case .days(let number):
                number
            case .weeks(let number):
                number
            case .months(let number):
                number
            case .years(let number):
                number
        }
    }
    
    mutating public func setNumber(to: UInt) {
        switch self {
            case .days(_):
                self = .days(number: to)
            case .weeks(_):
                self = .weeks(number: to)
            case .months(_):
                self = .months(number: to)
            case .years(_):
                self = .years(number: to)
        }
    }
}
