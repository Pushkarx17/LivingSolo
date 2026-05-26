import SwiftUI
import SwiftData

@Model
class Expense: Identifiable {
    var id: UUID = UUID()
    var name: String
    var amount: Double
    var date: Date = Date()
    var expenseCategory: String = "Other"
    var isRecurring: Bool = true

    init(name: String, amount: Double, expenseCategory: String = "Other", isRecurring: Bool = true) {
        self.name = name
        self.amount = amount
        self.date = Date()
        self.expenseCategory = expenseCategory
        self.isRecurring = isRecurring
    }
}

struct BudgetView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Expense.name) private var expenses: [Expense]

    @AppStorage("budgetLimit") private var budgetLimit: Double = 0
    @AppStorage("currencySymbol") private var currencySymbol: String = "£"

    @State private var name = ""
    @State private var amount = ""
    @State private var selectedCategory = "Other"
    @State private var isRecurring = true
    @State private var showingLimitSheet = false
    @State private var limitInput = ""

    private let expenseCategories = ["Food", "Transport", "Subscriptions", "Housing", "Other"]

    var monthlyTotal: Double { expenses.reduce(0) { $0 + $1.amount } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if budgetLimit > 0 { progressCard }
                inputCard

                List {
                    ForEach(expenses) { expense in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(expense.name).font(.headline)
                                HStack(spacing: 6) {
                                    Text(expense.expenseCategory)
                                        .font(.caption2).fontWeight(.semibold)
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundStyle(.blue)
                                        .cornerRadius(4)
                                    if !expense.isRecurring {
                                        Text("One-off")
                                            .font(.caption2).fontWeight(.semibold)
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(Color.purple.opacity(0.1))
                                            .foregroundStyle(.purple)
                                            .cornerRadius(4)
                                    }
                                }
                            }
                            Spacer()
                            Text("\(currencySymbol)\(expense.amount, specifier: "%.2f")")
                                .font(.headline)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteExpense)
                }
                .listStyle(.plain)

                totalCard
            }
            .navigationTitle("Budget")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        limitInput = budgetLimit > 0 ? String(format: "%.0f", budgetLimit) : ""
                        showingLimitSheet = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showingLimitSheet) { limitSheet }
        }
    }

    private var progressCard: some View {
        let fraction = min(monthlyTotal / budgetLimit, 1.0)
        let tint: Color = fraction >= 0.9 ? .red : fraction >= 0.7 ? .orange : .green
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Budget limit").font(.caption).fontWeight(.semibold).foregroundStyle(.secondary).textCase(.uppercase)
                Spacer()
                Text("\(currencySymbol)\(monthlyTotal, specifier: "%.2f") / \(currencySymbol)\(budgetLimit, specifier: "%.0f")")
                    .font(.caption).bold()
            }
            ProgressView(value: fraction).tint(tint)
                .scaleEffect(x: 1, y: 2, anchor: .center)
            Text(fraction >= 1 ? "Over budget!" : "\(Int((1 - fraction) * 100))% remaining")
                .font(.caption2).foregroundStyle(fraction >= 1 ? .red : .secondary)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        .padding(.horizontal)
    }

    private var inputCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                TextField("Expense name", text: $name)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))

                TextField("\(currencySymbol)0.00", text: $amount)
                    .keyboardType(.decimalPad)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    .frame(width: 110)
            }

            HStack(spacing: 10) {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(expenseCategories, id: \.self) { Text($0) }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)

                Toggle("Recurring", isOn: $isRecurring)
                    .font(.caption)
            }

            Button(action: addExpense) {
                Label("Add Expense", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(colors: [.blue.opacity(0.85), .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || Double(amount) == nil)
            .opacity((name.trimmingCharacters(in: .whitespaces).isEmpty || Double(amount) == nil) ? 0.6 : 1)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)).shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4))
        .padding(.horizontal)
    }

    private var totalCard: some View {
        HStack {
            Text("Estimated monthly total")
                .font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text("\(currencySymbol)\(monthlyTotal, specifier: "%.2f")")
                .font(.title3).bold()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)).shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var limitSheet: some View {
        NavigationStack {
            Form {
                Section("Monthly Budget Limit") {
                    TextField("e.g. 1200", text: $limitInput)
                        .keyboardType(.decimalPad)
                }
                if budgetLimit > 0 {
                    Section {
                        Button("Remove limit", role: .destructive) {
                            budgetLimit = 0
                            showingLimitSheet = false
                        }
                    }
                }
            }
            .navigationTitle("Budget Limit")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let v = Double(limitInput) { budgetLimit = v }
                        showingLimitSheet = false
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingLimitSheet = false }
                }
            }
        }
    }

    private func addExpense() {
        guard let value = Double(amount) else { return }
        let e = Expense(name: name.trimmingCharacters(in: .whitespaces), amount: value,
                        expenseCategory: selectedCategory, isRecurring: isRecurring)
        context.insert(e)
        try? context.save()
        name = ""; amount = ""; selectedCategory = "Other"; isRecurring = true
    }

    private func deleteExpense(at offsets: IndexSet) {
        offsets.forEach { context.delete(expenses[$0]) }
        try? context.save()
    }
}

#Preview {
    BudgetView()
        .modelContainer(for: Expense.self, inMemory: true)
}
