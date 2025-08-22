import WidgetKit
import SwiftUI
import AppIntents
import SwiftData

// Shared SwiftData ModelContainer for widget
let schema = Schema([Item.self, TaskSection.self])
let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.kylehosman.AnyTask")!
let storeURL = containerURL.appendingPathComponent("default.store")
let modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)
let modelContainer = try! ModelContainer(for: schema, configurations: [modelConfiguration])

struct TaskEntry: TimelineEntry {
    let date: Date
    let sectionName: String
    let sectionColorName: String
    let sectionIconName: String
    let sectionID: String // <-- Add this line
    let taskIDs: [String]
    let taskTexts: [String]
    let completedIDs: Set<String>
    let totalCount: Int
    let completedCount: Int
    let refreshToken: UUID
    let availableSections: [SectionButtonInfo]
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(date: Date(), sectionName: "To-Do", sectionColorName: ".green", sectionIconName: "pencil", sectionID: "todo", taskIDs: ["1", "2"], taskTexts: ["Sample Task 1", "Sample Task 2"], completedIDs: [], totalCount: 3, completedCount: 0, refreshToken: UUID(), availableSections: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> ()) {
        Task { @MainActor in
            completion(loadEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> ()) {
        Task { @MainActor in
            let entry = loadEntry()
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }

    @MainActor
    private func loadEntry() -> TaskEntry {
        // Query SwiftData for sections and items
        let context = modelContainer.mainContext
        let sections = (try? context.fetch(FetchDescriptor<TaskSection>())) ?? []
        // Read selected section ID from UserDefaults (App Group)
        let defaults = UserDefaults(suiteName: "group.com.kylehosman.AnyTask")
        let selectedSectionID = defaults?.string(forKey: "LastSelectedSectionID")
        // Find the selected section by ID
        let selectedSection = sections.first(where: { $0.id.uuidString == selectedSectionID }) ?? sections.first ?? TaskSection(name: "No List", colorName: ".gray", isEditable: false, order: 0, iconName: "folder")
        let sectionID = selectedSection.id.uuidString
        let sectionName = selectedSection.name
        let sectionColorName = selectedSection.colorName
        let sectionIconName = selectedSection.iconName
        // Get all items for the section, ordered
        let items = (try? context.fetch(FetchDescriptor<Item>()))?.filter { $0.parentSection?.id == selectedSection.id } ?? []
        let allItems = items.sorted { $0.order < $1.order }
        var completedIDs = Set(allItems.filter { $0.taskComplete }.map { $0.id.uuidString })
        // Section switcher info
        let availableSections = sections.map { SectionButtonInfo(id: $0.id.uuidString, colorName: $0.colorName, iconName: $0.iconName) }
        // --- NEW: Check for toggles in UserDefaults ---
        if let toggles = defaults?.array(forKey: "TasksToToggle") as? [[String: Any]] {
            for toggle in toggles {
                guard let toggledTaskID = toggle["id"] as? String,
                      allItems.contains(where: { $0.id.uuidString == toggledTaskID }) else { continue }
                if completedIDs.contains(toggledTaskID) {
                    completedIDs.remove(toggledTaskID)
                } else {
                    completedIDs.insert(toggledTaskID)
                }
            }
        }
        // --- Sort items: unchecked first, checked last ---
        let sortedWidgetItems = allItems.sorted {
            let lhsChecked = completedIDs.contains($0.id.uuidString)
            let rhsChecked = completedIDs.contains($1.id.uuidString)
            if lhsChecked == rhsChecked {
                return $0.order < $1.order // preserve order within group
            }
            return !lhsChecked // unchecked first
        }
        let widgetTaskIDs = sortedWidgetItems.map { $0.id.uuidString }
        let widgetTaskTexts = sortedWidgetItems.map { $0.taskText }
        let totalCount = allItems.count
        let completedCount = completedIDs.count
        return TaskEntry(
            date: Date(),
            sectionName: sectionName,
            sectionColorName: sectionColorName,
            sectionIconName: sectionIconName,
            sectionID: sectionID,
            taskIDs: Array(widgetTaskIDs.prefix(6)),
            taskTexts: Array(widgetTaskTexts.prefix(6)),
            completedIDs: completedIDs,
            totalCount: totalCount,
            completedCount: completedCount,
            refreshToken: UUID(),
            availableSections: availableSections
        )
    }
}



struct AnyTaskWidgetEntryView: View {
    var entry: TaskEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        //MARK: Accessory Circular Layout
        if family == .accessoryCircular {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(zip(entry.taskIDs, entry.taskTexts).prefix(3)), id: \.0) { (id, text) in
                        HStack(spacing: 4) {
                            Button(intent: CompleteTaskIntent(taskID: id)) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.black, lineWidth: 2)
                                        .frame(width: 25, height: 25)
                                    if entry.completedIDs.contains(id) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(Color.primary)
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                }
                            }
                            .buttonStyle(.borderless)
                            Text(text)
                                .font(.subheadline)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .padding(.leading, 2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                        .background(Color.fromName(entry.sectionColorName))
                        .cornerRadius(12)
                    }
                }
                //.padding(.leading, -11)
                //.padding(.trailing, -11)
                .containerBackground(for: .widget) { Color(.systemBackground) }
            
        }
        //MARK: Accessory Inline Layout
        if family == .accessoryInline {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(zip(entry.taskIDs, entry.taskTexts).prefix(3)), id: \.0) { (id, text) in
                        HStack(spacing: 4) {
                            Button(intent: CompleteTaskIntent(taskID: id)) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.black, lineWidth: 2)
                                        .frame(width: 25, height: 25)
                                    if entry.completedIDs.contains(id) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(Color.primary)
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                }
                            }
                            .buttonStyle(.borderless)
                            Text(text)
                                .font(.subheadline)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .padding(.leading, 2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                        .background(Color.fromName(entry.sectionColorName))
                        .cornerRadius(12)
                    }
                }
                //.padding(.leading, -11)
                //.padding(.trailing, -11)
                .containerBackground(for: .widget) { Color(.systemBackground) }
            
        }
        //MARK: Accessory Rectangular Layout
        if family == .accessoryRectangular {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(zip(entry.taskIDs, entry.taskTexts).prefix(2)), id: \.0) { (id, text) in
                        HStack(spacing: 1) {
                            Button(intent: CompleteTaskIntent(taskID: id)) {
                                ZStack {
//                                    RoundedRectangle(cornerRadius: 12)
//                                        .fill(Color.fromName(entry.sectionColorName))
//                                        .frame(width: 15, height: 15)
                                    Image(systemName: entry.sectionIconName)
                                        .font(.headline)
                                        .foregroundColor(Color.primary)
                                }
                            }
                            .buttonStyle(.borderless)
                            Text(text)
                                .font(.subheadline)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .padding(.leading, 2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.fromName(entry.sectionColorName))
                        .cornerRadius(8)
                    }
                }
                //.padding(.leading, -11)
                //.padding(.trailing, -11)
                .containerBackground(for: .widget) { Color(.systemBackground) }
            
        }
        //MARK: Small Widget Layout
        if family == .systemSmall {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(zip(entry.taskIDs, entry.taskTexts).prefix(3)), id: \.0) { (id, text) in
                        HStack(spacing: 4) {
                            Button(intent: CompleteTaskIntent(taskID: id)) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.black, lineWidth: 2)
                                        .frame(width: 25, height: 25)
                                    if entry.completedIDs.contains(id) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(Color.primary)
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                }
                            }
                            .buttonStyle(.borderless)
                            Text(text)
                                .font(.subheadline)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .padding(.leading, 2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                        .background(Color.fromName(entry.sectionColorName))
                        .cornerRadius(12)
                    }
                }
                .padding(.leading, -11)
                .padding(.trailing, -11)
                .containerBackground(for: .widget) { Color(.systemBackground) }
            
        }
        //MARK: Medium Widget Layout
        if family == .systemMedium {
            HStack(alignment: .top, spacing: 0) {
                // Left-side
                VStack(alignment: .center, spacing: 15) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.fromName(entry.sectionColorName))
                            .frame(width: 40, height: 40)
                        Image(systemName: entry.sectionIconName)
                            .font(.headline)
                            .foregroundColor(Color.primary)
                    }
                    .padding(.top, 14)
                    Text(entry.sectionName)
                        .font(.system(size: 18, weight: .bold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.7) // Shrinks font size
                        .foregroundColor(Color.fromName(entry.sectionColorName).opacity(100))
                    Text("\(entry.completedCount)/\(entry.totalCount)")
                        .font(.system(size: 18, weight: .bold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.7) // Shrinks font size
                        .foregroundColor(Color.primary)
                }
                .frame(width: 80) // Left-size width
                .padding(.trailing, 12)
                
                // Right-side
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(zip(entry.taskIDs, entry.taskTexts).prefix(4)), id: \.0) { (id, text) in
                        HStack(spacing: 8) {
                            Button(intent: CompleteTaskIntent(taskID: id)) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.black, lineWidth: 2)
                                        .frame(width: 21, height: 21)
                                    if entry.completedIDs.contains(id) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(Color.primary)
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                }
                            }
                            .buttonStyle(.borderless)
                            Text(text)
                                .font(.subheadline)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .padding(.leading, 2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                        .background(Color.fromName(entry.sectionColorName))
                        .cornerRadius(12)
                    }
                }
                .padding(.trailing, -10)
                .containerBackground(for: .widget) { Color(.systemBackground) }
            }
        }
        //MARK: Large Widget Layout
        if family == .systemLarge {
            VStack(spacing: 0) {
                // Section Name at Top
                Text(entry.sectionName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color.fromName(entry.sectionColorName).opacity(100))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, -14)
                    .padding(.bottom, -4)
                // Section Switcher Row
                HStack(spacing: 12) {
                    ForEach(entry.availableSections, id: \ .id) { section in
                        let isSelected = section.id == entry.sectionID
                        Button(intent: SwitchSectionIntent(
                            sectionID: section.id,
                            sectionName: section.id,
                            sectionColorName: section.colorName,
                            sectionIconName: section.iconName
                        )) {
                            ZStack {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.fromName(section.colorName))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.fromName(section.colorName), lineWidth: 3)
                                        )
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.clear)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.fromName(section.colorName), lineWidth: 3)
                                        )
                                }
                                if section.iconName == "questionmark" && (section.colorName == ".gray" || section.id == entry.availableSections.first?.id) {
                                    Text("A")
                                        .font(.headline)
                                        .foregroundColor(Color.primary)
                                } else {
                                    Image(systemName: section.iconName)
                                        .font(.headline)
                                        .foregroundColor(Color.primary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 8)
                .padding(.top, 8)
                // Bottom Part
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(zip(entry.taskIDs, entry.taskTexts).prefix(6)), id: \.0) { (id, text) in
                        HStack(spacing: 8) {
                            Button(intent: CompleteTaskIntent(taskID: id)) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.black, lineWidth: 2)
                                        .frame(width: 25, height: 25)
                                    if entry.completedIDs.contains(id) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(Color.primary)
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                }
                            }
                            .buttonStyle(.borderless)
                            Text(text)
                                .font(.subheadline)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .padding(.leading, 2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                        .background(Color.fromName(entry.sectionColorName))
                        .cornerRadius(12)
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 0) // Remove gap above VStack
            .ignoresSafeArea(.container, edges: .top) // Push content to top edge
            .containerBackground(for: .widget) { Color(.systemBackground) }
        }
        
    }
        
}

