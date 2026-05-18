import SwiftData

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
            habit.setFirstDay()
        }

        try context.save()
    }
}

public typealias Habit = HabitsSchemaV2.Habit
