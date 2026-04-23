import SwiftData
import Foundation

@Model
public class Task {
    public var name: String
    public var textDescription: String
    public private(set) var maxNum: UInt8?
    public private(set) var expectedNum: ExpectedCompletions
    var dayResults: [DateComponents: UInt8] = [:]
    
    public init(name: String, textDescription: String, maxNum: UInt8? = 1, expectedNum: ExpectedCompletions = .daily(number: 1)) {
        self.name = name
        self.textDescription = textDescription
        self.maxNum = maxNum
        self.expectedNum = expectedNum
    }
    
    public func getDay(_ day: DateComponents = Date.now.dc) -> UInt8 {
        return dayResults[day] ?? 0
    }
    
    public func setDay(_ day: DateComponents, to: UInt8) {
        switch maxNum {
            case let .some(max) where to > max:
                dayResults[day] = max
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
        return Double(getDay(day)) / self.expectedNum.getAsDaily(forDate: day)
    }
    
    public func getTotal(from: CalculationStart, to: DateComponents) -> UInt {
        guard let lastDate = to.asDate,
              let beforeStart = Calendar.current.date(byAdding: from.getAsDateComponents(), to: lastDate)?.dc else {return 0}
        
        return dayResults.filter({$0.key > beforeStart && $0.key <= to}).reduce(0, {$0 + UInt($1.value)})
    }
    
    public func getEvaluation(from: CalculationStart, to: DateComponents) -> Double {
        guard let lastDate = to.asDate,
              let beforeStart = Calendar.current.date(byAdding: from.getAsDateComponents(), to: lastDate)?.dc else {return 0}
        
        let totalEvaluation = dayResults.filter({$0.key > beforeStart && $0.key <= to}).reduce((0, 0), {($0.0 + 1, $0.1 + getEvaluationForDay($1.key))})
        
        guard totalEvaluation.0 != 0 else {return 0}
        
        return totalEvaluation.1 / Double(totalEvaluation.0)
    }
}

public enum ExpectedCompletions: Codable {
    case daily(number: UInt8)
    case weekly(number: UInt8)
    case monthly(number: UInt8)
    case yearly(number: UInt8)
    
    public func getAsDaily(forDate: DateComponents) -> Double {
        switch self {
            case .daily(let number):
                return Double(number)
            case .weekly(let number):
                return Double(number) / 7.0
            case .monthly(let number):
                return Double(number) / Double(forDate.daysInMonth())
            case .yearly(let number):
                return Double(number) / Double(forDate.daysInYear())
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
}
