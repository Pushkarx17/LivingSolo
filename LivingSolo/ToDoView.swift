import SwiftUI
import SwiftData

@Model
class ToDoItem {
    var title: String
    var priority: String
    var isDone: Bool
    var dueDate: Date?

    init(title: String, priority: String = "Low", isDone: Bool = false, dueDate: Date? = nil) {
        self.title = title
        self.priority = priority
        self.isDone = isDone
        self.dueDate = dueDate
    }
}

struct ToDoView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ToDoItem.priority) private var items: [ToDoItem]

    @State private var newTitle = ""
    @State private var newPriority = "Low"
    @State private var newDueDate = Date()
    @State private var hasDueDate = false

    private let priorities = ["High", "Medium", "Low"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                inputBar

                List {
                    ForEach(sortedItems) { item in
                        taskRow(item)
                    }
                    .onDelete(perform: deleteItems)
                }
                .listStyle(.plain)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("To Do")
            .toolbar { EditButton() }
        }
    }

    private var inputBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                TextField("New task…", text: $newTitle)
                    .font(.system(size: 16, weight: .medium))

                Picker("Priority", selection: $newPriority) {
                    ForEach(priorities, id: \.self) { Text($0) }
                }
                .pickerStyle(.menu)

                Button {
                    addItem()
                } label: {
                    Image(systemName: "plus.circle.fill").font(.title2)
                }
                .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            HStack {
                Toggle("Due date", isOn: $hasDueDate.animation())
                    .font(.caption)
                if hasDueDate {
                    DatePicker("", selection: $newDueDate, displayedComponents: .date)
                        .labelsHidden()
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func taskRow(_ item: ToDoItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Button { toggleDone(item) } label: {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isDone ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 5) {
                Text(item.title)
                    .strikethrough(item.isDone)
                    .foregroundStyle(item.isDone ? .secondary : .primary)

                HStack(spacing: 6) {
                    let pColor = colorForPriority(item.priority)
                    Text(item.priority)
                        .font(.caption2).fontWeight(.semibold)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(pColor.opacity(0.15))
                        .foregroundStyle(pColor)
                        .cornerRadius(4)

                    if let due = item.dueDate {
                        let overdue = !item.isDone && due < Calendar.current.startOfDay(for: Date())
                        Text(due, format: .dateTime.day().month(.abbreviated))
                            .font(.caption2)
                            .foregroundStyle(overdue ? .red : .secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var sortedItems: [ToDoItem] {
        items.sorted {
            if $0.isDone != $1.isDone { return !$0.isDone }
            let r = priorityRank($0.priority) - priorityRank($1.priority)
            if r != 0 { return r < 0 }
            let d0 = $0.dueDate ?? .distantFuture
            let d1 = $1.dueDate ?? .distantFuture
            return d0 < d1
        }
    }

    private func priorityRank(_ p: String) -> Int { p == "High" ? 0 : p == "Medium" ? 1 : 2 }

    private func colorForPriority(_ p: String) -> Color {
        p == "High" ? .red : p == "Medium" ? .orange : .blue
    }

    private func addItem() {
        let trimmed = newTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let item = ToDoItem(title: trimmed, priority: newPriority, dueDate: hasDueDate ? newDueDate : nil)
        context.insert(item)
        try? context.save()
        newTitle = ""
        newPriority = "Low"
        hasDueDate = false
    }

    private func deleteItems(at offsets: IndexSet) {
        offsets.forEach { context.delete(sortedItems[$0]) }
        try? context.save()
    }

    private func toggleDone(_ item: ToDoItem) {
        item.isDone.toggle()
        try? context.save()
    }
}

#Preview {
    ToDoView()
        .modelContainer(for: ToDoItem.self)
}
