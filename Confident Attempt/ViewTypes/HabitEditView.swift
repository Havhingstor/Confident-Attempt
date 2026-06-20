import Confident_Attempt_Model
import OSLog
import SFSymbolsPicker
import SwiftData
import SwiftUI

struct HabitEditView: View {
    private var editedHabit: Habit?
    @Environment(\.modelContext) private var modelContext

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var repetitionCustom = UInt(2)
    @State private var repetitionType = RepetitionType.normal
    @State private var goalScale = TimeScale.day
    @State private var goalAmount = UInt(1)
    @State private var dayDefault = UInt(0)
    @State private var symbol: String = ""
    @State private var symbolPickerShown = false
    @State private var saveConfirmationDialogShown = false
    @State private var repetitionProblems: UInt? = nil

    private var referenceDate: () -> DateComponents

    private var goal: CompletionGoal {
        goalScale.toCompletionGoal(withNum: goalAmount)
    }

    private var allowed: Bool {
        Habit.testValues(repetition: repetition, goal: goal)
    }

    private var defaultProblem: Bool {
        guard let repetition else { return false }

        return repetition < dayDefault
    }

    private var repetition: UInt? {
        switch repetitionType {
        case .normal:
            1
        case .repetitive:
            repetitionCustom
        case .unlimited:
            nil
        }
    }

    var repetitionTypeHelpText: LocalizedStringKey {
        switch repetitionType {
        case .normal:
            "edit.daily-limit.help.normal"
        case .repetitive:
            "edit.daily-limit.help.repeated-\(repetitionCustom)"
        case .unlimited:
            "edit.daily-limit.help.unlimited"
        }
    }

    init(editedHabit: Habit? = nil, referenceDate: @escaping () -> DateComponents) {
        self.editedHabit = editedHabit
        self.referenceDate = referenceDate

        if let editedHabit {
            _name = State(initialValue: editedHabit.name)
            _description = State(initialValue: editedHabit.textDescription)
            _goalScale = State(initialValue: .fromCompletionGoal(editedHabit.goal))
            _goalAmount = State(initialValue: editedHabit.goal.getNumber())
            _symbol = State(initialValue: editedHabit.symbol ?? "")
            _dayDefault = State(initialValue: editedHabit.dayDefault)

            if editedHabit.repetition == 1 {
                _repetitionType = State(initialValue: .normal)
            } else if let rep = editedHabit.repetition {
                _repetitionType = State(initialValue: .repetitive)
                _repetitionCustom = State(initialValue: rep)
            } else {
                _repetitionType = State(initialValue: .unlimited)
            }
        }
    }

