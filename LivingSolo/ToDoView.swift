import SwiftUI
import SwiftData

@Model
class ToDoItem {
    var title: String
    var priority: String
    var isDone: Bool

    init(title: String, priority: String = "None", isDone: Bool = false) {
        self.title = title
        self.priority = priority
        self.isDone = isDone
    }
}

struct ToDoView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ToDoItem.priority) private var items: [ToDoItem]  // temporary; we'll sort manually

    @State private var newTitle: String = ""
    @State private var newPriority: String = "None"

    private let priorities = ["High", "Priority", "None"]

    var body: some View {
        NavigationView {
            VStack {
                // Add new task
                VStack() {
                    HStack {
                        TextField("New task...", text: $newTitle) 
                            .font(.system(size: 18, weight: .medium))

                        
                        Picker("Priority", selection: $newPriority) {
                            ForEach(priorities, id: \.self) { p in
                                Text(p)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Button("+") {
                            addItem()
                        }
                        .font(.system(size: 30, weight: .heavy))
                        .buttonStyle(.plain)
                      
                        
                        
                        
                    }
                    .padding()
                }
                .background(Color.gray.opacity(0.1))
            

                // Task list (sorted manually by priority order)
                List {
                    ForEach(sortedItems) { item in
                        HStack {
                            Button(action: { toggleDone(item) }) {
                                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(item.isDone ? .green : .gray)
                            }

                            VStack(alignment: .leading) {
                                Text(item.title)
                                    .strikethrough(item.isDone)
                                    .foregroundColor(item.isDone ? .gray : .primary)
                                Text(item.priority)
                                    .font(.caption)
                                    .foregroundColor(colorForPriority(item.priority))
                            }
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .navigationTitle("To-Do List")
            .toolbar {
                EditButton()
            }
        }
    }

    // MARK: - Computed property
    private var sortedItems: [ToDoItem] {
        items.sorted {
            if $0.isDone == $1.isDone {
                // If both are done or not done, sort by priority
                return priorityRank($0.priority) < priorityRank($1.priority)
            } else {
                // Unfinished (false) before finished (true)
                return !$0.isDone && $1.isDone
            }
        }
    }

    // MARK: - Helper functions
    private func priorityRank(_ priority: String) -> Int {
        switch priority {
        case "High": return 0
        case "Priority": return 1
        default: return 2
        }
    }

    private func colorForPriority(_ priority: String) -> Color {
        switch priority {
        case "High": return .red
        case "Priority": return .orange
        default: return .gray
        }
    }

    private func addItem() {
        let newItem = ToDoItem(title: newTitle, priority: newPriority)
        context.insert(newItem)
        do {
            try context.save()
            newTitle = ""
            newPriority = "None"
        } catch {
            print("Failed to save item: \(error)")
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            context.delete(sortedItems[index])
        }
        do {
            try context.save()
        } catch {
            print("Delete error: \(error)")
        }
    }

    private func toggleDone(_ item: ToDoItem) {
        item.isDone.toggle()
        do {
            try context.save()
        } catch {
            print("Toggle error: \(error)")
        }
    }
}

#Preview {
    ToDoView()
        .modelContainer(for: ToDoItem.self)
}
