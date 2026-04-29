import SwiftUI
import Confident_Attempt_Model

struct SettingsView: View {
    @Binding var redZone: Double
    @Binding var periodScale: TimeScale
    @Binding var periodAmount: Int
    @Binding var dayStart: DateComponents
    
    @FocusState private var textFieldFocus: Bool
    
    var dayStartDate: Binding<Date> {
        Binding {
            dayStart.asDate ?? .now}
        set: { newVal in
            dayStart = Calendar.current.dateComponents([.hour, .minute, .second], from: newVal)
        }
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
                DatePicker("Day Start", selection: dayStartDate, displayedComponents: .hourAndMinute)
                Text("Any completions made before this time will be assigned to the previous day.")
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView(redZone: .constant(0.75), periodScale: .constant(.month), periodAmount: .constant(1), dayStart: .constant(DateComponents()))
}
