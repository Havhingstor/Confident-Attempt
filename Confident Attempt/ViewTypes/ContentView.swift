import Confident_Attempt_Model
import SwiftData
import SwiftUI
import TipKit

struct ContentView: View {
    @Parameter static var numberOfHabits: Int = 0
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.name) private var habits: [Habit]
    @Environment(\.scenePhase) var scenePhase

    @State private var viewModel: ViewModel

    var undoManager: UndoManager? {
        modelContext.undoManager
    }

    init(_ prefs: Preferences, initContext: ModelContext) {
        let viewModelWrapped = ViewModel(prefs)
        _viewModel = .init(initialValue: viewModelWrapped)
        viewModelWrapped.preloadEvals(context: initContext)
    }

    private var floatStyle: FloatingPointFormatStyle<Double> {
        .number.precision(.fractionLength(0 ... 2))
    }

    var body: some View {
        NavigationStack {
            List {
                TipView(SwipeTip())
                
                rows
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
                        HelpView(preferences: viewModel.preferences)
                    } label: {
                        Label("help.title", systemImage: "questionmark")
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    Button("new-habit.title", systemImage: "plus") {
                        viewModel.addHabitShown = true
                    }
                    // Workaround (see https://developer.apple.com/forums/thread/735961)
                    .buttonStyle(.plain)
                    .popoverTip(CreateTip())
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
            Self.numberOfHabits = habits.count
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            viewModel.runTimerAction(context: modelContext)
        }
        .alert(viewModel.alertText, isPresented: $viewModel.alertShown, actions: {})
        .onAppear {
            Self.numberOfHabits = habits.count
        }
    }
    
    @ViewBuilder
    var rows: some View {
        ForEach(Array(habits.enumerated()), id: \.offset) { idx, habit in
            HabitRowView(habit, viewModel, first: idx == 0)
        }
        .onDelete { indices in
            viewModel.delete(indices, list: habits, modelContext: modelContext)
        }
    }
}

#Preview {
    let container = getPreviewContainer()
    let context = ModelContext(container)
    ContentView(Preferences(), initContext: context)
        .modelContainer(container)
}
