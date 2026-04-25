import SwiftUI
import Confident_Attempt_Model

struct SettingsView: View {
    @Binding var redZone: Double
    @Binding var relevantPeriod: CalculationStart

    init(redZone: Binding<Double>, relevantPeriod: Binding<CalculationStart>) {
        self._redZone = redZone
        self._relevantPeriod = relevantPeriod
        
    }
    
    var body: some View {
        Form {
            Section("Evaluation Period") {
                Picker("Scale", selection: self.periodScale) {
                    Text("Days")
                        .tag(PeriodScale.days)
                    Text("Weeks")
                        .tag(PeriodScale.weeks)
                    Text("Months")
                        .tag(PeriodScale.months)
                    Text("Years")
                        .tag(PeriodScale.years)
                }
                
                HStack {
                    Text("Amount")
                    Spacer()
                    TextField("Amount", value: periodAmount, format: .number)
                        .multilineTextAlignment(.trailing)
                    #if os(iOS) || os(iPadOS)
                        .keyboardType(.numberPad)
                    #endif
                }
            }
            
            
            Section("Minimum Completion") {
                VStack {
                    Slider(value: $redZone, in: 0...1, step: 0.01)
                    Text("\(redZone.formatted(.percent))")
                }
            }
        }
        .navigationTitle("Settings")
    }
    
    private var periodScale: Binding<PeriodScale> {
        Binding {
            .fromCalculationStart(relevantPeriod)
        } set: { scale in
            relevantPeriod = scale.toCalculationStart(withNum: relevantPeriod.getNumber())
        }
    }
    
    private var periodAmount: Binding<UInt> {
        Binding {
            relevantPeriod.getNumber()
        } set: { scale in
            if scale > 0 {
                relevantPeriod.setNumber(to: scale)
            }
        }
    }
}

#Preview {
    SettingsView(redZone: .constant(0.75), relevantPeriod: .constant(.months(number: 1)))
}

fileprivate enum PeriodScale {
    case days
    case weeks
    case months
    case years
    
    func toCalculationStart(withNum: UInt) -> CalculationStart {
        switch self {
            case .days:
                    .days(number: withNum)
            case .weeks:
                    .weeks(number: withNum)
            case .months:
                    .months(number: withNum)
            case .years:
                    .years(number: withNum)
        }
    }
    
    static func fromCalculationStart(_ start: CalculationStart) -> Self {
        switch start {
            case .days(_):
                    .days
            case .weeks(_):
                    .weeks
            case .months(_):
                    .months
            case .years(_):
                    .years
        }
    }
}
