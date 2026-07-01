import CalendarView
import Confident_Attempt_Model
import SwiftData
import SwiftUI

struct DetailsView: View {
    @State private var viewModel: ViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colourScheme
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
                        Text("details.total-completions-\(viewModel.total)")
                        Text(viewModel.expectedText)
                        Text(viewModel.goal)
                        Text(viewModel.evaluationText)
                            .padding(.bottom, 20)
                    }
                    .padding(.leading)
                }
                .foregroundStyle(viewModel.evaluationColour(mode: colourScheme))

                if viewModel.dateSelected {
                    Group {
                        Text(viewModel.selectedDayString)
                            .font(.title3)
                            .padding(.bottom, 5)
                        Group {
                            Stepper {
                                Text(viewModel.selectedDayCompletionsString)
                                if viewModel.hasMax {
                                    Text(viewModel.maximumString)
                                }
                            } onIncrement: {
                                viewModel.increaseSelected()
                            } onDecrement: {
                                viewModel.decreaseSelected()
                            }
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
                        .overlay {
                            RoundedRectangle(cornerRadius: 40.0)
                                .strokeBorder(Color.accentColor, lineWidth: 2.0)
                        }

                    Button("details.jump-today") {
                        viewModel.showToday()
                    }
                    .padding([.top, .bottom], 5)

                    if viewModel.dateSelected {
                        Button("details.jump-selected") {
                            viewModel.showSelection()
                        }
                    }
                }
                .padding(.horizontal, 25)
                .padding(.bottom, 20)

                predictionView

                HStack {
                    Spacer()
                }
            }
            .textSelection(.enabled)
            .padding(30)
        }
        .animation(.default, value: viewModel.selectedDate)
        .animation(.default, value: viewModel.visibleComponentsCalendar)
        .onAppear {
            viewModel.loadDatesCorrectly()
        }
        .onDisappear {
            try? modelContext.save()
        }
    }

    var predictionView: some View {
        let (yellowDay, greenDay) = viewModel.getDayPredictionResults()

        return VStack(alignment: .leading, spacing: 10) {
            if yellowDay != nil || greenDay != nil {
                Text("details.prediction.title-\(Image(systemName: "checkmark.circle.fill"))")
                    .font(.title3)
                    .foregroundStyle(.green)
                if let yellowDay,
                   let yellowDay = yellowDay.asDate
                {
                    Text("details.prediction.yellow-\(yellowDay.formatted(date: .complete, time: .omitted))")
                        .foregroundStyle(.yellow)
                }
                if let greenDay,
                   let greenDay = greenDay.asDate
                {
                    Text("details.prediction.green-\(greenDay.formatted(date: .complete, time: .omitted))")
                        .foregroundStyle(.green)
                }
            }
        }
        .animation(.default, value: viewModel.evaluationText)
        .animation(.default, value: viewModel.goal)
        .animation(.default, value: viewModel.maximumString)
    }
}

extension CalendarView {
    func addDecorations(_ viewModel: DetailsView.ViewModel) -> CalendarView {
        let (achieved, remaining) = viewModel.getDayCompletions()

        return decorating(achieved, systemImage: "checkmark.circle.fill", color: .green, size: .large)
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
