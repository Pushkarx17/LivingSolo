import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                Text("Coming soon...")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            NavigationLink(destination: AboutView()) {
                                Image(systemName: "setting.fill")
                                    .font(.title2)
                            }
                        }
                    }
                    .navigationTitle("Dashboard")
            }
            .tabItem { Label("Dashboard", systemImage: "house.fill") }
            .tag(0)

            NavigationStack {
                KitchenView()
                    .navigationTitle("Kitchen")
            }
            .tabItem { Label("Kitchen", systemImage: "refrigerator.fill") }
            .tag(1)

            NavigationStack {
                BudgetView()
                    .navigationTitle("Budget")
            }
            .tabItem { Label("Budget", systemImage: "sterlingsign.gauge.chart.leftthird.topthird.rightthird") }
            .tag(2)

            NavigationStack {
                ToDoView()
                    .navigationTitle("To Do")
            }
            .tabItem { Label("To Do", systemImage: "checklist") }
            .tag(3)
        }
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Expense.self, configurations: config)
        
        return ContentView()
                    .modelContainer(container)
        
    }catch {fatalError("Failed to create SwiftData container: \(error)")
    }
}
