import Confident_Attempt_Model
import SwiftUI

struct SettingsView: View {
    @Binding var redZone: Double
    @Binding var periodScale: TimeScale
    @Binding var periodAmount: Int
    @Binding var dayStart: DateComponents
    @Binding var shouldBeBadging: Bool
    @State private var badgingWarning = ""

    @FocusState private var textFieldFocus: Bool

    var dayStartDate: Binding<Date> {
        Binding {
            dayStart.asDate ?? .now
        }
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
                    Slider(value: $redZone, in: 0 ... 1, step: 0.01)
                    Text("\(redZone.formatted(.percent))")
                }
            }

            Section {
                DatePicker("Day Start", selection: dayStartDate, displayedComponents: .hourAndMinute)
                Text("Any completions made before this time will be assigned to the previous day.")
            }

            Section {
                Toggle("Show Badges", isOn: $shouldBeBadging)
                    .onChange(of: shouldBeBadging) {
                        checkAndSetBadges()
                    }
                    .onAppear {
                        checkAndSetBadges()
                    }

                if !badgingWarning.isEmpty {
                    Text(badgingWarning)
                }
            }
            .animation(.default, value: badgingWarning)
        }
        .navigationTitle("Settings")
    }

    private func checkAndSetBadges() {
        guard shouldBeBadging else { return }
        badgingWarning = ""
        let notificationCentre = UNUserNotificationCenter.current()
        Task {
            do {
                let authorized = try await notificationCentre.requestAuthorization(options: [.badge])

                if !authorized {
                    shouldBeBadging = false
                }
            } catch {
                shouldBeBadging = false
            }

            if !shouldBeBadging {
                badgingWarning = "You need to allow Notifications to send you badges."
            }
        }
    }
}

#Preview {
    SettingsView(redZone: .constant(0.75), periodScale: .constant(.month), periodAmount: .constant(1), dayStart: .constant(DateComponents()), shouldBeBadging: .constant(false))
}
