import SwiftData
import Foundation

public enum HabitsMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [HabitsSchemaV1.self, HabitsSchemaV2.self]
    }

    public static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
    
    private static let migrateV1toV2 = MigrationStage.custom(fromVersion: HabitsSchemaV1.self, toVersion: HabitsSchemaV2.self, willMigrate: nil) { context in
        let habits = try context.fetch(FetchDescriptor<HabitsSchemaV2.Habit>())
        
        for habit in habits {
            for (day, value) in habit.oldDayResults {
                let customDay = HabitsSchemaV2.MyDate(day)
                let newEntry = HabitsSchemaV2.DayCompletion(date: customDay, value: value)
                habit.newDayResults.append(newEntry)
            }
            habit.oldDayResults.removeAll()
        }
        
        try context.save()
    }
    
    private static let migrateV2toV3 = MigrationStage.custom(fromVersion: HabitsSchemaV2.self, toVersion: HabitsSchemaV3.self, willMigrate: nil) { context in
        
    }
}
