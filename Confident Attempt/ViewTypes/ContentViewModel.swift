import Confident_Attempt_Model
import OSLog
import SwiftData
import SwiftUI

extension ContentView {
    @Observable
    class ViewModel {
        var addHabitShown: Bool
        var setTimer: Timer?
        var dateNow: Date

        let preferences: Preferences

        var alertShown = false
        var alertText = ""

        init(_ prefs: Preferences) {
            addHabitShown = false
            setTimer = nil
            dateNow = .now
            preferences = prefs
        }

        var notifications: Bool {
            preferences.notifications
        }

        var activeNotifications: Bool {
            preferences.activeNotifications
        }

        var calculationPeriod: CalculationStart {
            let periodScale = preferences.periodScale
            let periodAmount = UInt(clamping: preferences.periodAmount)

            return periodScale.toCalculationStart(withNum: periodAmount)
        }

        var dayStart: DateComponents {
            preferences.dayStart.val
        }

        var referenceDate: DateComponents {
            let invertedTime = dayStart.invertedTime
            let dateNow = dateNow
            let earlier = Calendar.current.date(byAdding: invertedTime, to: dateNow)

            if earlier == nil {
                logger().error("Can't add \(invertedTime) to \(dateNow), therefore the reference date is just now.")
            }

            return (earlier ?? .now).dc
        }

        func refreshDate() {
            dateNow = .now
        }

        func calculateNextTimerTrigger(_ startOfDay: DateComponents) -> Date? {
            let offset = startOfDay.time
            let start = Calendar.current.startOfDay(for: .now)

            guard var date = Calendar.current.date(byAdding: offset, to: start) else {
                logger().error("Can't add \(offset) to \(start), therefore the next timer can't be created.")
                return nil
            }

            while date <= .now {
                guard let newDate = Calendar.current.date(byAdding: .day, value: 1, to: date) else {
                    logger().error("Can't add one day to to \(date), therefore the next timer can't be created.")
                    return nil
                }
                date = newDate
            }

            date = date.addingTimeInterval(1)

            return date
        }

        func runTimerAction(context: ModelContext) {
            refreshDate()
            setBadge(context: context)
            addTimer(context: context)
        }

        func addTimer(context: ModelContext) {
            guard let date = calculateNextTimerTrigger(dayStart) else {
                alertText = "Currently unable to update the values on day start, please reload app then."
                alertShown = true
                return
            }

            let timer = Timer(fire: date, interval: 0, repeats: false) { _ in
                self.runTimerAction(context: context)
            }

            if let setTimer {
                setTimer.invalidate()
            }

            setTimer = timer

            RunLoop.main.add(timer, forMode: .common)

            addDayFlipNotification(context: context, at: date)
        }

        func setBadge(context: ModelContext) {
            let notificationCentre = UNUserNotificationCenter.current()

            Task {
                let authorizationStatus = await notificationCentre.notificationSettings().authorizationStatus

                guard authorizationStatus == .authorized else {
                    if preferences.notifications {
                        logger().error("Can't set badge, notifications aren't authorised!")
                        alertText = "Can't set the application's badge, please enable notifications in the iOS and app settings"
                        alertShown = true
                        preferences.notifications = false
                    }
                    return
                }

                var count = 0

                if preferences.notifications {
                    let descriptor = FetchDescriptor<Habit>()
                    let habits = (try? context.fetch(descriptor)) ?? []

                    count = habits.filter { habit in
                        habit.getEvaluationForDay(referenceDate) < 1.0
                    }.count
                }

                do {
                    try await notificationCentre.setBadgeCount(count)
                }
            }
        }

        func addDayFlipNotification(context: ModelContext, at: Date? = nil) {
            let notificationCentre = UNUserNotificationCenter.current()
            notificationCentre.removePendingNotificationRequests(withIdentifiers: ["DayFlip"])

            guard notifications, let date = at ?? calculateNextTimerTrigger(dayStart) else { return }

            let timing = Calendar.current.dateComponents([.hour, .minute], from: date)

            Task {
                let authorizationStatus = await notificationCentre.notificationSettings().authorizationStatus

                guard authorizationStatus == .authorized else {
                    if preferences.notifications {
                        logger().error("Can't add notification, notifications aren't authorised!")
                        alertText = "Can't show day start notifications, please enable notifications in the iOS and app settings"
                        alertShown = true
                        preferences.notifications = false
                    }
                    return
                }

                let descriptor = FetchDescriptor<Habit>()
                let habits = (try? context.fetch(descriptor)) ?? []

                let content = UNMutableNotificationContent()
                content.title = "A new day has started"
                content.body = "Complete all your habits to reach your goals"

                if preferences.activeNotifications {
                    content.interruptionLevel = .active
                } else {
                    content.interruptionLevel = .passive
                }

                content.badge = NSNumber(value: habits.count)

                let trigger = UNCalendarNotificationTrigger(dateMatching: timing, repeats: true)

                let request = UNNotificationRequest(identifier: "DayFlip", content: content, trigger: trigger)

                do {
                    try await notificationCentre.add(request)
                }
            }
        }

        func delete(_ indices: IndexSet, list: [Habit], modelContext: ModelContext) {
            let toDelete = indices.map { index in
                list[index]
            }

            for habit in toDelete {
                modelContext.delete(habit)
            }
        }
    }
}
