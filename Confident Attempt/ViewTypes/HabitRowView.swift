import Confident_Attempt_Model
import SwiftData
import SwiftUI

struct HabitRowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode
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

                Text(viewModel.completionText)
            }
            .multilineTextAlignment(.trailing)
        }
        .foregroundStyle(viewModel.foregroundColour)
        .swipeActions(edge: .trailing) {
            if editMode?.wrappedValue.isEditing != true {
                Button("Decrease", systemImage: "minus.circle") {
                    viewModel.decrease()
                }
            }
        }
        .swipeActions(edge: .leading) {
            if editMode?.wrappedValue.isEditing != true {
                Button("Increase", systemImage: "plus.circle") {
                    viewModel.increase()
                }
            }
        }
        .onTapGesture {
            if editMode?.wrappedValue.isEditing == true {
                viewModel.showEditor = true
            }
        }
        .contextMenu {
            Button("Edit") {
                viewModel.showEditor = true
            }
            Button("Duplicate") {
                viewModel.showDuplicateAlert = true
            }
            Button("Delete", role: .destructive) {
                viewModel.showDeletionAlert = true
            }
        }
        .animation(.default, value: viewModel.referenceDate)
        .animation(.default, value: viewModel.dayValue)
        .animation(.default, value: editMode?.wrappedValue)
        .onChange(of: viewModel.evaluationToday) {
            viewModel.setBadge(context: modelContext)
        }
        .sheet(isPresented: $viewModel.showEditor) {
            HabitEditView(editedHabit: viewModel.habit, referenceDate: { viewModel.referenceDate })
        }
        .alert("Delete Entry \"\(viewModel.name)\"?", isPresented: $viewModel.showDeletionAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                viewModel.delete(context: modelContext)
            }
        }
        .alert("Copy with Data?", isPresented: $viewModel.showDuplicateAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Copy Data") {
                viewModel.duplicateWithCopy(context: modelContext)
            }
            Button("Without Data") {
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
