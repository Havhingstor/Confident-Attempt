import SwiftUI
import Confident_Attempt_Model

extension SettingsView {
    @Observable
    class ViewModel {
        var badgingWarning: String
        
        var preferences: Preferences
        
        init(_ prefs: Preferences) {
            self.badgingWarning = ""
            self.preferences = prefs
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
    }
}
