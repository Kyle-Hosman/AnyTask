//
//  ContentView.swift
//  AnyTask
//
//  Created by Kyle Hosman on 1/10/25.
//

import SwiftUI
import SwiftData
import UserNotifications

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sectionsQuery: [TaskSection]
    @Query private var itemsQuery: [Item]

    @State private var newTaskText: String = ""
    @FocusState private var isInputFieldFocused: Bool
    @FocusState private var focusedItemID: UUID?
    @State private var selectedSection: TaskSection?
    @State private var isShowingNewSectionSheet: Bool = false
    @State private var isShowingEditSectionSheet: Bool = false
    @State private var sectionToEdit: TaskSection?
    @State private var sectionToDelete: TaskSection?
    @State private var isShowingDeleteConfirmation: Bool = false
    @State private var editModeState: EditMode = .inactive
    @State private var editingItem: Item? = nil
    @State private var pendingSection: TaskSection? = nil
    @State private var pendingSectionAssignments: [UUID: TaskSection] = [:]
    @State private var animatingOutIDs: Set<UUID> = []

    var sections: [TaskSection] {
        sectionsQuery.sorted { $0.order < $1.order }
    }

    var sortedItems: [Item] {
        itemsQuery
            .filter { $0.parentSection == selectedSection }
            .sorted { $0.order < $1.order }
    }

    var body: some View {
        NavigationStack {
            VStack {
                sectionSelector
                inputSection
                taskList
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("New Section") {
                        isShowingNewSectionSheet = true
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(editModeState == .active ? "Done" : "Edit") {
                        if editModeState == .active {
                            // Start animation
                            let idsToAnimate = Set(pendingSectionAssignments.keys)
                            animatingOutIDs = idsToAnimate
                            // Wait for animation, then move items
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                withAnimation(.easeInOut) {
                                    for (itemID, newSection) in pendingSectionAssignments {
                                        if let item = itemsQuery.first(where: { $0.id == itemID }) {
                                            item.parentSection = newSection
                                        }
                                    }
                                    try? modelContext.save()
                                    pendingSectionAssignments.removeAll()
                                    animatingOutIDs.removeAll()
                                }
                            }
                        }
                        withAnimation {
                            editModeState = (editModeState == .active) ? .inactive : .active
                        }
                    }
                }
            }
            .onAppear {
                requestNotificationPermission()
                if sectionsQuery.isEmpty {
                    initializeDefaultSection()
                } else {
                    restoreLastSelectedSection()
                }
                if selectedSection == nil {
                    selectedSection = sectionsQuery.first
                }
                
            }
            .navigationTitle("AnyTask")
            .navigationBarTitleDisplayMode(.large)
        }
        .environment(\.editMode, $editModeState)
        .sheet(isPresented: Binding<Bool>(
            get: { editingItem != nil },
            set: { if !$0 { editingItem = nil } }
        )) {
            if let item = editingItem {
                ItemEditSheet(
                    item: item,
                    sections: sections,
                    onSave: { _ in editingItem = nil },
                    onCancel: { editingItem = nil }
                )
            }
        }
        .sheet(isPresented: $isShowingNewSectionSheet) {
            NewSectionView { sectionName, colorName in
                addSection(name: sectionName, colorName: colorName)
            }
        }
        .sheet(isPresented: $isShowingEditSectionSheet, onDismiss: {
            sectionToEdit = nil
        }) {
            if let sectionToEdit = sectionToEdit {
                NewSectionView(initialName: sectionToEdit.name, initialColor: sectionToEdit.colorName) { sectionName, colorName in
                    editSection(sectionToEdit, newName: sectionName, newColor: colorName)
                }
            }
        }
        .confirmationDialog(
            "Are you sure you want to delete this section?",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            if let section = sectionToDelete {
                Button("Delete", role: .destructive) {
                    deleteSection(section)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Section Selector
    // In ContentView.swift

    private var sectionSelector: some View {
        VStack(spacing: 0) {
            if let anySection = sections.first(where: { $0.name == "Any" }) {
                Button(action: {
                    if editModeState == .active && selectedSection?.name == "Any" {
                        // Do nothing or reset pendingSection if needed
                    } else {
                        selectSection(anySection)
                        pendingSection = nil
                    }
                }) {
                    Text("Any")
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedSection?.id == anySection.id ? Color.fromName(anySection.colorName) : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.fromName(anySection.colorName), lineWidth: 2)
                                )
                        )
                        .foregroundColor(.black)
                        .font(.headline)
                }
                .padding(.horizontal)
                .padding(.bottom, 6)
            }

            // Show all other sections except "Any"
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(sections.filter { $0.name != "Any" }) { section in
                        Button(action: {
                            if editModeState == .active && selectedSection?.name == "Any" {
                                if section.id != selectedSection?.id {
                                    pendingSection = section
                                }
                            } else {
                                selectSection(section)
                                pendingSection = nil
                            }
                        }) {
                            Text(section.name)
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            (editModeState == .active && selectedSection?.name == "Any" && section.id == pendingSection?.id)
                                            ? Color.fromName(section.colorName)
                                            : (selectedSection?.id == section.id ? Color.fromName(section.colorName) : Color.clear)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.fromName(section.colorName), lineWidth: 2)
                                        )
                                )
                                .foregroundColor(.black)
                                .opacity(
                                    (editModeState == .active && selectedSection?.name == "Any" && section.id != selectedSection?.id)
                                    ? 0.7 : 1.0
                                )
                        }
                        .contextMenu {
                            if section.isEditable {
                                Button("Edit Section") {
                                    sectionToEdit = section
                                    isShowingEditSectionSheet = true
                                }
                                Button("Delete Section", role: .destructive) {
                                    sectionToDelete = section
                                    isShowingDeleteConfirmation = true
                                }
                            } else {
                                Text("This section cannot be edited or deleted")
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 0)
        }
        .padding(.top)
    }
    
    
    // MARK: - TextField
    private var inputSection: some View {
        HStack {
            TextField("Enter task", text: $newTaskText)
                .padding()
                .background(Color(Color.fromName(selectedSection?.colorName ?? ".gray")))
                .cornerRadius(16)
                .font(.system(size: 18))
                .focused($isInputFieldFocused)
                
                .tint(Color.fromName(selectedSection?.colorName ?? ".gray"))
                .onSubmit {
                    addItem()
                    isInputFieldFocused = true
                }
        }
        .padding(.horizontal)
        .padding(.vertical)
    }
    
    // MARK: - Task List
    private var taskList: some View {
        List {
            ForEach(sortedItems) { item in
                TaskRowView(
                    item: item,
                    editModeState: editModeState,
                    selectedSection: selectedSection,
                    pendingSection: pendingSection,
                    pendingSectionAssignments: $pendingSectionAssignments,
                    focusedItemID: $focusedItemID,
                    editingItem: $editingItem,
                    toggleTaskCompletion: toggleTaskCompletion,
                    modelContext: modelContext,
                    save: { try? modelContext.save() },
                    isAnimatingOut: animatingOutIDs.contains(item.id)
                )
            }
            .onMove(perform: moveItems)
            .onDelete(perform: deleteItems)
        }
        .listRowSpacing(10)
        .environment(\.editMode, $editModeState)
    }
    
    // MARK: - TaskRowView
    struct TaskRowView: View {
        let item: Item
        let editModeState: EditMode
        let selectedSection: TaskSection?
        let pendingSection: TaskSection?
        @Binding var pendingSectionAssignments: [UUID: TaskSection]
        var focusedItemID: FocusState<UUID?>.Binding
        @Binding var editingItem: Item?
        let toggleTaskCompletion: (Item) -> Void
        let modelContext: ModelContext
        let save: () -> Void
        let isAnimatingOut: Bool

        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 4.0) {
                    if editModeState != .active {
                        Text(item.taskText)
                            .font(.body)
                    } else {
                        TextField("Task Name", text: Binding(
                            get: { item.taskText },
                            set: { newValue in
                                item.taskText = newValue
                                try? modelContext.save()
                            }
                        ))
                        .focused(focusedItemID, equals: item.id)
                        .disabled(editModeState == .active)
                    }

                    if let dueDate = item.dueDate {
                        Text(dueDate, format: Date.FormatStyle(date: .numeric, time: .shortened))
                            .font(.footnote)
                            .foregroundColor(.black)
                    }
                }
                .padding(.all, 10)

                Spacer()

                if editModeState != .active {
                    Button(action: {
                        toggleTaskCompletion(item)
                    }) {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.black, lineWidth: 2)
                            .frame(width: 28, height: 28)
                            .overlay(
                                item.taskComplete ?
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.black)
                                    : nil
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 44, height: 44) // Larger tappable area
                    .padding(.trailing, 10)
                    
                } else {
                    Button(action: {
                        editingItem = item
                    }) {
                        ZStack {
                            Image(systemName: "pencil")
                                .foregroundColor(.black)
                        }
                    }
                    .font(.title2)
                    .padding(.trailing, 10)
                }
            }
            .padding(.vertical, 8)
            .background(
                Color.fromName(
                    (editModeState == .active &&
                     selectedSection?.name == "Any" &&
                     pendingSectionAssignments[item.id] != nil)
                    ? pendingSectionAssignments[item.id]?.colorName ?? ".gray"
                    : selectedSection?.colorName ?? ".gray"
                )
            )
            .cornerRadius(8)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
            .contentShape(Rectangle())
            .onTapGesture {
                        if editModeState == .active,
                           selectedSection?.name == "Any",
                           let newSection = pendingSection,
                           item.parentSection?.name == "Any" {
                            pendingSectionAssignments[item.id] = newSection
                        } else if editModeState != .active {
                            editingItem = item
                        }
                    }
            .scaleEffect(isAnimatingOut ? 0.1 : 1.0)
            .opacity(isAnimatingOut ? 0.0 : 1.0)
            .offset(x: isAnimatingOut ? 100 : 0, y: isAnimatingOut ? -40 : 0)
            .animation(.easeInOut(duration: 0.4), value: isAnimatingOut)
        }
    }

    // MARK: - Functions
    private func selectSection(_ section: TaskSection) {
        selectedSection = section
        saveLastSelectedSection(section)
    }

    private func addItem() {
        guard let selectedSection = selectedSection, !newTaskText.isEmpty else { return }
        withAnimation {
            let maxOrder = itemsQuery.map { $0.order }.max() ?? 0
            let newItem = Item(
                taskText: newTaskText,
                taskComplete: false,
                timestamp: Date(),
                order: maxOrder + 1,
                parentSection: selectedSection
            )
            modelContext.insert(newItem)
            newTaskText = ""
            if newItem.dueDate != nil {
                scheduleNotification(for: newItem)
            }
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        let filteredItems = sortedItems
        for index in offsets {
            let item = filteredItems[index]
            cancelNotification(for: item)
            modelContext.delete(item)
        }
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        var reorderedItems = sortedItems
        reorderedItems.move(fromOffsets: source, toOffset: destination)
        for (index, item) in reorderedItems.enumerated() {
            item.order = index
        }
        do {
            try modelContext.save()
        } catch {
            print("Error saving reordering changes: \(error)")
        }
    }

    private func toggleTaskCompletion(_ item: Item) {
        item.taskComplete.toggle()
        try? modelContext.save()
    }

    private func addSection(name: String, colorName: String) {
        withAnimation {
            let maxOrder = sectionsQuery.map { $0.order }.max() ?? 0
            let newSection = TaskSection(name: name, colorName: colorName, order: maxOrder + 1)
            modelContext.insert(newSection)
            selectedSection = newSection
        }
    }

    private func editSection(_ section: TaskSection, newName: String, newColor: String) {
        if let existingSection = sectionsQuery.first(where: { $0.id == section.id }) {
            existingSection.name = newName
            existingSection.colorName = newColor
            try? modelContext.save()
        }
    }

    private func deleteSection(_ section: TaskSection) {
        withAnimation {
            let itemsToDelete = itemsQuery.filter { $0.parentSection == section }
            for item in itemsToDelete {
                modelContext.delete(item)
            }
            modelContext.delete(section)
            selectedSection = sectionsQuery.first
        }
    }

    private func initializeDefaultSection() {
        let generalSection = TaskSection(name: "Any", colorName: ".gray", isEditable: false, order: 0)
        modelContext.insert(generalSection)
        selectedSection = generalSection
    }

    private func saveLastSelectedSection(_ section: TaskSection) {
        UserDefaults.standard.set(section.id.uuidString, forKey: "LastSelectedSectionID")
    }

    private func restoreLastSelectedSection() {
        if let lastSelectedID = UserDefaults.standard.string(forKey: "LastSelectedSectionID"),
           let lastSection = sectionsQuery.first(where: { $0.id.uuidString == lastSelectedID }) {
            selectedSection = lastSection
        }
    }

    // MARK: - Notification Helpers
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    private func scheduleNotification(for item: Item) {
        guard let dueDate = item.dueDate else { return }
        let content = UNMutableNotificationContent()
        content.title = "Task Due"
        content.body = item.taskText
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(dueDate.timeIntervalSinceNow, 1), repeats: false)
        let request = UNNotificationRequest(identifier: item.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    private func cancelNotification(for item: Item) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
    }
}

