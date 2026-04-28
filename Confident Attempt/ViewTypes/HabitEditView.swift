import SwiftUI
import Confident_Attempt_Model
import SwiftData

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
    
    private var goal: CompletionGoal {
        goalScale.toCompletionGoal(withNum: goalAmount)
    }
    
    private var allowed: Bool {
        Habit.testValues(repetition: repetition, goal: goal)
    }
    
    private var nameAllowed: Bool {
        if let editedHabit, editedHabit.name == name {
            return true
        }
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { habit in
                habit.name == name
            }
        )
        
        if let existing = try? modelContext.fetch(descriptor),
           !existing.isEmpty {
            return false
        }
        
        return true
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
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    CustomTextField(TextField("Name", text: $name))
                    CustomTextField(TextField("Description", text: $description))
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
                
                if !nameAllowed {
                    Text("The name of the habit must be unique!")
                        .listRowBackground(Color.red)
                        .font(.title3)
                }
            }
            .navigationTitle("\(editedHabit == nil ? "Add" : "Edit") Habit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                     createConfirmButton("Save") {
                        guard nameAllowed else {return}
                        
                        if let editedHabit {
                            editedHabit.name = name
                            editedHabit.textDescription = description
                            editedHabit.setRepetitionAndGoal(rep: repetition, goal: goal)
                        } else {
                            guard let newHabit = Habit(name: name, textDescription: description, repetition: repetition, goal: goal) else {return}
                            
                            modelContext.insert(newHabit)
                        }
                        
                        dismiss()
                    }
                    .disabled(!allowed || name.isEmpty || !nameAllowed)
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
            .animation(.default, value: nameAllowed)
            .animation(.default, value: name.isEmpty)
            .animation(.default, value: repetition)
        }
        .interactiveDismissDisabled()
    }
}

fileprivate enum RepetitionType {
    case normal
    case repetitive
    case unlimited
}

#Preview {
    HabitEditView()
}
