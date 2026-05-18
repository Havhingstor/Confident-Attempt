import Foundation
import SwiftData

///////////////////////////////////////// Schema /////////////////////////////////////////

public typealias Habit = HabitsSchemaV3.Habit
public typealias MyDate = HabitsSchemaV3.MyDate
public typealias DayCompletion = HabitsSchemaV3.DayCompletion

public enum HabitsSchemaV3: VersionedSchema {
    public static let versionIdentifier = Schema.Version(3, 0, 0)

    public static var models: [any PersistentModel.Type] {
        [Habit.self, MyDate.self, DayCompletion.self]
    }

    @Model
    public class Habit {
        public var name: String = ""
        public var textDescription: String = ""
        public var symbol: String?
        public private(set) var repetition: UInt?
        public private(set) var goal: CompletionGoal = CompletionGoal.daily(number: 1)

        @Relationship(deleteRule: .cascade)
        public private(set) var firstDay: MyDate

        @Relationship(deleteRule: .cascade, originalName: "newDayResults")
        fileprivate var dayResults: [DayCompletion]
        
        fileprivate init(name: String, textDescription: String, symbol: String?, repetition: UInt?,
                         goal: CompletionGoal, firstDay: MyDate, dayResults: [DayCompletion]) {
            self.name = name
            self.textDescription = textDescription
            self.repetition = repetition
            self.goal = goal
            self.symbol = symbol
            self.firstDay = firstDay
            self.dayResults = dayResults
        }
        
        public required init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: HabitCodingKeys.self)
            
            name = try container.decode(String.self, forKey: .name)
            textDescription = try container.decode(String.self, forKey: .textDescription)
            symbol = try container.decode(String?.self, forKey: .symbol)
            repetition = try container.decode(UInt?.self, forKey: .repetition)
            goal = try container.decode(CompletionGoal.self, forKey: .goal)
            dayResults = try container.decode([DayCompletion].self, forKey: .dayResults)
            firstDay = try container.decode(MyDate.self, forKey: .firstDay)
        }
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

        public required init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: MyDateCodingKeys.self)

            day = try container.decode(UInt8.self, forKey: .day)
            month = try container.decode(UInt8.self, forKey: .month)
            year = try container.decode(UInt.self, forKey: .year)
        }
    }

    @Model
    public class DayCompletion {
        public var date: MyDate
        public var value: UInt

        init(date: MyDate, value: UInt) {
            self.date = date
            self.value = value
        }

        public required init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: DayCompletionCodingKeys.self)

            date = try container.decode(MyDate.self, forKey: .date)
            value = try container.decode(UInt.self, forKey: .value)
        }
    }
}

enum HabitCodingKeys: CodingKey {
    case name
    case textDescription
    case symbol
    case repetition
    case goal
    case dayResults
    case firstDay
}

enum MyDateCodingKeys: CodingKey {
    case day
    case month
    case year
}

enum DayCompletionCodingKeys: CodingKey {
    case date
    case value
}

///////////////////////////////////////// Habit Functions /////////////////////////////////////////

extension Habit: Codable {
    public convenience init?(name: String, textDescription: String, symbol: String? = nil, repetition: UInt? = 1,
                             goal: CompletionGoal = .daily(number: 1), firstDay: MyDate = MyDate()) {
        if !Self.testValues(repetition: repetition, goal: goal) {return nil}
        
        self.init(name: name, textDescription: textDescription, symbol: symbol, repetition: repetition,
                  goal: goal, firstDay: firstDay, dayResults: [])
    }
    
    public convenience init(cloneof from: Habit, newName: String, copyData: Bool) {
        let dayResults = copyData ? from.dayResults.map({$0.clone}) : []
        
        self.init(name: newName, textDescription: from.textDescription, symbol: from.symbol, repetition: from.repetition,
                  goal: from.goal, firstDay: from.firstDay.clone, dayResults: dayResults)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: HabitCodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(textDescription, forKey: .textDescription)
        try container.encode(symbol, forKey: .symbol)
        try container.encode(repetition, forKey: .repetition)
        try container.encode(goal, forKey: .goal)
        try container.encode(dayResults, forKey: .dayResults)
        try container.encode(firstDay, forKey: .firstDay)
    }
    
    public func setFirstDay() {
        if let fromData = dayResults.map({ $0.date }).sorted().first {
            firstDay = fromData
        } else {
            firstDay = MyDate()
        }
    }
    
