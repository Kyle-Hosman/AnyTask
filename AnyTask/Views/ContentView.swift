//
//  ContentView.swift
//  AnyTask
//
//  Created by Kyle Hosman on 1/10/25.
//

import SwiftUI
import SwiftData

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

    var sections: [TaskSection] {
        sectionsQuery.sorted { $0.order < $1.order }
    }

    var sortedItems: [Item] {
        itemsQuery
            .filter { $0.parentSection == selectedSection }
            .sorted { $0.order < $1.order }
    }

    var body: some View {
        TabView {
            MainTabView(
                newTaskText: $newTaskText,
                isInputFieldFocused: $isInputFieldFocused,
                focusedItemID: $focusedItemID,
                selectedSection: $selectedSection,
                isShowingNewSectionSheet: $isShowingNewSectionSheet,
                isShowingEditSectionSheet: $isShowingEditSectionSheet,
                sectionToEdit: $sectionToEdit,
                sectionToDelete: $sectionToDelete,
                isShowingDeleteConfirmation: $isShowingDeleteConfirmation
            )
            .tabItem {
                Label("Main", systemImage: "house")
            }
            ListTabView(sections: sections, items: itemsQuery)
                .tabItem {
                    Label("Lists", systemImage: "list.bullet.rectangle")
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
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        let filteredItems = sortedItems
        for index in offsets {
            modelContext.delete(filteredItems[index])
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
        let generalSection = TaskSection(name: "General", colorName: ".gray", isEditable: false, order: 0)
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
        let sampleSection = TaskSection(name: "General", colorName: ".gray", isEditable: false, order: 0)
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
