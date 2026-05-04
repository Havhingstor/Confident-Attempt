import SwiftUI

struct HelpView: View {
    let appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""

    var body: some View {
        List {
            Section {
                Text("Made with ❤ by Paul Schütz")
                Link(destination: URL(string: "https://github.com/Havhingstor/Confident-Attempt/issues")!, label: {
                    Text("Issues")
                })
                Link(destination: URL(string: "https://github.com/Havhingstor/Confident-Attempt")!, label: {
                    Text("GitHub")
                })
                Text("Version \(appVersion)")
            }

            Section("Tips") {
                Text("Swipe right or left to increase or decrease the number of times you have completed a habit.")
                Text("A habit can be completed either once per day ('normal'), multiple times up to a certain limit ('repeated'), or as often as you like ('unlimited').")
                Text("The symbol on the left is green if today's completions are enough to reach the long-term goal if repeated daily, and red if this is not the case.")
                Text("The remaining text is red if the number of completions is below the minimum for the given period (both of which can be configured in the settings), and green if the number of completions is above the goal. Otherwise, it is yellow.")
            }
        }
        .navigationTitle("Help")
    }
}

#Preview {
    NavigationStack {
        HelpView()
    }
}
