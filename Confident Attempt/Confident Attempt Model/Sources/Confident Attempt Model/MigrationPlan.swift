import SwiftData

public enum HabitsMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [HabitsSchemaV1.self, HabitsSchemaV2.self, HabitsSchemaV3.self, HabitsSchemaV4.self]
    }

    public static var stages: [MigrationStage] {
        [migrateV1toV2, MigrationStage.lightweight(fromVersion: HabitsSchemaV2.self, toVersion: HabitsSchemaV3.self), migrateV3toV4]
    }

    private static let migrateV1toV2 = MigrationStage.custom(fromVersion: HabitsSchemaV1.self, toVersion: HabitsSchemaV2.self, willMigrate: nil) { context in
        let habits = try context.fetch(FetchDescriptor<HabitsSchemaV2.Habit>())

        for habit in habits {
            habit.setFirstDay()
        }

        try context.save()
    }

    private static let migrateV3toV4 = MigrationStage.custom(fromVersion: HabitsSchemaV3.self, toVersion: HabitsSchemaV4.self, willMigrate: nil) { context in
        let habits = try context.fetch(FetchDescriptor<HabitsSchemaV4.Habit>())

        for habit in habits {
            habit.moveDayResults()
        }

        try context.save()
    }
}

public typealias Habit = HabitsSchemaV4.Habit
