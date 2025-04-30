import SwiftUI


struct ItemEditSheet: View {
    @Bindable var item: Item
    var sections: [TaskSection]
    var onSave: (Item) -> Void
    var onCancel: () -> Void

    @State private var editedText: String
    @State private var selectedSection: TaskSection
    @State private var dueDate: Date

    init(item: Item, sections: [TaskSection], onSave: @escaping (Item) -> Void, onCancel: @escaping () -> Void) {
        self.item = item
        self.sections = sections
        self.onSave = onSave
        self.onCancel = onCancel
        _editedText = State(initialValue: item.taskText)
        _selectedSection = State(initialValue: item.parentSection ?? sections.first!)
        _dueDate = State(initialValue: item.dueDate ?? Date())
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task")) {
                    TextField("Task Name", text: $editedText)
                }
                Section(header: Text("Section")) {
                    Picker("Section", selection: $selectedSection) {
                        ForEach(sections) { section in
                            Text(section.name).tag(section)
                        }
                    }
                }
                Section(header: Text("Due Date")) {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarItems(leading: Button("Cancel", action: onCancel), trailing: Button("Save") {
                item.taskText = editedText
                item.parentSection = selectedSection
                item.dueDate = dueDate
                onSave(item)
            })
        }
    }
}
