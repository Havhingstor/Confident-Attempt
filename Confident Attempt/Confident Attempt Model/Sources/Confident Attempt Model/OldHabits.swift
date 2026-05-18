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
        public var repetition: UInt?
        public var goal: CompletionGoal = CompletionGoal.daily(number: 1)
        public var dayResults: [DateComponents: UInt] = [:]
        
        public init(name: String, textDescription: String, symbol: String?,
                    repetition: UInt?, goal: CompletionGoal, dayResults: [DateComponents: UInt]) {
            self.name = name
            self.textDescription = textDescription
            self.repetition = repetition
            self.goal = goal
            self.symbol = symbol
            self.dayResults = dayResults
        }
    }
}
