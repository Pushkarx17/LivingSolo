import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    @Query private var kitchenItems: [KitchenItem]

    private var expiringTodayCount: Int {
        let tomorrow = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        return kitchenItems.filter { $0.expiryDate < tomorrow }.count
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "house.fill") }
                .tag(0)

            KitchenView()
                .tabItem { Label("Kitchen", systemImage: "refrigerator.fill") }
                .badge(expiringTodayCount > 0 ? expiringTodayCount : 0)
                .tag(1)

            BudgetView()
                .tabItem { Label("Budget", systemImage: "sterlingsign.gauge.chart.leftthird.topthird.rightthird") }
                .tag(2)

            ToDoView()
                .tabItem { Label("To Do", systemImage: "checklist") }
                .tag(3)
        }
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Expense.self, KitchenItem.self, Category.self, ToDoItem.self, configurations: config)
        return ContentView().modelContainer(container)
    } catch {
        fatalError("Failed to create SwiftData container: \(error)")
    }
}
