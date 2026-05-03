import Confident_Attempt_Model
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.name) private var habits: [Habit]

    @State private var viewModel: ViewModel
    
    init(_ prefs: Preferences) {
        let viewModelWrapped = ViewModel(prefs)
        _viewModel = .init(initialValue: viewModelWrapped)
    }

    private var floatStyle: FloatingPointFormatStyle<Double> {
        .number.precision(.fractionLength(0 ... 2))
    }


    var body: some View {
        NavigationStack {
            List(habits) { habit in
                HabitRowView(habit, viewModel)
            }
            .navigationTitle("Confident Attempt")
            .toolbar {
                NavigationLink {
                    SettingsView(viewModel.preferences)
                } label: {
                    Label("Settings", systemImage: "gear")
                }
                NavigationLink {
                    HelpView()
                } label: {
                    Label("Help", systemImage: "questionmark")
                }

                Button("New Habit", systemImage: "plus") {
                    viewModel.addHabitShown = true
                }
            }
            .sheet(isPresented: $viewModel.addHabitShown) {
                HabitEditView()
            }
            .onAppear {
                if viewModel.setTimer == nil {
                    viewModel.addTimer(context: modelContext)
                    viewModel.setBadge(context: modelContext)
                }
            }
            .onChange(of: viewModel.dayStart) {
                viewModel.addTimer(context: modelContext)
            }
            .onChange(of: viewModel.shouldBeBadging) {
                viewModel.addDayFlipNotification(context: modelContext)
                viewModel.setBadge(context: modelContext)
            }
            .onChange(of: habits.count) {
                viewModel.addDayFlipNotification(context: modelContext)
                viewModel.setBadge(context: modelContext)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                viewModel.runTimerAction(context: modelContext)
            }
        }
    }

    
}

#Preview {
    ContentView(Preferences())
        .modelContainer(getPreviewContainer())
}
