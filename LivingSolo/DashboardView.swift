import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var expenses: [Expense]
    @Query private var kitchenItems: [KitchenItem]
    @Query private var todoItems: [ToDoItem]

    @AppStorage("budgetLimit") private var budgetLimit: Double = 0
    @AppStorage("currencySymbol") private var currencySymbol: String = "£"

    private var monthlyTotal: Double { expenses.reduce(0) { $0 + $1.amount } }

    private var expiringItems: [KitchenItem] {
        let threeDaysFromNow = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        return kitchenItems
            .filter { $0.expiryDate <= threeDaysFromNow }
            .sorted { $0.expiryDate < $1.expiryDate }
    }

    private var urgentTasks: [ToDoItem] {
        Array(
            todoItems
                .filter { !$0.isDone && ($0.priority == "High" || $0.priority == "Medium") }
                .sorted { priorityRank($0.priority) < priorityRank($1.priority) }
                .prefix(3)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    greeting
                    budgetCard
                    if !expiringItems.isEmpty { expiryCard }
                    if !urgentTasks.isEmpty { todoCard }
                    if expiringItems.isEmpty && urgentTasks.isEmpty { allClearCard }
                    Spacer(minLength: 20)
                }
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: AboutView()) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                    }
                }
            }
        }
    }

    private var greeting: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.title2).bold()
                Text("Here's your daily snapshot")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
    }

    private var greetingText: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good morning" }
        if h < 17 { return "Good afternoon" }
        return "Good evening"
    }

    private var budgetCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Monthly Budget", systemImage: "chart.bar.fill")
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(currencySymbol)\(monthlyTotal, specifier: "%.2f")")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                if budgetLimit > 0 {
                    Text("/ \(currencySymbol)\(budgetLimit, specifier: "%.0f")")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }

            if budgetLimit > 0 {
                let fraction = min(monthlyTotal / budgetLimit, 1.0)
                let tint: Color = fraction >= 0.9 ? .red : fraction >= 0.7 ? .orange : .green
                ProgressView(value: fraction).tint(tint)
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                Text(fraction >= 1 ? "Over budget!" : "\(Int((1 - fraction) * 100))% remaining")
                    .font(.caption).foregroundStyle(fraction >= 1 ? .red : .secondary)
            } else {
                Text("\(expenses.count) expense\(expenses.count == 1 ? "" : "s") tracked")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }

    private var expiryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Expiring Soon", systemImage: "exclamationmark.triangle.fill")
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(.orange)
                .textCase(.uppercase)

            ForEach(expiringItems.prefix(5)) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name).font(.subheadline).bold()
                        Text(item.category?.name ?? "Uncategorised")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    expiryBadge(for: item)
                }
            }

            if expiringItems.count > 5 {
                Text("+ \(expiringItems.count - 5) more items…")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }

    private func expiryBadge(for item: KitchenItem) -> some View {
        let days = daysUntil(item.expiryDate)
        let label = days < 0 ? "Expired" : days == 0 ? "Today" : "\(days)d"
        let color: Color = days < 1 ? .red : .orange
        return Text(label)
            .font(.caption).bold()
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .cornerRadius(6)
    }

    private func daysUntil(_ date: Date) -> Int {
        let cal = Calendar.current
        return cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: cal.startOfDay(for: date)).day ?? 0
    }

    private var todoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Priority Tasks", systemImage: "checklist")
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            ForEach(urgentTasks) { item in
                HStack(spacing: 10) {
                    Circle()
                        .fill(item.priority == "High" ? Color.red : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(item.title).font(.subheadline)
                    Spacer()
                    if let due = item.dueDate {
                        Text(due, format: .dateTime.day().month(.abbreviated))
                            .font(.caption2)
                            .foregroundStyle(due < Date() ? Color.red : Color.secondary)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }

    private var allClearCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48)).foregroundStyle(.green)
            Text("All clear!").font(.headline)
            Text("No expiring food and no urgent tasks.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }

    private func priorityRank(_ p: String) -> Int {
        p == "High" ? 0 : p == "Medium" ? 1 : 2
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Expense.self, KitchenItem.self, Category.self, ToDoItem.self])
}
