import TipKit

struct SwipeTip: Tip {
    
    var title: Text {
        Text("tips.swipe.title")
    }
    
    var message: Text? {
        Text("tips.swipe.message")
    }
    
    var image: Image? {
        Image(systemName: "hand.draw.fill")
    }
    
    var rules: [Rule] {
        #Rule(ContentView.$numberOfHabits) { num in
            num > 0
        }
        #Rule(HabitRowView.ViewModel.userSwiped) { swipeEvents in
            swipeEvents.donations.count == 0
        }
    }
}

struct CreateTip: Tip {
    
    var title: Text {
        Text("tips.create.title")
    }
    
    var message: Text? {
        Text("tips.create.message")
    }
    
    var image: Image? {
        Image(systemName: "square.and.pencil")
    }
    
    var rules: [Rule] {
        #Rule(ContentView.$numberOfHabits) { num in
            num == 0
        }
        #Rule(HabitEditView.userCreatedHabit) { createdEvents in
            createdEvents.donations.count == 0
        }
    }
}

struct EvalTodayTip: Tip {
    var title: Text {
        Text("tips.eval-today.title")
    }
    
    var message: Text? {
        Text("tips.eval-today.message")
    }
    
    var image: Image? {
        Image(systemName: "checkmark.circle.fill")
    }
    
    var rules: [Rule] {
        #Rule(ContentView.$numberOfHabits) { num in
            num > 0
        }
        #Rule(HabitRowView.ViewModel.userSwiped) { swipeEvents in
            swipeEvents.donations.count == 0
        }
    }
}

struct EvalTotalTip: Tip {
    var title: Text {
        Text("tips.eval-total.title")
    }
    
    var message: Text? {
        Text("tips.eval-total.message")
    }
    
    var image: Image? {
        Image(systemName: "chart.bar.fill")
    }
    
    var rules: [Rule] {
        #Rule(ContentView.$numberOfHabits) { num in
            num > 0
        }
        #Rule(HabitRowView.ViewModel.userSwiped) { swipeEvents in
            swipeEvents.donations.count > 0
        }
    }
}
