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
        
        var shouldBeBadging: Bool {
            preferences.shouldBeBadging
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
        
        func addTimer() {
            guard let date = calculateNextTimerTrigger(dayStart) else { return }
            
            let timer = Timer(fire: date, interval: 0, repeats: false) { _ in
                self.refreshDate()
                self.addTimer()
            }
            
            if let setTimer {
                setTimer.invalidate()
            }
            
            setTimer = timer
            
            RunLoop.main.add(timer, forMode: .common)
        }
        
        func setBadge(context: ModelContext) {
            let notificationCentre = UNUserNotificationCenter.current()
            
            Task {
                let authorizationStatus = await notificationCentre.notificationSettings().authorizationStatus
                
                guard authorizationStatus == .authorized else { return }
                
                var count = 0
                
                if preferences.shouldBeBadging {
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
    }
}
