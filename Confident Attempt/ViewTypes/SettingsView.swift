import Confident_Attempt_Model
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

    @FocusState private var textFieldFocus: Bool
    @State private var viewModel: ViewModel
    @State private var showExportDialog = false
    @State private var showImportDialog = false

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
                Toggle("Basic Notifications & Badges", isOn: $viewModel.notifications)
                    .onChange(of: viewModel.notifications) {
                        viewModel.checkAndSetBadges()
                    }
                    .onAppear {
                        viewModel.checkAndSetBadges()
                    }
                if viewModel.notifications {
                    Toggle("Only in Notification Centre", isOn: $viewModel.passiveNotifications)
                }
                Text("Sends a notification at the start of a day and sets the badge to the number of habits which don't yet have enough completions to reach the long-term goal")

                if !viewModel.badgingWarning.isEmpty {
                    Text(viewModel.badgingWarning)
                }
            }
            .animation(.default, value: viewModel.badgingWarning)
            .animation(.default, value: viewModel.notifications)

            Section {
                Button("Export Data") {
                    showExportDialog = true
                }

                Button("Import Data") {
                    showImportDialog = true
                }
            }
            .fileExporter(isPresented: $showExportDialog, document: viewModel.getAsFile(context: modelContext), contentType: .json, defaultFilename: "ConfidentAttemptExport.json") { result in
                print("Saving Result: \(result)")
            }
            .fileImporter(isPresented: $showImportDialog, allowedContentTypes: [.json]) { result in
                switch result {
                case let .success(directory):
                    let gotAccess = directory.startAccessingSecurityScopedResource()
                    if !gotAccess {
                        print("Can't get access to import directory")
                        return
                    }

                    viewModel.loadFromFile(directory, context: modelContext)

                    directory.stopAccessingSecurityScopedResource()
                case let .failure(error):
                    print(error)
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView(Preferences())
    }
}
