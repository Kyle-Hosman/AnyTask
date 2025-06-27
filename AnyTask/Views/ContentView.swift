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
    @Environment(\.colorScheme) var colorScheme

    @Namespace private var taskMoveNamespace // For matchedGeometryEffect

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
    var incompleteItems: [Item] {
        sortedItems.filter { !$0.taskComplete }.sorted { $0.order < $1.order }
    }
    var completeItems: [Item] {
        sortedItems.filter { $0.taskComplete }.sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            VStack {
                sectionSelector
                inputSection
                taskList
            }
            .background(
                colorScheme == .dark
                    ? Color(.secondarySystemBackground)
                    : Color(.tertiarySystemBackground)
            )
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("New Section") {
                        isShowingNewSectionSheet = true
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(editModeState == .active ? "Done" : "Edit") {
                        if editModeState == .active {
                            let idsToAnimate = Set(pendingSectionAssignments.keys)
                            animatingOutIDs = idsToAnimate
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
                        // Dismiss keyboard when entering edit mode
                        if editModeState != .active {
                            isInputFieldFocused = false
                        }
                        withAnimation {
                            editModeState = (editModeState == .active) ? .inactive : .active
                        }
                    }
                }
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
                NewSectionView { sectionName, colorName, iconName in
                    addSection(name: sectionName, colorName: colorName, iconName: iconName)
                }
            }
            .sheet(isPresented: $isShowingEditSectionSheet, onDismiss: {
                sectionToEdit = nil
            }) {
                if let sectionToEdit = sectionToEdit {
                    NewSectionView(initialName: sectionToEdit.name, initialColor: sectionToEdit.colorName, initialIconName: sectionToEdit.iconName) { sectionName, colorName, iconName in
                        editSection(sectionToEdit, newName: sectionName, newColor: colorName, iconName: iconName)
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
                        .foregroundColor(Color.primary)
                        .font(.headline)
                }
                .padding(.horizontal)
                .padding(.bottom, 6)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(sections.filter { $0.name != "Any" }) { section in
                        Button(action: {
                            if editModeState == .active && selectedSection?.name == "Any" {
                                if section.id != selectedSection?.id {
                                    pendingSection = section
                                }
                            } else {
                                isInputFieldFocused = false
                                selectSection(section)
                                pendingSection = nil
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: section.iconName)
                                    .font(.headline)
                                    .foregroundColor(Color.primary)
                                Text(section.name)
                            }
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
                            .foregroundColor(Color.primary)
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
                .tint(.black)
                .highPriorityGesture(TapGesture().onEnded {
                    if editModeState == .active {
                        withAnimation {
                            editModeState = .inactive
                        }
                    } else {
                        isInputFieldFocused = true
                    }
                })
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
        ScrollView {
            VStack(spacing: 24) {
                if !incompleteItems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tasks").font(.headline).padding(.leading, 8)
                        VStack(spacing: 10) {
                            ForEach(incompleteItems) { item in
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
                                    isAnimatingOut: animatingOutIDs.contains(item.id),
                                    showMoveIcon: true,
                                    namespace: taskMoveNamespace
                                )
                                .matchedGeometryEffect(id: item.id, in: taskMoveNamespace)
                            }
                        }
                    }
                }
                if !completeItems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Completed").font(.headline).padding(.leading, 8)
                        VStack(spacing: 10) {
                            ForEach(completeItems) { item in
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
                                    isAnimatingOut: animatingOutIDs.contains(item.id),
                                    showMoveIcon: false,
                                    namespace: taskMoveNamespace
                                )
                                .matchedGeometryEffect(id: item.id, in: taskMoveNamespace)
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
            .padding(.horizontal, 8)
        }
        .background(
            colorScheme == .dark
                ? Color(.tertiarySystemBackground)
                : Color(.secondarySystemBackground)
        )
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
        let showMoveIcon: Bool
        let namespace: Namespace.ID // Add namespace

        var body: some View {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    if editModeState != .active {
                        Text(item.taskText)
                            .font(.body)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .layoutPriority(1)
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
                            .foregroundColor(Color.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

                if editModeState != .active {
                    GeometryReader { geometry in
                        ZStack {
                            //Color.yellow.opacity(0.3) // debug highlight
                            Color.clear

                            HStack {
                                Spacer()
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.black, lineWidth: 2)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        item.taskComplete ?
                                            Image(systemName: "checkmark")
                                                .foregroundColor(Color.primary)
                                            : nil
                                    )
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            toggleTaskCompletion(item)
                        }
                    }
                    .frame(width: 60) // controls overall size of checkbox zone
                        
                } else {
//                    Button(action: {
//                        editingItem = item
//                    }) {
//                        Image(systemName: "pencil")
//                            .foregroundColor(Color.primary)
//                    }
//                    .font(.title2)
                }
            }
            .padding(10) // This gives internal space for both text & checkbox
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
            .moveDisabled(!showMoveIcon) // disables move icon if false
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
            // Insert new item at the top of the incomplete list (order = 0)
            let incomplete = itemsQuery.filter { $0.parentSection == selectedSection && !$0.taskComplete }
            for item in incomplete {
                item.order += 1
            }
            let newItem = Item(
                taskText: newTaskText,
                taskComplete: false,
                timestamp: Date(),
                order: 0,
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

    private func moveIncompleteItems(from source: IndexSet, to destination: Int) {
        var reorderedItems = incompleteItems
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
        withAnimation(.easeInOut) {
            if item.taskComplete {
                // Move from complete to incomplete, restore previous order
                item.taskComplete = false
                if let prevOrder = item.previousOrder {
                    // Shift all incomplete items with order >= prevOrder up by 1
                    let incomplete = itemsQuery.filter { $0.parentSection == selectedSection && !$0.taskComplete && $0.id != item.id }
                    for other in incomplete where other.order >= prevOrder {
                        other.order += 1
                    }
                    item.order = prevOrder
                } else {
                    // If no previousOrder, put at top
                    let incomplete = itemsQuery.filter { $0.parentSection == selectedSection && !$0.taskComplete && $0.id != item.id }
                    for other in incomplete {
                        other.order += 1
                    }
                    item.order = 0
                }
                item.completedAt = nil
                item.previousOrder = nil
            } else {
                // Move from incomplete to complete, store previous order
                item.previousOrder = item.order
                item.taskComplete = true
                item.completedAt = Date()
                // Remove from incomplete order, shift others down
                let incomplete = itemsQuery.filter { $0.parentSection == selectedSection && !$0.taskComplete && $0.id != item.id }
                for other in incomplete where other.order > item.order {
                    other.order -= 1
                }
                item.order = 0 // order is not used for complete list
            }
            try? modelContext.save()
        }
    }

    private func addSection(name: String, colorName: String, iconName: String) {
        withAnimation {
            let maxOrder = sectionsQuery.map { $0.order }.max() ?? 0
            let newSection = TaskSection(name: name, colorName: colorName, order: maxOrder + 1, iconName: iconName)
            modelContext.insert(newSection)
            selectedSection = newSection
        }
    }

    private func editSection(_ section: TaskSection, newName: String, newColor: String, iconName: String) {
        if let existingSection = sectionsQuery.first(where: { $0.id == section.id }) {
            existingSection.name = newName
            existingSection.colorName = newColor
            existingSection.iconName = iconName
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
        let generalSection = TaskSection(name: "Any", colorName: ".gray", isEditable: false, order: 0, iconName: "questionmark")
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
        let sampleSection = TaskSection(name: "Any", colorName: ".gray", isEditable: false, order: 0, iconName: "questionmark")
        context.insert(sampleSection)
        let sampleItems = [
            Item(taskText: "Buy Groceries Buy Groceries Buy Groceries Buy Groceries Buy Groceries Buy Groceries Buy Groceries Buy Groceries Buy Groceries Buy Groceries", taskComplete: false, timestamp: Date(), order: 0, parentSection: sampleSection),
            Item(taskText: "Finish Project", taskComplete: false, timestamp: Date().addingTimeInterval(-3600), order: 1, parentSection: sampleSection),
            Item(taskText: "Pet Jerm", taskComplete: true, timestamp: Date().addingTimeInterval(-7200), order: 2, parentSection: sampleSection)
        ]
        sampleItems.forEach { context.insert($0) }
        
        let sampleSection2 = TaskSection(name: "To-Do", colorName: ".green", isEditable: true, order: 1, iconName: "pencil")
        context.insert(sampleSection2)
        let sampleItems2 = [
            Item(taskText: "Work Out Work Out Work Out Work Out Work Out Work Out Work Out Work Out Work Out Work Out Work Out Work Out", taskComplete: false, timestamp: Date(), order: 0, parentSection: sampleSection2),
            Item(taskText: "Walk Jerm", taskComplete: false, timestamp: Date().addingTimeInterval(-3600), order: 1, parentSection: sampleSection2),
            Item(taskText: "Give Jerm breakfast", taskComplete: true, timestamp: Date().addingTimeInterval(-7200), order: 2, parentSection: sampleSection2)
        ]
        sampleItems2.forEach { context.insert($0) }
        
        let sampleSection3 = TaskSection(name: "Reminders", colorName: ".red", isEditable: true, order: 2, iconName: "flag")
        context.insert(sampleSection3)
        let sampleItems3 = [
            Item(taskText: "Develop app", taskComplete: true, timestamp: Date(), order: 0, parentSection: sampleSection3),
            Item(taskText: "Tune bike", taskComplete: false, timestamp: Date().addingTimeInterval(-3600), order: 1, parentSection: sampleSection3),
            Item(taskText: "Do laundry", taskComplete: false, timestamp: Date().addingTimeInterval(-7200), order: 2, parentSection: sampleSection3)
        ]
        sampleItems3.forEach { context.insert($0) }
        
        let sampleSection4 = TaskSection(name: "Shopping", colorName: ".blue", isEditable: true, order: 3, iconName: "cart")
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