// MARK: - Preview
#Preview {
    PreviewContainer()
}

struct PreviewContainer: View {
    let modelContainer: ModelContainer

    init() {
        let container = try! ModelContainer(for: Item.self, TaskSection.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        insertPreviewData(into: context)
        self.modelContainer = container
    }

    var body: some View {
        ContentView()
            .modelContainer(modelContainer)
    }
}

// Function to Insert Sample Data
private func insertPreviewData(into context: ModelContext) {
    let fetchRequest = FetchDescriptor<Item>()
    if (try? context.fetch(fetchRequest).isEmpty) == true {
        let sampleSection = TaskSection(name: "Any", colorName: ".gray", isEditable: false, order: 0)
        context.insert(sampleSection)
        let sampleItems = [
            Item(taskText: "Buy Groceries", taskComplete: false, timestamp: Date(), order: 0, parentSection: sampleSection),
            Item(taskText: "Finish Project", taskComplete: false, timestamp: Date().addingTimeInterval(-3600), order: 1, parentSection: sampleSection),
            Item(taskText: "Pet Jerm", taskComplete: true, timestamp: Date().addingTimeInterval(-7200), order: 2, parentSection: sampleSection)
        ]
        sampleItems.forEach { context.insert($0) }
        
        let sampleSection2 = TaskSection(name: "To-Do", colorName: ".green", isEditable: true, order: 1)
        context.insert(sampleSection2)
        let sampleItems2 = [
            Item(taskText: "Work Out", taskComplete: false, timestamp: Date(), order: 0, parentSection: sampleSection2),
            Item(taskText: "Walk Jerm", taskComplete: false, timestamp: Date().addingTimeInterval(-3600), order: 1, parentSection: sampleSection2),
            Item(taskText: "Give Jerm breakfast", taskComplete: true, timestamp: Date().addingTimeInterval(-7200), order: 2, parentSection: sampleSection2)
        ]
        sampleItems2.forEach { context.insert($0) }
        
        let sampleSection3 = TaskSection(name: "Reminders", colorName: ".red", isEditable: true, order: 2)
        context.insert(sampleSection3)
        let sampleItems3 = [
            Item(taskText: "Develop app", taskComplete: true, timestamp: Date(), order: 0, parentSection: sampleSection3),
            Item(taskText: "Tune bike", taskComplete: false, timestamp: Date().addingTimeInterval(-3600), order: 1, parentSection: sampleSection3),
            Item(taskText: "Do laundry", taskComplete: false, timestamp: Date().addingTimeInterval(-7200), order: 2, parentSection: sampleSection3)
        ]
        sampleItems3.forEach { context.insert($0) }
        
        let sampleSection4 = TaskSection(name: "Shopping", colorName: ".blue", isEditable: true, order: 3)
        context.insert(sampleSection4)
        let sampleItems4 = [
            Item(taskText: "Eggs", taskComplete: false, timestamp: Date(), order: 0, parentSection: sampleSection4),
            Item(taskText: "Milk", taskComplete: false, timestamp: Date().addingTimeInterval(-3600), order: 1, parentSection: sampleSection4),
            Item(taskText: "Tomatoes", taskComplete: true, timestamp: Date().addingTimeInterval(-7200), order: 2, parentSection: sampleSection4),
            Item(taskText: "Potatoes", taskComplete: true, timestamp: Date().addingTimeInterval(-7200), order: 3, parentSection: sampleSection4)
        ]
        sampleItems4.forEach { context.insert($0) }
    }
}

