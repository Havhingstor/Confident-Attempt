import SwiftData

public enum HabitsMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [HabitsSchemaV1.self]
    }
    
    public static var stages: [MigrationStage] {
        []
    }
}
