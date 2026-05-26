import SwiftUI

struct AboutView: View {
    @AppStorage("currencySymbol") private var currencySymbol: String = "£"

    private let currencyOptions = ["£", "$", "€", "¥", "₹", "A$", "C$", "CHF"]

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Picker("Currency Symbol", selection: $currencySymbol) {
                        ForEach(currencyOptions, id: \.self) { Text($0).tag($0) }
                    }
                }

                Section("Support") {
                    Link(destination: URL(string: "mailto:pushkargowda39923993@gmail.com?subject=LivingSolo%20Feedback")!) {
                        Label("Send Feedback", systemImage: "envelope")
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(appVersion) (\(buildNumber))").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Developer")
                        Spacer()
                        Text("Pushkar K U").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    AboutView()
}
