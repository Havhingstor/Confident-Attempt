import Foundation

extension DateComponents {
    public var invertedTime: DateComponents {
        DateComponents(hour: hour.inverted(), minute: minute.inverted())
    }

    public var time: DateComponents {
        DateComponents(hour: hour, minute: minute)
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
