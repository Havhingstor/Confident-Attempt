import Confident_Attempt_Model
import OSLog
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

    @FocusState private var textFieldFocus: Bool
    @State private var viewModel: ViewModel
    @State private var showExportDialog = false
    @State private var showImportDialog = false
    @State private var showIOAlert = false
    @State private var showImportMarkDialog = false
    @State private var importURL: URL?
    @State private var ioTitle: LocalizedStringKey = ""

    init(_ prefs: Preferences) {
        let viewModel = ViewModel(prefs)
        _viewModel = .init(initialValue: viewModel)
    }

    var body: some View {
        Form {
            Section("Evaluation Period") {
                LabeledTextField(label: "general.amount", TextField("general.amount", value: $viewModel.periodAmount, format: .number))
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
                    .onChange(of: viewModel.notificationsPreferences) {
                        viewModel.reloadNotifications()
                    }
                    .onAppear {
                        viewModel.checkAndSetBadges()
                    }
                if viewModel.notificationsPreferences {
                    Toggle("Only in Notification Centre", isOn: $viewModel.passiveNotifications)
                    Toggle("Include habits where the goal\nhas been achieved over the evaluation period", isOn: $viewModel.achievedHabitsInBadge)
                }
                Text("Sends a notification at the start of a day and sets the badge to the number of habits which don't yet have enough completions to reach the long-term goal.")
                Text("Note: After the notification has been sent, before the app is opened the next time, the badge number will include all habits, regardless of their number of completions in the past or on that day")

                if let badgingWarning = viewModel.badgingWarning {
                    Text(badgingWarning)
                        .foregroundStyle(.red)
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
                switch result {
                case let .success(success):
                    logger().info("Saving Success: Saved to \(success.absoluteString)")
                    ioTitle = "Successfully exported habits"
                    showIOAlert = true
                case let .failure(failure):
                    logger().error("Couldn't save: \(failure)")
                    ioTitle = "Couldn't export habits: \(failure.localizedDescription)"
                    showIOAlert = true
                }
            }
            .fileImporter(isPresented: $showImportDialog, allowedContentTypes: [.json]) { result in
                switch result {
                case let .success(directory):
                    importURL = directory
                    showImportMarkDialog = true
                case let .failure(error):
                    logger().error("Can't import file: \(error)")
                    ioTitle = "Habits can't be imported: \(error.localizedDescription)"
                    showIOAlert = true
                }
            }
            .alert("Should the habits be marked as \"imported\"?", isPresented: $showImportMarkDialog, presenting: importURL, actions: { url in
                Button("Yes") {
                    importHabitFile(url: url, addMark: true)
                }
                Button("No") {
                    importHabitFile(url: url, addMark: false)
                }
                Button("Cancel", role: .cancel) {}
            })
            .alert(ioTitle, isPresented: $showIOAlert) {}
            .alert(viewModel.ioError, isPresented: $viewModel.ioErrorShown) {}
        }
        .navigationTitle("settings.title")
    }

    func importHabitFile(url: URL, addMark: Bool) {
        let gotAccess = url.startAccessingSecurityScopedResource()
        if !gotAccess {
            logger().error("Can't get access to import directory")
            ioTitle = "Habits can't be imported: App can't get access to directory"
            showIOAlert = true
            return
        }

        viewModel.loadFromFile(url, context: modelContext, markHabits: addMark)

        url.stopAccessingSecurityScopedResource()
    }
}

#Preview {
    NavigationStack {
        SettingsView(Preferences())
    }
}
