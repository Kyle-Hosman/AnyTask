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
    // Repeat notification states
    @State private var repeatNotification: Bool
    @State private var repeatInterval: TimeInterval

    init(item: Item, sections: [TaskSection], onSave: @escaping (Item) -> Void, onCancel: @escaping () -> Void) {
        self.item = item
        self.sections = sections
        self.onSave = onSave
        self.onCancel = onCancel
        _editedText = State(initialValue: item.taskText)
        _selectedSection = State(initialValue: item.parentSection ?? sections.first!)
        _dueDate = State(initialValue: item.dueDate ?? Date())
        _hasDueDate = State(initialValue: item.dueDate != nil)
        _repeatNotification = State(initialValue: item.repeatNotification)
        _repeatInterval = State(initialValue: item.repeatInterval ?? 3600) // Default 1 hour
    }

    var body: some View {
        NavigationView {
            Form {
                taskSection
                sectionSection
                notifySection
            }
            .navigationTitle("Edit Task")
            .navigationBarItems(
                leading: Button("Cancel", action: onCancel),
                trailing: Button("Save") {
                    item.taskText = editedText
                    item.parentSection = selectedSection
                    item.dueDate = hasDueDate ? dueDate : nil
                    item.repeatNotification = hasDueDate ? repeatNotification : false
                    item.repeatInterval = (hasDueDate && repeatNotification) ? repeatInterval : nil
                    onSave(item)
                    if item.dueDate != nil {
                        NotificationManager.scheduleNotification(for: item)
                    }
                }
            )
        }
    }

    private var taskSection: some View {
        Section(header: Text("Task")) {
            TextField("Task Name", text: $editedText)
        }
    }

    private var sectionSection: some View {
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
    }

    private var notifySection: some View {
        Section(header: Text("Notify at:")) {
            Toggle("Date", isOn: $hasDueDate)
            if hasDueDate {
                DatePicker("", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    //.minuteInterval(5)
                Toggle("Repeat", isOn: $repeatNotification)
                if repeatNotification {
                    RepeatIntervalRow(repeatInterval: $repeatInterval)
                    Text(intervalString(for: repeatInterval))
                }
            }
        }
    }

    // Helper for interval string
    private func intervalString(for interval: TimeInterval) -> String {
        switch interval {
        case 900: return "15 min"
        case 1800: return "30 min"
        case 3600: return "1 hour"
        case 7200: return "2 hours"
        case 86400: return "1 day"
        case 604800: return "1 week"
        case 60: return "1 min"
        default: return "Custom"
        }
    }
    private struct RepeatIntervalRow: View {
        @Binding var repeatInterval: TimeInterval
        var body: some View {
            HStack {
                Text("Repeat every")
                Spacer()
                Picker("Interval", selection: $repeatInterval) {
                    Text("1 min").tag(60.0)
                    Text("15 min").tag(900.0)
                    Text("30 min").tag(1800.0)
                    Text("1 hour").tag(3600.0)
                    Text("2 hours").tag(7200.0)
                    Text("1 day").tag(86400.0)
                    Text("1 week").tag(604800.0)
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
    }
}