    public var calculatedFirstDay: MyDate {
        if let fromData = dayResults.map({ $0.date }).sorted().first {
            return min(fromData, firstDay)
        } else {
            return firstDay
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
    
    func getDay(_ day: MyDate = MyDate()) -> UInt {
        return dayResults.filter { $0.date == day }.reduce(0) { $0 + $1.value }
    }

    func setDay(_ day: MyDate, to: UInt) {
        let actualValue = switch repetition {
        case let .some(repetition) where to > repetition:
            repetition
        default:
            to
        }

        dayResults.removeAll(where: { $0.date == day })

        let newEntry = DayCompletion(date: day, value: actualValue)
        dayResults.append(newEntry)
    }

    func increaseDay(_ day: MyDate, by: UInt) {
        var oldVal = UInt(0)

        dayResults.removeAll(where: {
            if $0.date == day {
                oldVal = oldVal.addWithoutOverflow($0.value)
                return true
            } else {
                return false
            }
        })

        let actualValue = oldVal.addWithoutOverflow(by)

        let newEntry = DayCompletion(date: day, value: actualValue)
        dayResults.append(newEntry)
    }

    func decreaseDay(_ day: MyDate, by: UInt) {
        var oldVal = UInt(0)

        dayResults.removeAll(where: {
            if $0.date == day {
                oldVal = oldVal.addWithoutOverflow($0.value)
                return true
            } else {
                return false
            }
        })

        let actualValue = oldVal.subWithoutOverflow(by)

        let newEntry = DayCompletion(date: day, value: actualValue)
        dayResults.append(newEntry)
    }

    func getEvaluationForDay(_ day: MyDate) -> Double {
        return Double(getDay(day)) / goal.getAsDaily(forDate: day)
    }

    func getTotal(from: CalculationStart, to: MyDate) -> UInt {
        guard let beforeStart = to.addingDateComponents(from.getAsDateComponents()) else { return 0 }

        return dayResults.filter { $0.date > beforeStart && $0.date <= to }.reduce(0) { $0 + UInt($1.value) }
    }

    func getEvaluation(from: CalculationStart, to: MyDate) -> Double {
        guard var beforeStart = to.addingDateComponents(from.getAsDateComponents()),
              let beforeFirst = calculatedFirstDay.addingDays(-1) else { return 0 }

        beforeStart = max(beforeStart, beforeFirst)

        let totalEvaluation = dayResults.filter { $0.date > beforeStart && $0.date <= to }.reduce(0) { $0 + Double($1.value) / goal.getAsDaily(forDate: $1.date) }

        let totalDays = to.daysSince(beforeStart)
        guard totalDays > 0 else { return 0 }

        return totalEvaluation / Double(totalDays)
    }

    func setRepetitionAndGoal(rep repetition: UInt?, goal: CompletionGoal) {
        guard Self.testValues(repetition: repetition, goal: goal) else { return }
        if let repetition,
           self.repetition == nil || self.repetition ?? 0 > repetition {
            var valueTable: [MyDate: UInt] = [:]
            
            for day in dayResults {
                let oldVal = valueTable[day.date] ?? 0
                valueTable[day.date] = oldVal + day.value
            }
        
            valueTable = valueTable.filter({$0.value > repetition})
            
            dayResults.removeAll(where: {valueTable[$0.date] != nil})
            
            for day in valueTable {
                dayResults.append(DayCompletion(date: day.key, value: repetition))
            }
        }

        self.repetition = repetition
        self.goal = goal
    }

    /// Returns the number of days which would need to be lowered to confine to the proposed repetition
    func checkNewRepetition(_ repetition: UInt) -> UInt {
        if let oldRep = self.repetition,
           repetition >= oldRep
        {
            return 0
        }

        let days = dayResults.filter { $0.value > repetition }.count
        return UInt(days)
    }
}

///////////////////////////////////////// MyDate Functions /////////////////////////////////////////

extension MyDate: Codable, Comparable, Equatable {
    public convenience init(_ dc: DateComponents) {
        let day = UInt8(clamping: dc.day ?? 1)
        let month = UInt8(clamping: dc.month ?? 1)
        let year = UInt(clamping: dc.year ?? 2026)
        self.init(day: day, month: month, year: year)
    }
    
    public convenience init(_ date: Date) {
        self.init(Calendar.current.dateComponents([.year, .month, .day], from: date))
    }
    
    public convenience init() {
        self.init(Date.now)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: MyDateCodingKeys.self)
        
        try container.encode(day, forKey: .day)
        try container.encode(month, forKey: .month)
        try container.encode(year, forKey: .year)
    }
    
    public static func < (lhs: MyDate, rhs: MyDate) -> Bool {
        guard lhs.year == rhs.year else {
            return lhs.year < rhs.year
        }
        
        guard lhs.month == rhs.month else {
            return lhs.month < rhs.month
        }
        
        return lhs.day < rhs.day
    }
    
    public static func == (lhs: MyDate, rhs: MyDate) -> Bool {
        return lhs.year == rhs.year
        && lhs.month == rhs.month
        && lhs.day == rhs.day
    }
    
    func daysInMonth() -> Int {
        guard let date = asDate else { return 30 }
        return Calendar.current.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    func daysInYear() -> Int {
        guard let date = asDate else { return 365 }
        return Calendar.current.range(of: .day, in: .year, for: date)?.count ?? 365
    }

    func daysSince(_ other: MyDate) -> Int {
        guard let result = Calendar.current.dateComponents([.day], from: other.asDC, to: asDC).day else {
            #if DEBUG
                fatalError("Day was nil, couldn't calculate distance between \(other) and \(self)")
            #endif
            return 0
        }

        return result
    }

    func addingDays(_ number: Int) -> MyDate? {
        guard let date = asDate,
              let newDate = Calendar.current.date(byAdding: .day, value: number, to: date) else { return .none }
        return MyDate(newDate)
    }
    
    func addingDateComponents(_ amount: DateComponents) -> MyDate? {
        guard let date = asDate,
              let newDate = Calendar.current.date(byAdding: amount, to: date) else { return .none }
        return MyDate(newDate)
    }

    public var asDC: DateComponents {
        DateComponents(year: Int(year), month: Int(month), day: Int(day))
    }
    
    public var asDate: Date? {
        Calendar.current.date(from: asDC)
    }
    
    public var clone: MyDate {
        MyDate(day: day, month: month, year: year)
    }
}

///////////////////////////////////////// DayCompletion Functions /////////////////////////////////////////

extension DayCompletion: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: DayCompletionCodingKeys.self)
        
        try container.encode(date, forKey: .date)
        try container.encode(value, forKey: .value)
    }
    
    public var clone: DayCompletion {
        DayCompletion(date: date.clone, value: value)
    }
}
