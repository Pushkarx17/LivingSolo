import SwiftUI
import SwiftData

@main
struct LivingSoloApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Expense.self, KitchenItem.self, ToDoItem.self])
    }
}
