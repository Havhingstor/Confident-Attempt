import SwiftUI
import Foundation

@Observable
class Preferences {
    let defaults = NSUbiquitousKeyValueStore.default
    let localDefaults = UserDefaults.standard

    var periodScale: TimeScale {
        didSet {
            guard oldValue != periodScale else { return }
            defaults.set(periodScale.rawValue, forKey: "periodScale")
            defaults.synchronize()
        }
    }

    var periodAmount: Int {
        didSet {
            guard oldValue != periodAmount else { return }
            defaults.set(periodAmount, forKey: "periodAmount")
            defaults.synchronize()
        }
    }

    var redZone: Double {
        didSet {
            guard oldValue != redZone else { return }
            defaults.set(redZone, forKey: "redZone")
            defaults.synchronize()
        }
    }

    var dayStart: RawDateComponents {
        didSet {
            guard oldValue != dayStart else { return }
            defaults.set(dayStart.rawValue, forKey: "dayStart")
            defaults.synchronize()
        }
    }

    var notifications: Bool {
        didSet {
            guard oldValue != notifications else { return }
            localDefaults.set(notifications, forKey: "notifications")
        }
    }

    var activeNotifications: Bool {
        didSet {
            guard oldValue != activeNotifications else { return }
            localDefaults.set(activeNotifications, forKey: "activeNotifications")
        }
    }

    init() {
        periodScale = .month
        periodAmount = 1
        redZone = 0.75
        dayStart = RawDateComponents()
        notifications = false
        activeNotifications = true
        
        deleteKeys()
        
        loadValues()
        NotificationCenter.default.addObserver(self, selector: #selector(receiveNotification), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: defaults)
    }
    
    private func loadValues() {
        if let periodScale = TimeScale(rawValue: defaults.string(forKey: "periodScale") ?? "") {
            self.periodScale = periodScale
        }
        if let periodAmount = defaults.object(forKey: "periodAmount") as? Int {
            self.periodAmount = periodAmount
        }
        if let redZone = defaults.object(forKey: "redZone") as? Double {
            self.redZone = redZone
        }
        if let dayStart = RawDateComponents(rawValue: defaults.string(forKey: "dayStart") ?? "") {
            self.dayStart = dayStart
        }
        if let notifications = localDefaults.value(forKey: "notifications") as? Bool {
            self.notifications = notifications
        }
        if let activeNotifications = localDefaults.value(forKey: "activeNotifications") as? Bool {
            self.activeNotifications = activeNotifications
        }
    }
    
    @objc private func receiveNotification(_ notification: NSNotification) {
        loadValues()
    }
    
    private func deleteKeys() {
        localDefaults.removeObject(forKey: "periodScale")
        localDefaults.removeObject(forKey: "periodAmount")
        localDefaults.removeObject(forKey: "redZone")
        localDefaults.removeObject(forKey: "dayStart")
        defaults.removeObject(forKey: "notifications")
        defaults.removeObject(forKey: "activeNotifications")
        defaults.synchronize()
    }
}
