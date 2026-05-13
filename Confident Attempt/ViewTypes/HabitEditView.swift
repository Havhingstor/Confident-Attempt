import Confident_Attempt_Model
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
    @State private var symbol: String = ""
    @State private var symbolPickerShown = false
    @State private var saveConfirmationDialogShown = false
    @State private var repetitionProblems: UInt? = nil

    private var goal: CompletionGoal {
        goalScale.toCompletionGoal(withNum: goalAmount)
    }

    private var allowed: Bool {
        Habit.testValues(repetition: repetition, goal: goal)
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

    var repetitionTypeHelpText: String {
        switch repetitionType {
        case .normal:
            "A habit that can be completed once per day."
        case .repetitive:
            "A habit that can be completed multiple times per day, up to a limit of \(repetitionCustom)."
        case .unlimited:
            "A habit that can be completed multiple times per day."
        }
    }

    init(editedHabit: Habit? = nil) {
        self.editedHabit = editedHabit

        if let editedHabit {
            _name = State(initialValue: editedHabit.name)
            _description = State(initialValue: editedHabit.textDescription)
            _goalScale = State(initialValue: .fromCompletionGoal(editedHabit.goal))
            _goalAmount = State(initialValue: editedHabit.goal.getNumber())
            _symbol = State(initialValue: editedHabit.symbol ?? "")

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
                    CustomTextField(TextField("Name", text: $name))
                    CustomTextField(TextField("Description", text: $description))
                    HStack {
                        Image(systemName: actualSymbol)
                            .font(.title)
                            .frame(width: 28, height: 27)
                            .foregroundStyle(.blue)

                        Spacer()

                        HStack(spacing: 12) {
                            Button("Choose") {
                                symbolPickerShown = true
                            }

                            Button("Reset", role: .destructive) {
                                symbol = ""
                            }
                            .foregroundStyle(.red)
                        }
                    }
                    .foregroundStyle(.tint)
                    .buttonStyle(.borderless)
                }

                Section("Goal") {
                    LabeledTextField(label: "Amount", TextField("Amount", value: $goalAmount, format: .number))
                        .keyboardType(.numberPad)

                    Picker("Scale", selection: $goalScale) {
                        Text("per Day")
                            .tag(TimeScale.day)
                        Text("per Week")
                            .tag(TimeScale.week)
                        Text("per Month")
                            .tag(TimeScale.month)
                        Text("per Year")
                            .tag(TimeScale.year)
                    }
                }

                Section("Repetition") {
                    Picker("Type", selection: $repetitionType) {
                        Text("Normal")
                            .tag(RepetitionType.normal)
                        Text("Repetitive")
                            .tag(RepetitionType.repetitive)
                        Text("Unlimited")
                            .tag(RepetitionType.unlimited)
                    }
                    .pickerStyle(.segmented)
                    Text(repetitionTypeHelpText)
                    if repetitionType == .repetitive {
                        LabeledTextField(label: "Maximum Number", TextField("Maximum Number", value: $repetitionCustom, format: .number))
                            .keyboardType(.numberPad)
                    }
                }

                if !allowed {
                    Text("The current goal cannot be reached with the current repetition!")
                        .listRowBackground(Color.red)
                        .font(.title3)
                }

                if name.isEmpty {
                    Text("The name of the habit can't be empty!")
                        .listRowBackground(Color.red)
                        .font(.title3)
                }
            }
            .navigationTitle("\(editedHabit == nil ? "Add" : "Edit") Habit")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $symbolPickerShown, content: {
                SymbolsPicker(selection: $symbol, title: "Choose a symbol", autoDismiss: true)
            })
            .alert("Save Habit", isPresented: $saveConfirmationDialogShown, presenting: repetitionProblems) { _ in
                Button("Save anyways", role: .destructive) {
                    save()
                }
                Button("Cancel", role: .cancel) {
                    repetitionProblems = nil
                }
            } message: { problems in
                Text("The new repetition setting would overwrite the completion number in \(problems) day\(problems == 1 ? "" : "s")")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    createConfirmButton("Save") {
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
                    .disabled(!allowed || name.isEmpty)
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
        } else {
            guard let newHabit = Habit(name: name, textDescription: description, symbol: storedSymbol, repetition: repetition, goal: goal) else { return }

            modelContext.insert(newHabit)
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
    HabitEditView()
        .modelContainer(getPreviewContainer())
}
