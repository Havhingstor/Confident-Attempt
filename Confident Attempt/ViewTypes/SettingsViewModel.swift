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
            guard preferences.shouldBeBadging else { return }
            badgingWarning = ""
            let notificationCentre = UNUserNotificationCenter.current()
            Task {
                do {
                    let authorized = try await notificationCentre.requestAuthorization(options: [.badge])
                    
                    if !authorized {
                        preferences.shouldBeBadging = false
                    }
                } catch {
                    preferences.shouldBeBadging = false
                }
                
                if !preferences.shouldBeBadging {
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
        
        var shouldBeBadging: Bool {
            get {
                preferences.shouldBeBadging
            }
            set {
                preferences.shouldBeBadging = newValue
            }
        }
    }
}
