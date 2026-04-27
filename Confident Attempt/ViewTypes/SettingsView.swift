import SwiftUI
import Confident_Attempt_Model

struct SettingsView: View {
    @Binding var redZone: Double
    @Binding private var periodScale: TimeScale
    @Binding private var periodAmount: Int
    
    @FocusState private var textFieldFocus: Bool

    init(redZone: Binding<Double>, periodScale: Binding<TimeScale>, periodAmount: Binding<Int>) {
        self._redZone = redZone
        self._periodScale = periodScale
        self._periodAmount = periodAmount
    }
    
    var body: some View {
        Form {
            Section("Evaluation Period") {
                LabeledTextField(label: "Amount", TextField("Amount", value: $periodAmount, format: .number))
                    .keyboardType(.numberPad)
                
                Picker("Scale", selection: $periodScale) {
                    Text("Days")
                        .tag(TimeScale.day)
                    Text("Weeks")
                        .tag(TimeScale.week)
                    Text("Months")
                        .tag(TimeScale.month)
                    Text("Years")
                        .tag(TimeScale.year)
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
    SettingsView(redZone: .constant(0.75), periodScale: .constant(.month), periodAmount: .constant(1))
}
