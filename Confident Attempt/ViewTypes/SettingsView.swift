import Confident_Attempt_Model
import SwiftUI

struct SettingsView: View {
    @FocusState private var textFieldFocus: Bool
    @State private var viewModel: ViewModel
    
    init(_ prefs: Preferences) {
        let viewModel = ViewModel(prefs)
        _viewModel = .init(initialValue: viewModel)
    }
    

    var body: some View {
        Form {
            Section("Evaluation Period") {
                LabeledTextField(label: "Amount", TextField("Amount", value: $viewModel.periodAmount, format: .number))
                    .keyboardType(.numberPad)

                Picker("Scale", selection: $viewModel.periodScale) {
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
                    Slider(value: $viewModel.redZone, in: 0 ... 1, step: 0.01)
                    Text("\(viewModel.redZone.formatted(.percent))")
                }
            }

            Section {
                DatePicker("Day Start", selection: viewModel.dayStartDate, displayedComponents: .hourAndMinute)
                Text("Any completions made before this time will be assigned to the previous day.")
            }

            Section {
                Toggle("Basic Notifications & Badges", isOn: $viewModel.shouldBeBadging)
                    .onChange(of: viewModel.shouldBeBadging) {
                        viewModel.checkAndSetBadges()
                    }
                    .onAppear {
                        viewModel.checkAndSetBadges()
                    }
                Text("Sends a notification at the start of a day and sets the badge to the number of habits which don't yet have enough completions to reach the long-term goal")

                if !viewModel.badgingWarning.isEmpty {
                    Text(viewModel.badgingWarning)
                }
            }
            .animation(.default, value: viewModel.badgingWarning)
        }
        .navigationTitle("Settings")
    }
}

//#Preview {
//    SettingsView(redZone: .constant(0.75), periodScale: .constant(.month), periodAmount: .constant(1), dayStart: .constant(DateComponents()), shouldBeBadging: .constant(false))
//}
