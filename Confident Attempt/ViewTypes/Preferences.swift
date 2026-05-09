import SwiftUI

@Observable
class Preferences {
    let defaults = UserDefaults.standard

    var periodScale: TimeScale {
        didSet {
            guard oldValue != periodScale else { return }
            UserDefaults().set(periodScale.rawValue, forKey: "periodScale")
        }
    }

    var periodAmount: Int {
        didSet {
            guard oldValue != periodAmount else { return }
            UserDefaults().set(periodAmount, forKey: "periodAmount")
        }
    }

    var redZone: Double {
        didSet {
            guard oldValue != redZone else { return }
            UserDefaults().set(redZone, forKey: "redZone")
        }
    }

    var dayStart: RawDateComponents {
        didSet {
            guard oldValue != dayStart else { return }
            UserDefaults().set(dayStart.rawValue, forKey: "dayStart")
        }
    }

    var notifications: Bool {
        didSet {
            guard oldValue != notifications else { return }
            UserDefaults().set(notifications, forKey: "notifications")
        }
    }

    var activeNotifications: Bool {
        didSet {
            guard oldValue != activeNotifications else { return }
            UserDefaults().set(activeNotifications, forKey: "activeNotifications")
        }
    }

    init() {
        periodScale = TimeScale(rawValue: defaults.string(forKey: "periodScale") ?? "") ?? .month
        periodAmount = defaults.value(forKey: "periodAmount") as? Int ?? 1
        redZone = defaults.value(forKey: "redZone") as? Double ?? 0.75
        dayStart = RawDateComponents(rawValue: defaults.string(forKey: "dayStart") ?? "") ?? RawDateComponents()
        notifications = defaults.value(forKey: "notifications") as? Bool ?? false
        activeNotifications = defaults.value(forKey: "activeNotifications") as? Bool ?? true
    }
}