extension Color {
    static func fromName(_ name: String) -> Color {
        switch name {
        case ".blue": return .blue.opacity(0.5)
        case ".red": return .red.opacity(0.5)
        case ".green": return .green.opacity(0.5)
        case ".yellow": return .yellow.opacity(0.5)
        case ".purple": return .purple.opacity(0.5)
        case ".black": return .black
        case ".white": return .white
        default: return .gray.opacity(0.5)
        }
    }
}

struct AnyTaskWidget: Widget {
    let kind: String = "AnyTaskWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AnyTaskWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Section Tasks")
        .description("Shows the first few tasks from a section.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCircular
        ])
    }
}

#Preview(as: .accessoryCircular) {
    AnyTaskWidget()
} timeline: {
    TaskEntry(
        date: .now,
        sectionName: "To-Do",
        sectionColorName: ".green",
        sectionIconName: "pencil", sectionID: "todo",
        taskIDs: ["1", "2", "3", "4", "5", "6"],
        taskTexts: ["Sample Task 1", "Sample Task 2", "Sample Task 3", "Sample Task 4", "Sample Task 5", "Sample Task 6"],
        completedIDs: ["6"],
        totalCount: 6,
        completedCount: 0,
        refreshToken: UUID(),
        availableSections: [
            SectionButtonInfo(id: "todo", colorName: ".green", iconName: "pencil"),
            SectionButtonInfo(id: "reminders", colorName: ".red", iconName: "flag"),
            SectionButtonInfo(id: "shopping",  colorName: ".blue", iconName: "cart"),
            SectionButtonInfo(id: "ideas",  colorName: ".yellow", iconName: "star")
        ]
    )
}