    func createConfirmButton(_ title: LocalizedStringKey, _ action: @escaping () -> Void) -> some View {
        if #available(iOS 26, *) {
            Button(title, role: .confirm, action: action)
        } else {
            Button(title, action: action)
        }
    }

    private var actualSymbol: String {
        if symbol.isEmpty {
            return "book.pages"
        } else {
            return symbol
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    CustomTextField(TextField("edit.name", text: $name))
                    CustomTextField(TextField("edit.description", text: $description, axis: .vertical))
                    HStack {
                        Image(systemName: actualSymbol)
                            .font(.title)
                            .frame(width: 28, height: 27)
                            .foregroundStyle(.blue)

                        Spacer()

                        HStack(spacing: 12) {
                            Button("edit.choose") {
                                symbolPickerShown = true
                            }

                            Button("edit.reset", role: .destructive) {
                                symbol = ""
                            }
                            .foregroundStyle(.red)
                        }
                    }
                    .foregroundStyle(.tint)
                    .buttonStyle(.borderless)
                }

                Section("edit.goal") {
                    LabeledTextField(label: LocalizedStringKey("general.amount"), TextField("general.amount", value: $goalAmount, format: .number))
                        .keyboardType(.numberPad)

                    Picker("general.scale", selection: $goalScale) {
                        Text("edit.per-day")
                            .tag(TimeScale.day)
                        Text("edit.per-week")
                            .tag(TimeScale.week)
                        Text("edit.per-month")
                            .tag(TimeScale.month)
                        Text("edit.per-year")
                            .tag(TimeScale.year)
                    }
                }

                Section("edit.daily-limit") {
                    Picker("edit.daily-limit.type", selection: $repetitionType) {
                        Text("edit.daily-limit.normal")
                            .tag(RepetitionType.normal)
                        Text("edit.daily-limit.repeated")
                            .tag(RepetitionType.repetitive)
                        Text("edit.daily-limit.unlimited")
                            .tag(RepetitionType.unlimited)
                    }
                    .pickerStyle(.segmented)
                    Text(repetitionTypeHelpText)
                    if repetitionType == .repetitive {
                        LabeledTextField(label: "edit.daily-limit.max-number", TextField("edit.daily-limit.max-number", value: $repetitionCustom, format: .number))
                            .keyboardType(.numberPad)
                    }
                }

                Section("edit.default-completions") {
                    CustomTextField(TextField("edit.default-completions", value: $dayDefault, format: .number))
                        .keyboardType(.numberPad)
                }

                if !allowed {
                    Text("edit.daily-limit.too-low")
                        .listRowBackground(Color.red)
                        .font(.title3)
                }

                if defaultProblem {
                    Text("edit.default-completions.too-high")
                        .listRowBackground(Color.red)
                        .font(.title3)
                }

                if name.isEmpty {
                    Text("edit.name-empty")
                        .listRowBackground(Color.red)
                        .font(.title3)
                }
            }
            .navigationTitle(editedHabit == nil ? "edit.edit-habit" : "edit.add-habit")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $symbolPickerShown, content: {
                SymbolsPicker(selection: $symbol, titleKey: "edit.choose-symbol", autoDismiss: true)
            })
            .alert("edit.save", isPresented: $saveConfirmationDialogShown, presenting: repetitionProblems) { _ in
                Button("edit.save.confirmation", role: .destructive) {
                    save()
                }
                Button("general.cancel", role: .cancel) {
                    repetitionProblems = nil
                }
            } message: { problems in
                Text("edit.save.overwrite-warning-\(problems)")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("general.cancel", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    createConfirmButton("general.save") {
                        if let editedHabit,
                           let repetition
                        {
                            let repetitionProblems = editedHabit.checkNewRepetition(repetition)

                            if repetitionProblems > 0 {
                                self.repetitionProblems = repetitionProblems
                                self.saveConfirmationDialogShown = true
                                return
                            }
                        }
                        save()
                    }
                    .disabled(!allowed || defaultProblem || name.isEmpty)
                }
            }
            .onChange(of: goal) {
                if goalAmount < 1 {
                    goalAmount = 1
                }
            }
            .onChange(of: repetitionCustom) {
                if repetitionCustom < 1 {
                    repetitionCustom = 1
                }
            }
            .animation(.default, value: allowed)
            .animation(.default, value: defaultProblem)
            .animation(.default, value: name.isEmpty)
            .animation(.default, value: repetition)
        }
        .interactiveDismissDisabled()
    }

    func save() {
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        description = description.trimmingCharacters(in: .whitespacesAndNewlines)

        var storedSymbol: String? = nil

        if !symbol.isEmpty {
            storedSymbol = symbol
        }

        if let editedHabit {
            editedHabit.name = name
            editedHabit.textDescription = description
            editedHabit.symbol = storedSymbol
            editedHabit.setRepetitionAndGoal(rep: repetition, goal: goal)
            editedHabit.dayDefault = dayDefault
        } else {
            guard let newHabit = Habit(name: name, textDescription: description, symbol: storedSymbol, repetition: repetition,
                                       goal: goal, firstDay: referenceDate(), dayDefault: dayDefault)
            else {
                logger().error("Couldn't create habit! This should never happen.")
                return
            }

            modelContext.insert(newHabit)
        }

        do {
            try modelContext.save()
        } catch let err {
            logger().error("Can't save model context at the moment: \(err)")
        }

        dismiss()
    }
}

private enum RepetitionType {
    case normal
    case repetitive
    case unlimited
}

#Preview {
    HabitEditView(referenceDate: { .now })
        .modelContainer(getPreviewContainer())
}
