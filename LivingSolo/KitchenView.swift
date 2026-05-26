import SwiftUI
import SwiftData

// MARK: - Models

@Model
class Category: Identifiable {
    var id: UUID = UUID()
    var name: String
    @Relationship(deleteRule: .cascade)
    var items: [KitchenItem] = []

    init(name: String) { self.name = name }
}

@Model
class KitchenItem: Identifiable {
    var id: UUID = UUID()
    var name: String
    var quantity: Int
    var expiryDate: Date
    var onShoppingList: Bool = false
    @Relationship(inverse: \Category.items)
    var category: Category?

    init(name: String, quantity: Int, expiryDate: Date, category: Category?) {
        self.name = name
        self.quantity = quantity
        self.expiryDate = expiryDate
        self.category = category
    }
}

// MARK: - Kitchen View

struct KitchenView: View {
    @Query(sort: \Category.name, order: .forward) var categories: [Category]
    @Environment(\.modelContext) private var modelContext

    @State private var showingAddItem = false
    @State private var showingAddCategory = false
    @State private var showingShoppingList = false
    @State private var searchText = ""
    @State private var showDeleteAlert = false
    @State private var categoryToDelete: Category?

    private let gridColumns = [GridItem(.flexible())]

    var filteredCategories: [Category] {
        guard !searchText.isEmpty else { return categories }
        return categories.filter { c in
            c.name.localizedCaseInsensitiveContains(searchText) ||
            c.items.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    private var shoppingListCount: Int {
        categories.flatMap { $0.items }.filter { $0.onShoppingList }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                header

                if categories.isEmpty {
                    emptyState.frame(maxWidth: .infinity, maxHeight: .infinity).padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: gridColumns, spacing: 16) {
                            ForEach(filteredCategories) { category in
                                CategoryCard(category: category, onDelete: { askToDelete(category) })
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
                        showingShoppingList = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "cart").imageScale(.large)
                            if shoppingListCount > 0 {
                                Text("\(shoppingListCount)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(3)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 8, y: -6)
                            }
                        }
                    }
                    Button { showingAddCategory = true } label: {
                        Image(systemName: "folder.badge.plus").symbolRenderingMode(.hierarchical)
                    }
                    Button { showingAddItem = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2).symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) { AddKitchenItemView(categories: categories) }
            .sheet(isPresented: $showingAddCategory) { AddCategoryView() }
            .sheet(isPresented: $showingShoppingList) { ShoppingListView() }
            .onAppear { addDefaultCategoriesIfNeeded() }
            .alert("Delete Category", isPresented: $showDeleteAlert, presenting: categoryToDelete) { cat in
                Button("Delete", role: .destructive) { deleteCategory(cat) }
                Button("Cancel", role: .cancel) {}
            } message: { cat in
                Text("Delete \"\(cat.name)\" and all its items? This cannot be undone.")
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .animation(.default, value: filteredCategories)
            .padding(.top, 4)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading) {
                Text("Pantry at a glance").font(.title2).bold()
                Text("Items expiring soon are highlighted — tap any item to edit")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.arrow.triangle.circlepath")
                .resizable().scaledToFit()
                .frame(width: 80, height: 80)
                .padding(20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            Text("Your kitchen is looking fresh — add your first category or item")
                .font(.headline)
            HStack(spacing: 12) {
                Button { showingAddCategory = true } label: {
                    Label("Add Category", systemImage: "folder.badge.plus")
                }
                .buttonStyle(.borderedProminent)
                Button { showingAddItem = true } label: {
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
        categoryToDelete = category; showDeleteAlert = true
    }

    private func addDefaultCategoriesIfNeeded() {
        let existing = Set(categories.map { $0.name })
        for name in ["Refrigerator", "Freezer", "Cupboard", "Pantry"] where !existing.contains(name) {
            modelContext.insert(Category(name: name))
        }
        try? modelContext.save()
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
                Text(category.name).font(.headline)
                Spacer()
                Menu {
                    Button(role: .destructive) { onDelete() } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle").imageScale(.large)
                }
            }

            if sortedItems.isEmpty {
                Text("No items yet")
                    .font(.subheadline).foregroundColor(.secondary).padding(.top, 8)
            } else {
                ForEach(sortedItems.prefix(5)) { item in
                    KitchenItemRow(item: item)
                        .padding(.vertical, 6)
                }
                if sortedItems.count > 5 {
                    Text("+ \(sortedItems.count - 5) more")
                        .font(.caption).foregroundColor(.secondary)
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
    @State private var isEditing = false

    private var daysUntilExpiry: Int {
        let cal = Calendar.current
        return cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: cal.startOfDay(for: item.expiryDate)).day ?? 0
    }

    private var expiryColor: Color {
        daysUntilExpiry < 1 ? .red : daysUntilExpiry <= 3 ? .orange : .secondary
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.name).font(.subheadline).bold()
                    if item.onShoppingList {
                        Image(systemName: "cart.fill")
                            .font(.caption2).foregroundStyle(.blue)
                    }
                }
                HStack {
                    Text("Qty: \(item.quantity)").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text(item.expiryDate, format: .dateTime.day().month(.abbreviated).year())
                        .font(.caption2).foregroundColor(expiryColor)
                }
            }

            Spacer()

            HStack(spacing: 10) {
                Button { decrementQuantity() } label: {
                    Image(systemName: "minus.circle.fill").font(.title3)
                }
                .buttonStyle(.plain)
                Button { incrementQuantity() } label: {
                    Image(systemName: "plus.circle.fill").font(.title3)
                }
                .buttonStyle(.plain)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { isEditing = true }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { deleteItem() } label: {
                Label("Remove", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                item.onShoppingList.toggle()
                try? modelContext.save()
            } label: {
                Label(item.onShoppingList ? "Remove" : "Shopping", systemImage: item.onShoppingList ? "cart.badge.minus" : "cart.badge.plus")
            }
            .tint(.blue)
        }
        .sheet(isPresented: $isEditing) {
            EditKitchenItemView(item: item)
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

// MARK: - Edit Item View

struct EditKitchenItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.name) private var categories: [Category]

    var item: KitchenItem

    @State private var name: String
    @State private var quantity: Int
    @State private var expiryDate: Date
    @State private var selectedCategoryID: UUID?

    init(item: KitchenItem) {
        self.item = item
        _name = State(initialValue: item.name)
        _quantity = State(initialValue: item.quantity)
        _expiryDate = State(initialValue: item.expiryDate)
        _selectedCategoryID = State(initialValue: item.category?.id)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name", text: $name)
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...999)
                    DatePicker("Expiry", selection: $expiryDate, displayedComponents: .date)
                }
                Section("Category") {
                    Picker("Category", selection: $selectedCategoryID) {
                        Text("None").tag(UUID?.none)
                        ForEach(categories, id: \.id) { c in
                            Text(c.name).tag(Optional(c.id))
                        }
                    }
                }
            }
            .navigationTitle("Edit Item")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func saveChanges() {
        item.name = name.trimmingCharacters(in: .whitespaces)
        item.quantity = quantity
        item.expiryDate = expiryDate
        if let catID = selectedCategoryID {
            item.category = categories.first { $0.id == catID }
        } else {
            item.category = nil
        }
        try? modelContext.save()
    }
}

// MARK: - Shopping List View

struct ShoppingListView: View {
    @Query(filter: #Predicate<KitchenItem> { $0.onShoppingList == true },
           sort: \KitchenItem.name) private var shoppingItems: [KitchenItem]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if shoppingItems.isEmpty {
                    ContentUnavailableView(
                        "Shopping list is empty",
                        systemImage: "cart",
                        description: Text("Swipe right on any kitchen item to add it.")
                    )
                } else {
                    List {
                        ForEach(shoppingItems) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name).font(.headline)
                                    Text(item.category?.name ?? "Uncategorised")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button {
                                    item.onShoppingList = false
                                    try? modelContext.save()
                                } label: {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3).foregroundStyle(.green)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Shopping List")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
                if !shoppingItems.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Clear all") {
                            shoppingItems.forEach { $0.onShoppingList = false }
                            try? modelContext.save()
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
        }
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
                    Stepper(value: $quantity, in: 1...999) { Text("Quantity: \(quantity)") }
                    DatePicker("Expiry", selection: $expiryDate, displayedComponents: .date)
                }

                Section("Category") {
                    if isCreatingNewCategory {
                        TextField("New category name", text: $newCategoryName)
                        HStack {
                            Button("Create") { createNewCategoryAndSelect() }
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
                    Button("Save") { saveItem(); dismiss() }
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
        let c = Category(name: trimmed)
        modelContext.insert(c)
        try? modelContext.save()
        selectedCategoryID = c.id
        newCategoryName = ""
        isCreatingNewCategory = false
    }

    private func saveItem() {
        guard let catID = selectedCategoryID,
              let category = categories.first(where: { $0.id == catID }) else { return }
        let item = KitchenItem(name: name.trimmingCharacters(in: .whitespaces),
                               quantity: quantity, expiryDate: expiryDate, category: category)
        modelContext.insert(item)
        try? modelContext.save()
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
                    Button("Save") { addCategory(); dismiss() }
                        .disabled(categoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func addCategory() {
        let c = Category(name: categoryName.trimmingCharacters(in: .whitespaces))
        modelContext.insert(c)
        try? modelContext.save()
    }
}

// MARK: - Preview

#Preview {
    KitchenView()
        .modelContainer(for: [KitchenItem.self, Category.self])
}
