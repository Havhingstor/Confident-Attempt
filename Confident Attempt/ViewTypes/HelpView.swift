import SwiftUI

struct HelpView: View {
    let appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""

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
                Text("help.tips.daily-limit")
                Text("help.tips.evaluation-today")
                Text("help.tips.evaluation")
                Text("help.tips.details")
                Text("help.tips.first-day")
            }
        }
        .navigationTitle("help.title")
    }
}

#Preview {
    NavigationStack {
        HelpView()
    }
}
