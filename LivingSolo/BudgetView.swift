import SwiftUI
import SwiftData

@Model
class Expense: Identifiable {
    var id: UUID = UUID()
    var name: String
    var amount: Double

    init(name: String, amount: Double) {
        self.name = name
        self.amount = amount
    }
}

struct BudgetView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Expense.name) private var expenses: [Expense]

    @State private var name = ""
    @State private var amount = ""

    var monthlyTotal: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add the expenses you expect every month — subscriptions, groceries, transport, essentials.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Input card
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        TextField("Expense name (e.g. Spotify)", text: $name)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))

                        TextField("£0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                            .frame(width: 120)
                    }

                    Button(action: addExpense) {
                        Label("Add Item", systemImage: "plus")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: [Color.blue.opacity(0.85), Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || amount.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity((name.trimmingCharacters(in: .whitespaces).isEmpty || amount.trimmingCharacters(in: .whitespaces).isEmpty) ? 0.6 : 1)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)).shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4))
                .padding(.horizontal)

                // Expense list
                List {
                    ForEach(expenses) { expense in
                        HStack {
                            Text(expense.name)
                                .font(.headline)
                            Spacer()
                            Text("£\(expense.amount, specifier: "%.2f")")
                                .font(.headline)
                        }
                        .padding(.vertical, 6)
                    }
                    .onDelete(perform: deleteExpense)
                }
                .listStyle(.plain)
                .padding(.horizontal)

                // Monthly total
                VStack(spacing: 6) {
                    HStack {
                        Text("Estimated monthly total")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("£\(monthlyTotal, specifier: "%.2f")")
                            .font(.title3)
                            .bold()
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)).shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3))
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationTitle("Monthly Expenses")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }

    private func addExpense() {
        guard let amountValue = Double(amount) else { return }
        let newExpense = Expense(name: name.trimmingCharacters(in: .whitespaces), amount: amountValue)
        context.insert(newExpense)
        try? context.save()
        name = ""
        amount = ""
    }

    private func deleteExpense(at offsets: IndexSet) {
        for index in offsets {
            context.delete(expenses[index])
        }
        try? context.save()
    }
}

#Preview {
    BudgetView()
        .modelContainer(for: Expense.self, inMemory: true)
}
