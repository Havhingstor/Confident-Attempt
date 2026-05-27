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
            .navigationTitle("Confident Attempt")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }

                if let undoManager {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Undo", systemImage: "arrow.uturn.backward.circle") {
                            undoManager.undo()
                        }
                        .disabled(!undoManager.canUndo)
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Redo", systemImage: "arrow.uturn.forward.circle") {
                            undoManager.redo()
                        }
                        .disabled(!undoManager.canRedo)
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    NavigationLink {
                        SettingsView(viewModel.preferences)
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    NavigationLink {
                        HelpView()
                    } label: {
                        Label("Help", systemImage: "questionmark")
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    Button("New Habit", systemImage: "plus") {
                        viewModel.addHabitShown = true
                    }
                }
            }
            .sheet(isPresented: $viewModel.addHabitShown) {
                HabitEditView(referenceDate: { viewModel.referenceDate })
            }
            .onChange(of: scenePhase) {
                viewModel.runTimerAction(context: modelContext)
            }
            .onChange(of: viewModel.dayStart) {
                viewModel.addTimer(context: modelContext)
            }
            .onChange(of: viewModel.notifications) {
                viewModel.addDayFlipNotification(context: modelContext)
                viewModel.setBadge(context: modelContext)
            }
            .onChange(of: viewModel.activeNotifications) {
                viewModel.addDayFlipNotification(context: modelContext)
            }
            .onChange(of: habits.count) {
                viewModel.addDayFlipNotification(context: modelContext)
                viewModel.setBadge(context: modelContext)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                viewModel.runTimerAction(context: modelContext)
            }
            .alert(viewModel.alertText, isPresented: $viewModel.alertShown, actions: {})
        }
    }
}

#Preview {
    ContentView(Preferences())
        .modelContainer(getPreviewContainer())
}
