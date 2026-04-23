import Foundation

public extension Date {
    var dc: DateComponents {
        Calendar.current.dateComponents([.year, .month, .day], from: self)
    }
}

extension DateComponents: @retroactive Comparable {
    public static func < (lhs: DateComponents, rhs: DateComponents) -> Bool {
        if let distance = lhs.daysSince(rhs), distance < 0 {
            return true
        } else {
            return false
        }
    }
    
    func daysSince(_ other: DateComponents) -> Int? {
        Calendar.current.dateComponents([.day], from: other, to: self).day
    }
    
    func addingDays(_ number: Int) -> DateComponents? {
        guard let date = self.asDate else {return .none}
        return Calendar.current.date(byAdding: .day, value: number, to: date)?.dc
    }
    
    func daysInMonth() -> Int {
        guard let date = self.asDate else {return 30}
        return Calendar.current.range(of: .day, in: .month, for: date)?.count ?? 30
    }
    
    func daysInYear() -> Int {
        guard let date = self.asDate else {return 365}
        return Calendar.current.range(of: .day, in: .year, for: date)?.count ?? 365
    }
    
    var asDate: Date? {
        Calendar.current.date(from: self)
    }
}

extension FixedWidthInteger {
    func addWithoutOverflow(_ other: Self) -> Self {
        let result = self.addingReportingOverflow(other)
        
        if result.overflow {
            return self
        } else {
            return result.partialValue
        }
    }
    
    func subWithoutOverflow(_ other: Self) -> Self {
        let result = self.subtractingReportingOverflow(other)
        
        if result.overflow {
            return self
        } else {
            return result.partialValue
        }
    }
}
