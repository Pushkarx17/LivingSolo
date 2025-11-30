import SwiftUI
import SwiftData

// MARK: - Model
@Model
class Category: Identifiable {
    var id: UUID = UUID()
    var name: String
    @Relationship(deleteRule: .cascade)
    var items: [KitchenItem] = []

    init(name: String) {
        self.name = name
    }
}

@Model
class KitchenItem: Identifiable {
    var id: UUID = UUID()
    var name: String
    var quantity: Int
    var expiryDate: Date
    @Relationship(inverse: \Category.items)
    var category: Category?

    init(name: String, quantity: Int, expiryDate: Date, category: Category?) {
        self.name = name
        self.quantity = quantity
        self.expiryDate = expiryDate
        self.category = category
    }
}

// MARK: - Kitchen View (Modern)
struct KitchenView: View {
    @Query(sort: \Category.name, order: .forward)
    var categories: [Category]

    @Environment(\.modelContext) private var modelContext
    @State private var showingAddItem = false
    @State private var showingAddCategory = false
    @State private var searchText = ""
    @State private var selectedCategoryID: UUID? = nil
    @State private var showDeleteAlert = false
    @State private var categoryToDelete: Category?

    private let gridColumns = [GridItem(.flexible())]

    var filteredCategories: [Category] {
        if searchText.isEmpty {
            return categories
        }
        var results: [Category] = []
        for c in categories {
            if c.name.localizedCaseInsensitiveContains(searchText) {
                results.append(c)
                continue
            }
            for item in c.items {
                if item.name.localizedCaseInsensitiveContains(searchText) {
                    results.append(c)
                    break
                }
            }
        }
        return results
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                header

                if categories.isEmpty {
                    emptyState
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: gridColumns, spacing: 16) {
                            ForEach(filteredCategories) { category in
                                CategoryCard(category: category,
                                             onDelete: { askToDelete(category) })
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Kitchen")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCategory = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                            .symbolRenderingMode(.hierarchical)
                    }
                    Button {
                        showingAddItem = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddKitchenItemView(categories: categories)
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView()
            }
            .onAppear { addDefaultCategoriesIfNeeded() }
            .alert("Delete Category", isPresented: $showDeleteAlert, presenting: categoryToDelete) { category in
                Button("Delete", role: .destructive) {
                    deleteCategory(category)
                }
                Button("Cancel", role: .cancel) {}
            } message: { category in
                Text("Delete \"\(category.name)\" and all its items? This cannot be undone.")
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .animation(.default, value: filteredCategories)
            .padding(.top, 4)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading) {
                Text("Pantry at a glance")
                    .font(.title2)
                    .bold()
                Text("Items expiring soon are highlighted - to add items tap on top right corner")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.arrow.triangle.circlepath")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .padding(20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            Text("Your kitchen is looking fresh — add your first category or item")
                .font(.headline)
            HStack(spacing: 12) {
                Button(action: { showingAddCategory = true }) {
                    Label("Add Category", systemImage: "folder.badge.plus")
                }
                .buttonStyle(.borderedProminent)

                Button(action: { showingAddItem = true }) {
                    Label("Add Item", systemImage: "plus")
                }
                .buttonStyle(.bordered)
            }
        }
        .multilineTextAlignment(.center)
        .foregroundColor(.secondary)
        .padding()
    }

    private func askToDelete(_ category: Category) {
        categoryToDelete = category
        showDeleteAlert = true
    }


    private func addDefaultCategoriesIfNeeded() {
        let ctx = modelContext
        let defaultCategoryNames = ["Refrigerator", "Freezer", "Cupboard", "Pantry"]
        let existingNames = Set(categories.map { $0.name })
        for name in defaultCategoryNames where !existingNames.contains(name) {
            let c = Category(name: name)
            ctx.insert(c)
        }
        try? ctx.save()
    }

    private func deleteCategory(_ category: Category) {
        guard let ctx = category.modelContext else { return }
        ctx.delete(category)
        try? ctx.save()
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    var category: Category
    var onDelete: () -> Void

    private var sortedItems: [KitchenItem] {
        category.items.sorted { $0.expiryDate < $1.expiryDate }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.name)
                    .font(.headline)
                Spacer()
                Menu {
                    Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .imageScale(.large)
                }
            }

            if sortedItems.isEmpty {
                Text("No items yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            } else {
                ForEach(sortedItems.prefix(5)) { item in
                    KitchenItemRow(item: item)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(UIColor.systemBackground).opacity(0.001))
                        )
                }
                if sortedItems.count > 5 {
                    Text("+ \(sortedItems.count - 5) more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 6)
    }
}

// MARK: - Item Row
struct KitchenItemRow: View {
    var item: KitchenItem
    @Environment(\.modelContext) private var modelContext

    private var daysUntilExpiry: Int {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.startOfDay(for: item.expiryDate)
        return Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
    }

    private var expiryColor: Color {
        if daysUntilExpiry < 1 { return .red }
        if daysUntilExpiry <= 3 { return .orange }
        return .secondary
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                    .bold()
                HStack {
                    Text("Qty: \(item.quantity)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(item.expiryDate, format: .dateTime.day().month(.abbreviated).year())
                        .font(.caption2)
                        .foregroundColor(expiryColor)
                }
            }

            Spacer()

            HStack(spacing: 10) {
                Button {
                    decrementQuantity()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)

                Button {
                    incrementQuantity()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { deleteItem() } label: { Label("Remove", systemImage: "trash") }
        }
    }

    private func decrementQuantity() {
        guard let ctx = item.modelContext else { return }
        if item.quantity > 0 { item.quantity -= 1 }
        if item.quantity == 0 { ctx.delete(item) }
        try? ctx.save()
    }

    private func incrementQuantity() {
        guard let ctx = item.modelContext else { return }
        item.quantity += 1
        try? ctx.save()
    }

    private func deleteItem() {
        guard let ctx = item.modelContext else { return }
        ctx.delete(item)
        try? ctx.save()
    }
}

// MARK: - Add Item View
struct AddKitchenItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var categories: [Category]

    @State private var name = ""
    @State private var quantity = 1
    @State private var expiryDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var selectedCategoryID: UUID?
    @State private var isCreatingNewCategory = false
    @State private var newCategoryName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name", text: $name)
                    Stepper(value: $quantity, in: 1...999) {
                        Text("Quantity: \(quantity)")
                    }
                    DatePicker("Expiry", selection: $expiryDate, displayedComponents: .date)
                }

                Section("Category") {
                    if isCreatingNewCategory {
                        TextField("New category name", text: $newCategoryName)
                        HStack {
                            Button("Create") {
                                createNewCategoryAndSelect()
                            }
                            .disabled(newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                            Spacer()
                            Button("Cancel") { isCreatingNewCategory = false }
                        }
                    } else {
                        Picker("Category", selection: $selectedCategoryID) {
                            Text("Choose...").tag(UUID?.none)
                            ForEach(categories, id: \.id) { c in
                                Text(c.name).tag(Optional(c.id))
                            }
                            Text("Add new category...").tag(UUID?.none)
                        }
                        .onChange(of: selectedCategoryID) { _, newValue in
                            if newValue == nil { isCreatingNewCategory = true }
                        }
                    }
                }
            }
            .navigationTitle("Add Item")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveItem()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || selectedCategoryID == nil)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func createNewCategoryAndSelect() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let ctx = modelContext
        let c = Category(name: trimmed)
        ctx.insert(c)
        try? ctx.save()
        selectedCategoryID = c.id
        newCategoryName = ""
        isCreatingNewCategory = false
    }

    private func saveItem() {
        let ctx = modelContext
        guard let catID = selectedCategoryID else { return }
        guard let category = categories.first(where: { $0.id == catID }) else { return }
        let item = KitchenItem(name: name.trimmingCharacters(in: .whitespaces),
                               quantity: quantity,
                               expiryDate: expiryDate,
                               category: category)
        ctx.insert(item)
        try? ctx.save()
    }
}

// MARK: - Add Category View
struct AddCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var categoryName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Category name", text: $categoryName)
                }
            }
            .navigationTitle("Add Category")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        addCategory()
                        dismiss()
                    }
                    .disabled(categoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func addCategory() {
        let ctx = modelContext
        let c = Category(name: categoryName.trimmingCharacters(in: .whitespaces))
        ctx.insert(c)
        try? ctx.save()
    }
}

// MARK: - Preview
#Preview {
    KitchenView()
        .modelContainer(for: [KitchenItem.self, Category.self])
}
