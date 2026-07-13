import Confident_Attempt_Model
import SwiftData
import SwiftUI

struct HabitRowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode
    @Environment(\.colorScheme) var colourScheme
    @State private var viewModel: ViewModel

    init(_ habit: Habit, _ model: ContentView.ViewModel) {
        let viewModel = ViewModel(habit, model)
        _viewModel = .init(initialValue: viewModel)
    }

    var body: some View {
        HStack {
            viewModel.completionSymbol
            VStack(alignment: .leading) {
                viewModel.habitSymbol
                Text(viewModel.habit.name)
            }
            .multilineTextAlignment(.leading)
            Spacer()
            VStack(alignment: .trailing) {
                Text(viewModel.goal)

                Text(viewModel.text)

                Text(viewModel.evaluationText)
            }
            .multilineTextAlignment(.trailing)
        }
        .foregroundStyle(viewModel.foregroundColour(mode: colourScheme))
        .swipeActions(edge: .trailing) {
            if editMode?.wrappedValue.isEditing != true {
                Button("row.decrease", systemImage: "minus.circle") {
                    viewModel.decrease()
                }
            }
        }
        .swipeActions(edge: .leading) {
            if editMode?.wrappedValue.isEditing != true {
                Button("row.increase", systemImage: "plus.circle") {
                    viewModel.increase()
                }
            }
        }
        .contentShape(.rect)
        .onTapGesture {
            if editMode?.wrappedValue.isEditing == true {
                viewModel.showEditor = true
            } else {
                viewModel.showDetails = true
            }
        }
        .contextMenu {
            Button("row.edit") {
                viewModel.showEditor = true
            }
            Button("row.duplicate") {
                viewModel.showDuplicateAlert = true
            }
            Button("row.delete", role: .destructive) {
                viewModel.showDeletionAlert = true
            }
        }
        .animation(.default, value: viewModel.referenceDate)
        .animation(.default, value: viewModel.dayValue)
        .animation(.default, value: editMode?.wrappedValue)
        .onChange(of: viewModel.evaluationToday) {
            viewModel.setBadgeNow(context: modelContext)
        }
        .onChange(of: viewModel.foregroundColour(mode: colourScheme)) {
            // This is also necessary because the badge might need to change if
            // habits that reached the goal aren't shown
            viewModel.setBadgeNow(context: modelContext)
        }
        .sheet(isPresented: $viewModel.showEditor) {
            HabitEditView(editedHabit: viewModel.habit, referenceDate: { viewModel.referenceDate })
        }
        .sheet(isPresented: $viewModel.showDetails) {
            DetailsView(viewModel)
        }
        .alert("row.delete-entry-\(viewModel.name)", isPresented: $viewModel.showDeletionAlert) {
            Button("general.cancel", role: .cancel) {}
            Button("row.delete", role: .destructive) {
                viewModel.delete(context: modelContext)
            }
        }
        .alert("row.copy-confirmation", isPresented: $viewModel.showDuplicateAlert) {
            Button("general.cancel", role: .cancel) {}
            Button("row.copy-confirmation.with-data") {
                viewModel.duplicateWithCopy(context: modelContext)
            }
            Button("row.copy-confirmation.without-data") {
                viewModel.duplicateWithoutCopy(context: modelContext)
            }
        }
    }
}

#Preview {
    let model = ContentView.ViewModel(Preferences())
    let habit = Habit(name: "Test", textDescription: "Test", firstDay: .now)!
    HabitRowView(habit, model)
        .modelContainer(getPreviewContainer())
}
