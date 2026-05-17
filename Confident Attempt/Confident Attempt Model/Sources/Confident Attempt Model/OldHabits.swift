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
        public private(set) var repetition: UInt?
        public private(set) var goal: CompletionGoal = CompletionGoal.daily(number: 1)
        fileprivate var dayResults: [DateComponents: UInt] = [:]
        
        public init() {
        }
    }
}

public enum HabitsSchemaV2: VersionedSchema {
    public static let versionIdentifier = Schema.Version(2, 0, 0)
    
    public static var models: [any PersistentModel.Type] {
        [Habit.self, MyDate.self, DayCompletion.self]
    }
    
    @Model
    public class Habit {
        public var name: String = ""
        public var textDescription: String = ""
        public var symbol: String?
        public var repetition: UInt?
        public var goal: CompletionGoal = CompletionGoal.daily(number: 1)
        
        @Attribute(originalName: "dayResults")
        public var oldDayResults: [DateComponents: UInt] = [:]
        
        @Relationship(deleteRule: .cascade)
        public var newDayResults: [DayCompletion] = []
        
        public init() {}
    }
    
    @Model
    public class MyDate {
        public var day: UInt8
        public var month: UInt8
        public var year: UInt
        
        public init(day: UInt8, month: UInt8, year: UInt) {
            self.day = day
            self.month = month
            self.year = year
        }
        
        public init(_ dc: DateComponents) {
            day = UInt8(clamping: dc.day ?? 1)
            month = UInt8(clamping: dc.month ?? 1)
            year = UInt(clamping: dc.year ?? 2026)
        }
    }
    
    @Model
    public class DayCompletion {
        @Relationship(deleteRule: .cascade)
        public var date: MyDate
        public var value: UInt
        
        init(date: MyDate, value: UInt) {
            self.date = date
            self.value = value
        }
    }
}
