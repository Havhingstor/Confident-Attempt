import Foundation
import OSLog

public extension Date {
    var dc: DateComponents {
        Calendar.current.dateComponents([.year, .month, .day], from: self)
    }
}

extension DateComponents: @retroactive Comparable {
    /// Cleans the date components to be used in the date components dict
    public var cleaned: DateComponents {
        DateComponents(year: self.year, month: self.month, day: self.day)
    }
    
    public static func < (lhs: DateComponents, rhs: DateComponents) -> Bool {
        if let distance = lhs.daysSince(rhs), distance < 0 {
            return true
        } else {
            return false
        }
    }

    func daysSince(_ other: DateComponents) -> Int? {
        let result = Calendar.current.dateComponents([.day], from: other, to: self).day

        if result == nil {
            logger("Util").error("Can't calculate days between \(other) and \(self)!")
        }

        return result
    }

    func addingDays(_ number: Int) -> DateComponents? {
        guard let date = asDate else { return .none }
        let result = Calendar.current.date(byAdding: .day, value: number, to: date)?.dc

        if result == nil {
            logger("Util").error("Can't adds \(number) days to \(self)!")
        }

        return result
    }

    func daysInMonth() -> Int {
        guard let date = asDate else { return 30 }
        return Calendar.current.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    func daysInYear() -> Int {
        guard let date = asDate else { return 365 }
        return Calendar.current.range(of: .day, in: .year, for: date)?.count ?? 365
    }

    public var asDate: Date? {
        let result = Calendar.current.date(from: self)

        if result == nil {
            logger("Util").error("Can't convert \(self) to Date!")
        }

        return result
    }

    public var invertedTime: DateComponents {
        DateComponents(hour: hour.inverted(), minute: minute.inverted())
    }

    public var time: DateComponents {
        DateComponents(hour: hour, minute: minute)
    }

    public static var now: DateComponents {
        Date.now.dc
    }
}

extension FixedWidthInteger {
    func addWithoutOverflow(_ other: Self) -> Self {
        let result = addingReportingOverflow(other)

        if result.overflow {
            return self
        } else {
            return result.partialValue
        }
    }

    func subWithoutOverflow(_ other: Self) -> Self {
        let result = subtractingReportingOverflow(other)

        if result.overflow {
            return self
        } else {
            return result.partialValue
        }
    }
}

extension Int? {
    func inverted() -> Int? {
        guard let self else { return nil }

        return -self
    }
}

func logger(_ category: String = "Habit") -> Logger {
    Logger(subsystem: "de.pschuetz.ConfidentAttempt", category: category)
}
