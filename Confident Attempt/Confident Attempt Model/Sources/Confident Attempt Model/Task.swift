import SwiftData
import Foundation

@Model
public class Task {
    public var name: String
    public var textDescription: String
    var firstDayInternal: Data
    public private(set) var maxNum: UInt8?
    public private(set) var expectedNum: ExpectedCompletions
    var dayResults: [UInt8] = []
    
    var firstDay: DateComponents {
        do {
            return try JSONDecoder().decode(DateComponents.self, from: firstDayInternal)
        } catch (let e) {
            print("Error: when decoding first day: ", e.localizedDescription)
            return Date.now.dc
        }
    }
    
    public init(name: String, textDescription: String, firstDay: DateComponents = Date.now.dc, maxNum: UInt8? = 1, expectedNum: ExpectedCompletions = .daily(number: 1)) {
        self.name = name
        self.textDescription = textDescription
        self.maxNum = maxNum
        self.expectedNum = expectedNum
        do {
            try self.firstDayInternal = JSONEncoder().encode(firstDay)
        } catch (let e) {
            print("Error when encoding first day: ", e)
            self.firstDayInternal = Data()
        }
    }
    
    public func getDay(_ day: DateComponents = Date.now.dc) -> UInt8 {
        let offset = day.daysSince(firstDay) ?? 0
        
        return getDay(offset)
    }
    
    public func getDay(_ offset: Int) -> UInt8 {
        if offset >= 0 && offset < dayResults.count {
            return dayResults[offset]
        } else {
            return 0
        }
    }
    
    public func setDay(_ day: DateComponents, to: UInt8) {
        let offset = day.daysSince(firstDay) ?? 0
        
        return setDay(offset, to: to)
    }
    
    public func setDay(_ offset: Int, to: UInt8) {
        guard offset >= 0 else {return}
        
        while dayResults.count <= offset {
            dayResults.append(0)
        }
        
        switch maxNum {
            case let .some(max) where to > max:
                dayResults[offset] = max
            default:
                dayResults[offset] = to
        }
    }
    
    public func increaseDay(_ day: DateComponents, by: UInt8) {
        let offset = day.daysSince(firstDay) ?? 0
        
        return increaseDay(offset, by: by)
    }
    
    public func increaseDay(_ offset: Int, by: UInt8) {
        let newVal = getDay(offset).addWithoutOverflow(by)
        
        setDay(offset, to: newVal)
    }
    
    public func decreaseDay(_ day: DateComponents, by: UInt8) {
        let offset = day.daysSince(firstDay) ?? 0
        
        return decreaseDay(offset, by: by)
    }
    
    public func decreaseDay(_ offset: Int, by: UInt8) {
        let newVal = getDay(offset).subWithoutOverflow(by)
        
        setDay(offset, to: newVal)
    }
    
    public func getEvaluationForDay(_ day: DateComponents) -> Double {
        let offset = day.daysSince(firstDay) ?? 0
        
        return getEvaluationForDay(offset)
    }
    
    public func getEvaluationForDay(_ offset: Int) -> Double {
        return Double(getDay(offset)) / self.expectedNum.getAsDaily(forDate: firstDay.addingDays(offset) ?? firstDay)
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
