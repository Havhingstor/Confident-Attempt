import Confident_Attempt_Model
import OSLog
import SwiftUI

enum TimeScale: String {
    case day
    case week
    case month
    case year

    func toCalculationStart(withNum: UInt) -> CalculationStart {
        switch self {
        case .day:
            .days(number: withNum)
        case .week:
            .weeks(number: withNum)
        case .month:
            .months(number: withNum)
        case .year:
            .years(number: withNum)
        }
    }

    static func fromCalculationStart(_ start: CalculationStart) -> Self {
        switch start {
        case .days:
            .day
        case .weeks:
            .week
        case .months:
            .month
        case .years:
            .year
        }
    }

    func toCompletionGoal(withNum: UInt) -> CompletionGoal {
        switch self {
        case .day:
            .daily(number: withNum)
        case .week:
            .weekly(number: withNum)
        case .month:
            .monthly(number: withNum)
        case .year:
            .yearly(number: withNum)
        }
    }

    static func fromCompletionGoal(_ goal: CompletionGoal) -> Self {
        switch goal {
        case .daily:
            .day
        case .weekly:
            .week
        case .monthly:
            .month
        case .yearly:
            .year
        }
    }
}

struct RawDateComponents: RawRepresentable {
    var val: DateComponents

    typealias RawValue = String

    var rawValue: RawValue {
        (try? JSONEncoder().encode(val).base64EncodedString()) ?? ""
    }

    init(val: DateComponents = DateComponents()) {
        self.val = val
    }

    init?(rawValue: String) {
        if let data = Data(base64Encoded: rawValue),
           let val = try? JSONDecoder().decode(DateComponents.self, from: data)
        {
            self.val = val
        } else {
            return nil
        }
    }
}

struct CustomTextField<Label: View>: View {
    let textField: TextField<Label>

    @FocusState private var focussed: Bool

    init(_ textField: TextField<Label>) {
        self.textField = textField
    }

    var body: some View {
        textField
            .focused($focussed)
            .toolbar {
                if focussed {
                    ToolbarItem(placement: .keyboard) {
                        Button("Done", systemImage: "checkmark") {
                            focussed = false
                        }
                    }
                }
            }
    }
}

struct LabeledTextField<Label: View>: View {
    let textField: TextField<Label>
    let label: String

    @FocusState private var focussed: Bool

    init(label: String, _ textField: TextField<Label>) {
        self.textField = textField
        self.label = label
    }

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            textField
                .multilineTextAlignment(.trailing)
                .focused($focussed)
                .toolbar {
                    if focussed {
                        ToolbarItem(placement: .keyboard) {
                            Button("Done", systemImage: "checkmark") {
                                focussed = false
                            }
                        }
                    }
                }
        }
        .onTapGesture {
            focussed = true
        }
    }
}

func logger(_ category: String = "UI") -> Logger {
    Logger(subsystem: "de.pschuetz.ConfidentAttempt", category: category)
}

func numberAsText(_ val: UInt) -> String {
    switch val {
    case 0:
        "zero"
    case 1:
        "one"
    case 2:
        "two"
    case 3:
        "three"
    case 4:
        "four"
    case 5:
        "five"
    case 6:
        "six"
    case 7:
        "seven"
    case 8:
        "eight"
    case 9:
        "nine"
    default:
        "\(val)"
    }
}
