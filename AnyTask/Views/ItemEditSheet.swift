import SwiftUI

struct ItemEditSheet: View {
    @Bindable var item: Item
    var sections: [TaskSection]
    var onSave: (Item) -> Void
    var onCancel: () -> Void

    @State private var editedText: String
    @State private var selectedSection: TaskSection
    @State private var dueDate: Date
    @State private var hasDueDate: Bool

    init(item: Item, sections: [TaskSection], onSave: @escaping (Item) -> Void, onCancel: @escaping () -> Void) {
        self.item = item
        self.sections = sections
        self.onSave = onSave
        self.onCancel = onCancel
        _editedText = State(initialValue: item.taskText)
        _selectedSection = State(initialValue: item.parentSection ?? sections.first!)
        _dueDate = State(initialValue: item.dueDate ?? Date())
        _hasDueDate = State(initialValue: item.dueDate != nil)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task")) {
                    TextField("Task Name", text: $editedText)
                }
                Section(header: Text("Section")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(sections) { section in
                                Button(action: {
                                    selectedSection = section
                                }) {
                                    Text(section.name)
                                        .padding(10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedSection.id == section.id ? Color.fromName(section.colorName) : Color.clear)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color.fromName(section.colorName), lineWidth: 2)
                                                )
                                        )
                                        .foregroundColor(Color.primary)
                                }
                                .disabled(!section.isEditable && section != selectedSection)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
                Section(header: Text("Notify at:")) {
                    Toggle("Date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarItems(
                leading: Button("Cancel", action: onCancel),
                trailing: Button("Save") {
                    item.taskText = editedText
                    item.parentSection = selectedSection
                    item.dueDate = hasDueDate ? dueDate : nil
                    onSave(item)
                    if item.dueDate != nil {
                        NotificationManager.scheduleNotification(for: item)
                    }
                }
            )
        }
    }
}
