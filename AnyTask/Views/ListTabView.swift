//
//  SectionsListView.swift
//  AnyTask
//
//  Created by Kyle Hosman on 4/29/25.
//

import SwiftUI
import SwiftData

struct ListTabView: View {
    let sections: [TaskSection]
    let items: [Item]
    
    @State private var selectedSection: TaskSection?
    @Environment(\.modelContext) private var modelContext
    @FocusState private var focusedItemID: UUID?
    
    var sortedItems: [Item] {
        items
            .filter { $0.parentSection == selectedSection }
            .sorted { $0.order < $1.order }
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Section Selector (copied from Main View)
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
                                            .fill(selectedSection?.id == section.id ? Color.fromName(section.colorName) : Color.clear)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.fromName(section.colorName), lineWidth: 2)
                                            )
                                    )
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top)

                // Styled Task List
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
            .onAppear {
                if selectedSection == nil {
                    selectedSection = sections.first
                }
            }
            .navigationTitle("Lists")
        }
    }
    
    private func toggleTaskCompletion(_ item: Item) {
        item.taskComplete.toggle()
        try? modelContext.save()
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
    
    private func deleteItems(at offsets: IndexSet) {
        let filteredItems = sortedItems
        for index in offsets {
            modelContext.delete(filteredItems[index])
        }
    }
}
