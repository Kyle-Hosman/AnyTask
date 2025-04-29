//
//  MainTabView.swift
//  AnyTask
//
//  Created by Kyle Hosman on 4/29/25.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sectionsQuery: [TaskSection]
    @Query private var itemsQuery: [Item]

    @Binding var newTaskText: String
    @FocusState.Binding var isInputFieldFocused: Bool
    @FocusState.Binding var focusedItemID: UUID?
    @Binding var selectedSection: TaskSection?
    @Binding var isShowingNewSectionSheet: Bool
    @Binding var isShowingEditSectionSheet: Bool
    @Binding var sectionToEdit: TaskSection?
    @Binding var sectionToDelete: TaskSection?
    @Binding var isShowingDeleteConfirmation: Bool

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
                // MARK: Section Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(sections) { section in
                            Button(action: {
                                selectSection(section)
                            }) {
                                Text(section.name)
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedSection?.id == section.id ? Color.fromName(section.colorName) : Color.clear)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.fromName(section.colorName), lineWidth: 2)
                                            )
                                    )
                                    .foregroundColor(.black)
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
                .padding(.top)

                // Input Section
                HStack {
                    Picker(selection: $selectedSection, label: Image(systemName: "folder")) {
                        ForEach(sections) { section in
                            Text(section.name).tag(Optional(section))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 120)

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

                // MARK: Task List
                List {
                    ForEach(sortedItems) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4.0) {
                                TextField("Task Name", text: Binding(
                                    get: { item.taskText },
                                    set: { newValue in
                                        item.taskText = newValue
                                        try? modelContext.save()
                                    }
                                ))
                                .focused($focusedItemID, equals: item.id)
                                .onTapGesture {
                                    focusedItemID = item.id
                                }

                                Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .shortened))
                                    .font(.footnote)
                                    .foregroundColor(.black)
                            }
                            .padding(.leading, 10)

                            Spacer()

                            Button(action: {
                                toggleTaskCompletion(item)
                            }) {
                                Image(systemName: item.taskComplete ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(.black)
                                    .font(.title2)
                            }
                            .padding(.trailing, 10)
                        }
                        .padding(.vertical, 8)
                        .background(Color.fromName(selectedSection?.colorName ?? ".gray"))
                        .cornerRadius(8)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                    }
                    .onMove(perform: moveItems)
                    .onDelete(perform: deleteItems)
                }
                .listStyle(.plain)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("New Section") {
                        isShowingNewSectionSheet = true
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .onAppear {
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

