import SwiftUI
import Confident_Attempt_Model

struct SettingsView: View {
    @Binding var redZone: Double
    @Binding private var periodScale: PeriodScale
    @Binding private var periodAmount: Int

    init(redZone: Binding<Double>, periodScale: Binding<PeriodScale>, periodAmount: Binding<Int>) {
        self._redZone = redZone
        self._periodScale = periodScale
        self._periodAmount = periodAmount
    }
    
    var body: some View {
        Form {
            Section("Evaluation Period") {
                Picker("Scale", selection: $periodScale) {
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
                    TextField("Amount", value: $periodAmount, format: .number)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                }
            }
            
            
            Section("Minimum Completion") {
                VStack {
                    Slider(value: $redZone, in: 0...1, step: 0.01)
                    Text("\(redZone.formatted(.percent))")
                }
            }
            
            Section {
                Text("Made with ❤ by Paul")
                Link(destination: URL(string: "https://github.com/Havhingstor/Confident-Attempt/issues")!, label: {
                    Text("Issues")
                })
                Link(destination: URL(string: "https://github.com/Havhingstor/Confident-Attempt")!, label: {
                    Text("GitHub")
                })
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView(redZone: .constant(0.75), periodScale: .constant(.months), periodAmount: .constant(1))
}
