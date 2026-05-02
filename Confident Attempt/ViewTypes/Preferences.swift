import SwiftUI

@Observable
class Preferences {
    let defaults = UserDefaults.standard
    
    var periodScale: TimeScale {
        didSet {
            guard oldValue != periodScale else { return }
            UserDefaults().set(_periodScale, forKey: "periodScale")
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
    var shouldBeBadging: Bool {
        didSet {
            guard oldValue != shouldBeBadging else { return }
            UserDefaults().set(shouldBeBadging, forKey: "badging")
        }
    }
    
    init() {
        periodScale = defaults.value(forKey: "periodScale") as? TimeScale ?? .month
        periodAmount = defaults.value(forKey: "periodAmount") as? Int ?? 1
        redZone = defaults.value(forKey: "redZone") as? Double ?? 0.75
        dayStart = RawDateComponents(rawValue: defaults.string(forKey: "dayStart") ?? "") ?? RawDateComponents()
        shouldBeBadging = defaults.value(forKey: "badging") as? Bool ?? false
    }
}
