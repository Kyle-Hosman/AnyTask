import SwiftUI

struct ItemEditSheet: View {
    @Bindable var item: Item
    var sections: [TaskSection]
    var onSave: (Item) -> Void
    var onCancel: () -> Void

    @State private var editedText: String
    @State private var selectedSection: TaskSection
    @State private var dueDate: Date
    @State private var hasDueDate: Bool // deprecated
    @State private var repeatIntervalType: RepeatIntervalType
    // Replace hasDate, hasTime, selectedDate, selectedTime with:
    @State private var hasDateTime: Bool
    @State private var selectedDateTime: Date

    init(item: Item, sections: [TaskSection], onSave: @escaping (Item) -> Void, onCancel: @escaping () -> Void) {
        self.item = item
        self.sections = sections
        self.onSave = onSave
        self.onCancel = onCancel
        _editedText = State(initialValue: item.taskText)
        _selectedSection = State(initialValue: item.parentSection ?? sections.first!)
        let initialDate = item.dueDate ?? Date()
        _dueDate = State(initialValue: initialDate)
        _hasDueDate = State(initialValue: item.dueDate != nil) // deprecated
        _repeatIntervalType = State(initialValue: item.repeatIntervalType ?? .never)
        // New state
        if let dueDate = item.dueDate {
            _hasDateTime = State(initialValue: true)
            _selectedDateTime = State(initialValue: dueDate)
        } else {
            _hasDateTime = State(initialValue: false)
            // Round up to next 5-minute interval
            let now = Date()
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
            if let minute = components.minute {
                let remainder = minute % 5
                if remainder != 0 {
                    components.minute = minute + (5 - remainder)
                    if components.minute! >= 60 {
                        components.minute = 0
                        if let hour = components.hour {
                            components.hour = hour + 1
                        }
                    }
                }
            }
            components.second = 0
            let roundedDate = calendar.date(from: components) ?? now
            _selectedDateTime = State(initialValue: roundedDate)
        }
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
                    if hasDateTime {
                        item.dueDate = selectedDateTime
                        item.repeatIntervalType = repeatIntervalType
                    } else {
                        item.dueDate = nil
                        item.repeatIntervalType = .never
                    }
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
        UIDatePicker.appearance().minuteInterval = 5
        let dateTimeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter
        }()
        return Section(header: Text("Notify at:")) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Date & Time")
                    if hasDateTime {
                        Text(dateTimeFormatter.string(from: selectedDateTime))
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                Spacer()
                Toggle("", isOn: $hasDateTime)
                    .labelsHidden()
            }
            if hasDateTime {
                DatePicker("", selection: $selectedDateTime, displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                DatePicker("", selection: $selectedDateTime, displayedComponents: [.hourAndMinute])
                    .datePickerStyle(.wheel)
                RepeatIntervalRow(repeatIntervalType: $repeatIntervalType)
            }
        }
    }

    private struct RepeatIntervalRow: View {
        @Binding var repeatIntervalType: RepeatIntervalType
        var body: some View {
            HStack {
                Text("Repeat:")
                Spacer()
                Picker("", selection: $repeatIntervalType) {
                    ForEach(RepeatIntervalType.allCases, id: \ .self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
}

#if DEBUG
struct ItemEditSheet_Previews: PreviewProvider {
    static var previews: some View {
        let sampleSection = TaskSection(id: UUID(), name: "Personal", colorName: "blue", isEditable: true, order: 0, iconName: "person")
        let otherSection = TaskSection(id: UUID(), name: "Work", colorName: "green", isEditable: true, order: 1, iconName: "briefcase")
        let sampleItem = Item(
            taskText: "Sample Task",
            taskComplete: false,
            timestamp: Date(),
            order: 0,
            parentSection: sampleSection,
            dueDate: Date().addingTimeInterval(3600),
            repeatIntervalType: .never
        )
        return ItemEditSheet(
            item: sampleItem,
            sections: [sampleSection, otherSection],
            onSave: { _ in },
            onCancel: {}
        )
    }
}
#endif
