import Confident_Attempt_Model
import OSLog
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

extension SettingsView {
    @Observable
    class ViewModel {
        var badgingWarning: String

        var preferences: Preferences
        var ioErrorShown = false
        var ioError = ""

        init(_ prefs: Preferences) {
            badgingWarning = ""
            preferences = prefs
        }

        private var dayStart: DateComponents {
            get {
                preferences.dayStart.val
            }
            set {
                preferences.dayStart.val = newValue
            }
        }

        var dayStartDate: Binding<Date> {
            Binding {
                self.dayStart.asDate ?? .now
            }
            set: { newVal in
                self.dayStart = Calendar.current.dateComponents([.hour, .minute, .second], from: newVal)
            }
        }

        func checkAndSetBadges() {
            guard preferences.notifications else { return }
            badgingWarning = ""
            let notificationCentre = UNUserNotificationCenter.current()
            Task {
                do {
                    let authorized = try await notificationCentre.requestAuthorization(options: [.badge, .alert])

                    if !authorized {
                        preferences.notifications = false
                    }
                } catch {
                    preferences.notifications = false
                }

                if preferences.notifications == false {
                    badgingWarning = "You need to allow Notifications to send you badges."
                }
            }
        }

        var periodAmount: Int {
            get {
                preferences.periodAmount
            }
            set {
                preferences.periodAmount = newValue
            }
        }

        var redZone: Double {
            get {
                preferences.redZone
            }
            set {
                preferences.redZone = newValue
            }
        }

        var periodScale: TimeScale {
            get {
                preferences.periodScale
            }
            set {
                preferences.periodScale = newValue
            }
        }

        var notifications: Bool {
            get {
                preferences.notifications
            }
            set {
                preferences.notifications = newValue
            }
        }

        var passiveNotifications: Bool {
            get {
                !preferences.activeNotifications
            }
            set {
                preferences.activeNotifications = !newValue
            }
        }

        var achievedHabitsInBadge: Bool {
            get {
                preferences.achievedHabitsInBadge
            }
            set {
                preferences.achievedHabitsInBadge = newValue
            }
        }

        func getAsFile(context: ModelContext) -> HabitListFile? {
            let descriptor = FetchDescriptor<Habit>()

            do {
                let habits = try context.fetch(descriptor)
                return try HabitListFile(values: habits)
            } catch let e {
                logger().error("Error when converting habits to JSON: \(e)")
                ioError = "Habits can't be exported: \(e)"
                ioErrorShown = true
                return nil
            }
        }

        func loadFromFile(_ url: URL, context: ModelContext) {
            do {
                let data = try Data(contentsOf: url)
                let habits = try JSONDecoder().decode([Habit].self, from: data)

                for habit in habits {
                    habit.name += " (Imported)"
                    context.insert(habit)
                }

                try context.save()
            } catch let e {
                logger().error("Can't load habits: \(e)")
                ioError = "Habits can't be imported: \(e)"
                ioErrorShown = true
            }
        }
    }

    struct HabitListFile: FileDocument {
        static var readableContentTypes = [UTType.json]
        let data: Data

        init(values: [Habit]) throws {
            data = try JSONEncoder().encode(values)
        }

        init(configuration: ReadConfiguration) throws {
            if let data = configuration.file.regularFileContents {
                self.data = data
            } else {
                data = Data()
            }
        }

        func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
            return FileWrapper(regularFileWithContents: data)
        }
    }
}
