import SwiftUI
import Confident_Attempt_Model
import SwiftData

struct HabitEditView: View {
    private var editedHabit: Binding<Habit>?
    @Environment(\.modelContext) private var modelContext
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var maxNum = Optional(UInt8(1))
    @State private var goalScale = TimeScale.day
    @State private var goalAmount = UInt8(1)
    
    private var goal: CompletionGoal {
        goalScale.toCompletionGoal(withNum: goalAmount)
    }
    
    private var allowed: Bool {
        Habit.testValues(maxNum: maxNum, goal: goal)
    }
    
    init(editedHabit: Binding<Habit>? = nil) {
        self.editedHabit = editedHabit
        
        if let editedHabit {
            let editedHabit = editedHabit.wrappedValue
            name = editedHabit.name
            description = editedHabit.textDescription
            maxNum = editedHabit.maxNum
            goalScale = .fromCompletionGoal(editedHabit.goal)
            goalAmount = editedHabit.goal.getNumber()
        }
    }
    
    var body: some View {
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
            
            if !allowed {
                Text("The current goal cannot be reached with the current maximum number!")
                    .listRowBackground(Color.red)
                    .font(.title3)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", role: .confirm) {
                    if let editedHabit {
                        editedHabit.name.wrappedValue = name
                        editedHabit.textDescription.wrappedValue = description
                        editedHabit.maxNum.wrappedValue = maxNum
                        editedHabit.goal.wrappedValue = goal
                    } else {
                        if let new = Habit(name: name, textDescription: description, maxNum: maxNum, goal: goal) {
                            modelContext.insert(new)
                            dismiss()
                        }
                    }
                }
                .disabled(!allowed)
            }
        }
        .onChange(of: goal) {
            if goalAmount < 0 {
                goalAmount = 1
            }
        }
    }
}

#Preview {
    NavigationStack {
        HabitEditView()
    }
}
