import SwiftUI
import Confident_Attempt_Model
import SwiftData
import CalendarView

struct DetailsView: View {
    @State private var viewModel: ViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var date = Date()
    @State private var number = UInt(3)

    private var habit: Habit {
        viewModel.habit
    }
    
    init(_ superViewModel: HabitRowView.ViewModel) {
        let viewModel = ViewModel(superViewModel)
        _viewModel = .init(initialValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(habit.name)
                    .font(.title)
                Text(habit.textDescription)
                    .padding(.bottom, 20)
                
                Group {
                    Text(viewModel.timePeriodString)
                        .font(.title3)
                        .padding(.bottom, 5)
                    
                    Group {
                        Text("Total: \(viewModel.total) Completions")
                        Text(viewModel.goal)
                        Text(viewModel.completionText)
                            .padding(.bottom, 20)
                    }
                    .padding(.leading)
                }
                .foregroundStyle(viewModel.evaluationColour)
                
                if viewModel.dateSelected {
                    Group {
                        Text(viewModel.selectedDayString)
                            .font(.title3)
                            .padding(.bottom, 5)
                        Group {
                            Text(viewModel.selectedDayCompletionsString)
                                .padding(.bottom, 20)
                        }
                        .padding(.leading)
                    }
                    .foregroundStyle(viewModel.dayColour)
                }
                
                Group {
                    CalendarView(visibleDateComponents: $viewModel.visibleComponentsCalendar, selection: $viewModel.selectedDate)
                        .addDecorations(viewModel)
                        .padding(5)
                        .overlay{
                            RoundedRectangle(cornerRadius: 40.0)
                                .strokeBorder(Color.accentColor, lineWidth: 2.0)
                        }
                    
                    Button("Jump to today") {
                        viewModel.showToday()
                    }
                    .padding([.top, .bottom], 5)
                    
                    if viewModel.dateSelected {
                        Button("Jump to selected day") {
                            viewModel.showSelection()
                        }
                    }
                }
                .padding(.horizontal, 25)
                
                HStack {
                    Spacer()
                }
            }
            .animation(.default, value: viewModel.selectedDate)
            .animation(.default, value: viewModel.visibleComponentsCalendar)
            .padding(30)
        }
    }
}

extension CalendarView {
    func addDecorations(_ viewModel: DetailsView.ViewModel) -> CalendarView {
        let (achieved, remaining) = viewModel.getDayCompletions()
        
        return self
            .decorating(achieved, systemImage: "checkmark.circle.fill", color: .green, size: .large)
            .decorating(remaining, systemImage: "xmark.circle.fill", color: .red, size: .large)
    }
}

#Preview {
    getPreview()
}

private func getPreview() -> some View {
    let container = getPreviewContainer()
    let habit = try! container.mainContext.fetch(FetchDescriptor<Habit>())[0]
    habit.increaseDay(.now, by: 2)
    
    let preferences = Preferences()
    preferences.periodScale = .week
    preferences.periodAmount = 5
    let rootVM = ContentView.ViewModel(preferences)
    let superVM = HabitRowView.ViewModel(habit, rootVM)
    
    return DetailsView(superVM)
        .modelContainer(container)
}
