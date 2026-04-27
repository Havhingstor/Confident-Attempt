import Confident_Attempt_Model
import SwiftUI

enum TimeScale: String {
    case day = "day"
    case week = "week"
    case month = "month"
    case year = "year"
    
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
            case .days(_):
                    .day
            case .weeks(_):
                    .week
            case .months(_):
                    .month
            case .years(_):
                    .year
        }
    }
    
    func toCompletionGoal(withNum: UInt8) -> CompletionGoal {
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
            case .daily(_):
                    .day
            case .weekly(_):
                    .week
            case .monthly(_):
                    .month
            case .yearly(_):
                    .year
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
