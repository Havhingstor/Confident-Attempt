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
            Section("settings.evaluation-period") {
                LabeledTextField(label: "general.amount", TextField("general.amount", value: $viewModel.periodAmount, format: .number))
                    .keyboardType(.numberPad)

                Picker("general.scale", selection: $viewModel.periodScale) {
                    Text("settings.days")
                        .tag(TimeScale.day)
                    Text("settings.weeks")
                        .tag(TimeScale.week)
                    Text("settings.months")
                        .tag(TimeScale.month)
                    Text("settings.years")
                        .tag(TimeScale.year)
                }
            }

            Section("settings.minimum-completion") {
                VStack {
                    Slider(value: $viewModel.redZone, in: 0 ... 1, step: 0.01)
                    Text("\(viewModel.redZone.formatted(.percent))")
                }
            }

            Section {
                DatePicker("settings.day-start", selection: viewModel.dayStartDate, displayedComponents: .hourAndMinute)
                Text("settings.day-start.help")
            }

            Section {
                Toggle("settings.notifications.basic", isOn: $viewModel.notifications)
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
                    Toggle("settings.notifications.notification-centre", isOn: $viewModel.passiveNotifications)
                    Toggle("settings.notifications.achieved-habits", isOn: $viewModel.achievedHabitsInBadge)
                }
                Text("settings.notifications.help.basic")
                Text("settings.notifications.help.badge")

                if let badgingWarning = viewModel.badgingWarning {
                    Text(badgingWarning)
                        .foregroundStyle(.red)
                }
            }
            .animation(.default, value: viewModel.badgingWarning)
            .animation(.default, value: viewModel.notifications)

            Section {
                Button("settings.export") {
                    showExportDialog = true
                }

                Button("settings.import") {
                    showImportDialog = true
                }
            }
            .fileExporter(isPresented: $showExportDialog, document: viewModel.getAsFile(context: modelContext), contentType: .json, defaultFilename: "ConfidentAttemptExport.json") { result in
                switch result {
                case let .success(success):
                    logger().info("Saving Success: Saved to \(success.absoluteString)")
                    ioTitle = "settings.export.success"
                    showIOAlert = true
                case let .failure(failure):
                    logger().error("Couldn't save: \(failure)")
                    ioTitle = "settings.export.fail-\(failure.localizedDescription)"
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
                    ioTitle = "settings.import.fail-\(error.localizedDescription)"
                    showIOAlert = true
                }
            }
            .alert("settings.import.mark", isPresented: $showImportMarkDialog, presenting: importURL, actions: { url in
                Button("general.yes") {
                    importHabitFile(url: url, addMark: true)
                }
                Button("general.no") {
                    importHabitFile(url: url, addMark: false)
                }
                Button("general.cancel", role: .cancel) {}
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
            ioTitle = "settings.import.fail.directory"
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
