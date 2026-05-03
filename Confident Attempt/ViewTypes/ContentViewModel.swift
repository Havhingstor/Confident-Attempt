import SwiftUI
import Confident_Attempt_Model
import SwiftData

extension ContentView {
    @Observable
    class ViewModel {
        var addHabitShown: Bool
        var editHabit: Habit?
        var deleteHabit: Habit?
        var duplicateHabit: Habit?
        var showDuplicateDialog: Bool
        var showDeletionDialog: Bool
        var setTimer: Timer?
        var dateNow: Date
        
        let preferences: Preferences

        init(_ prefs: Preferences) {
            addHabitShown = false
            editHabit = nil
            deleteHabit = nil
            duplicateHabit = nil
            showDuplicateDialog = false
            showDeletionDialog = false
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
            let earlier = Calendar.current.date(byAdding: dayStart.invertedTime, to: dateNow) ?? .now
            
            return earlier.dc
        }
        
        func refreshDate() {
            self.dateNow = .now
        }

        func calculateNextTimerTrigger(_ startOfDay: DateComponents) -> Date? {
            let offset = startOfDay.time
            let start = Calendar.current.startOfDay(for: .now)
            
            guard var date = Calendar.current.date(byAdding: offset, to: start) else { return nil }
            
            while date <= .now {
                guard let newDate = Calendar.current.date(byAdding: .day, value: 1, to: date) else { return nil }
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
            guard let date = calculateNextTimerTrigger(dayStart) else { return }
            
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
                
                guard authorizationStatus == .authorized else { return }
                
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
                
                guard authorizationStatus == .authorized else { return }
                
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
    }
}
