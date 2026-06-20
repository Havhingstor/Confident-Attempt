import Confident_Attempt_Model
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.name) private var habits: [Habit]
    @Environment(\.scenePhase) var scenePhase

    @State private var viewModel: ViewModel

    var undoManager: UndoManager? {
        modelContext.undoManager
    }

    init(_ prefs: Preferences) {
        let viewModelWrapped = ViewModel(prefs)
        _viewModel = .init(initialValue: viewModelWrapped)
    }

    private var floatStyle: FloatingPointFormatStyle<Double> {
        .number.precision(.fractionLength(0 ... 2))
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(habits) { habit in
                    HabitRowView(habit, viewModel)
                }
                .onDelete { indices in
                    viewModel.delete(indices, list: habits, modelContext: modelContext)
                }
            }
            .animation(.default, value: habits)
            .animation(.default, value: undoManager?.canUndo)
            .animation(.default, value: undoManager?.canRedo)
            .navigationTitle("root.app-name")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }

                if let undoManager {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("general.undo", systemImage: "arrow.uturn.backward.circle") {
                            undoManager.undo()
                        }
                        .disabled(!undoManager.canUndo)
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button("general.redo", systemImage: "arrow.uturn.forward.circle") {
                            undoManager.redo()
                        }
                        .disabled(!undoManager.canRedo)
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    NavigationLink {
                        SettingsView(viewModel.preferences)
                    } label: {
                        Label("settings.title", systemImage: "gear")
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    NavigationLink {
                        HelpView()
                    } label: {
                        Label("help.title", systemImage: "questionmark")
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    Button("new-habit.title", systemImage: "plus") {
                        viewModel.addHabitShown = true
                    }
                }
            }
            .sheet(isPresented: $viewModel.addHabitShown) {
                HabitEditView(referenceDate: { viewModel.referenceDate })
            }
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                // We must set the correct timer, badge and notification even
                // if the application was just in the background for a long time,
                // as the timer might not have run when it was its time
                if viewModel.newTimerNeeded() {
                    viewModel.runTimerAction(context: modelContext)
                }
            }
        }
        .onChange(of: viewModel.dayStart) {
            viewModel.planDayStart(context: modelContext)
        }
        .onChange(of: viewModel.notifications) {
            viewModel.addDayStartNotification(context: modelContext)
            viewModel.setBadgeNow(context: modelContext)
        }
        .onChange(of: viewModel.activeNotifications) {
            viewModel.addDayStartNotification(context: modelContext)
        }
        .onChange(of: viewModel.achievedHabitsInBadge) {
            viewModel.addDayStartNotification(context: modelContext)
            viewModel.setBadgeNow(context: modelContext)
        }
        .onChange(of: habits.count) {
            viewModel.addDayStartNotification(context: modelContext)
            viewModel.setBadgeNow(context: modelContext)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            viewModel.runTimerAction(context: modelContext)
        }
        .alert(viewModel.alertText, isPresented: $viewModel.alertShown, actions: {})
    }
}

#Preview {
    ContentView(Preferences())
        .modelContainer(getPreviewContainer())
}
