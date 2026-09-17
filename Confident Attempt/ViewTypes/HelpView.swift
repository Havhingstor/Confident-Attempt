import SwiftUI
import TipKit

struct HelpView: View {
    let appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
    var preferences: Preferences
    
    @State var showTipsReloadHint = false

    var body: some View {
        List {
            Section {
                Text("help.author-name")
                Link(destination: URL(string: "https://github.com/Havhingstor/Confident-Attempt/issues")!, label: {
                    Text("help.issues")
                })
                Link(destination: URL(string: "https://github.com/Havhingstor/Confident-Attempt")!, label: {
                    Text("help.github")
                })
                Text("help.version-\(appVersion)")
            }

            Section("help.tips") {
                Text("help.tips.swipe")
                Text("help.tips.first-day")
                Button("help.tips.reload") {
                    preferences.storeTipsReload()
                    showTipsReloadHint = true
                }
                .alert("help.tips.reload.restart-hint", isPresented: $showTipsReloadHint, actions: {})
            }
            
            Section("help.libraries") {
                Link("CalendarView", destination: URL(string: "https://github.com/AllanJuenemann/CalendarView")!)
                Link("SFSymbolsPickerForSwiftUI", destination: URL(string: "https://github.com/alessiorubicini/SFSymbolsPickerForSwiftUI")!)
                Link("TaskGate", destination: URL(string: "https://github.com/mattmassicotte/TaskGate")!)
            }
        }
        .navigationTitle("help.title")
    }
}

#Preview {
    NavigationStack {
        HelpView(preferences: Preferences())
    }
}
