import WidgetKit
import SwiftUI
import AppIntents

struct TaskEntry: TimelineEntry {
    let date: Date
    let sectionName: String
    let sectionColorName: String
    let sectionIconName: String
    let taskIDs: [String]
    let taskTexts: [String]
    let completedIDs: Set<String>
    let totalCount: Int
    let completedCount: Int
    let refreshToken: UUID // Add a refresh token to force widget redraw
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(date: Date(), sectionName: "To-Do", sectionColorName: ".green", sectionIconName: "pencil", taskIDs: ["1", "2"], taskTexts: ["Sample Task 1", "Sample Task 2"], completedIDs: [], totalCount: 3, completedCount: 0, refreshToken: UUID())
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> ()) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> ()) {
        let entry = loadEntry()
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(300)))
        completion(timeline)
    }

    private func loadEntry() -> TaskEntry {
        let defaults = UserDefaults(suiteName: "group.com.kylehosman.AnyTask")
        let sectionName = defaults?.string(forKey: "WidgetSectionName") ?? "No List"
        let sectionColorName = defaults?.string(forKey: "WidgetSectionColor") ?? ".gray"
        let sectionIconName = defaults?.string(forKey: "WidgetSectionIcon") ?? "folder"
        let taskIDs = defaults?.stringArray(forKey: "WidgetTaskIDs") ?? []
        let taskTexts = defaults?.stringArray(forKey: "WidgetTaskTexts") ?? []
        // --- Begin per-section completed IDs dictionary ---
        let sectionID = defaults?.string(forKey: "WidgetSectionID") ?? ""
        let completedDict = defaults?.dictionary(forKey: "WidgetCompletedTaskIDsDict") as? [String: [String]] ?? [:]
        let completedIDs = Set(completedDict[sectionID] ?? [])
        // --- End per-section completed IDs dictionary ---
        let totalCount = (defaults?.array(forKey: "WidgetTaskIDs") as? [String])?.count ?? 0
        let completedCount = completedIDs.count
        print("[DEBUG] Provider.loadEntry: WidgetTaskIDs=\(taskIDs), WidgetTaskTexts=\(taskTexts), completedIDs=\(completedIDs)")
        return TaskEntry(date: Date(), sectionName: sectionName, sectionColorName: sectionColorName, sectionIconName: sectionIconName, taskIDs: Array(taskIDs.prefix(3)), taskTexts: Array(taskTexts.prefix(3)), completedIDs: completedIDs, totalCount: totalCount, completedCount: completedCount, refreshToken: UUID())
    }
}



struct AnyTaskWidgetEntryView: View {
    var entry: TaskEntry

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left-side
            VStack(alignment: .center, spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.fromName(entry.sectionColorName))
                        .frame(width: 40, height: 40)
                    Image(systemName: entry.sectionIconName)
                        .font(.headline)
                        .foregroundColor(Color.primary)
                }
                //.padding(.top, 26)
                Text(entry.sectionName)
                    .font(.system(size: 18, weight: .bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7) // Shrinks font size
                    .foregroundColor(Color.fromName(entry.sectionColorName).opacity(100))
                    .padding(.top, 15)
                Text("\(entry.completedCount)/\(entry.totalCount)")
                    .font(.system(size: 18, weight: .bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7) // Shrinks font size
                    .foregroundColor(Color.primary)
                    .padding(.top, 15)
            }
            .frame(width: 80) // Left-size width
            .padding(.trailing, 12)

            // Right-side
            VStack(alignment: .leading, spacing: 8) {
                
                ForEach(Array(zip(entry.taskIDs, entry.taskTexts)), id: \.0) { (id, text) in
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
                        Text(text)
                            .font(.subheadline)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .padding(.leading, 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(2)
                    .background(Color.fromName(entry.sectionColorName))
                    .cornerRadius(12)
                }
            }
            //.padding(.top, 25)
            //.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemMedium) {
    AnyTaskWidget()
} timeline: {
    TaskEntry(date: .now, sectionName: "To-Do", sectionColorName: ".green", sectionIconName: "pencil", taskIDs: ["1", "2", "3", "4"], taskTexts: ["Sample Task 1", "Sample Task 2", "Sample Task 3", "Sample Task 4"], completedIDs: [], totalCount: 4, completedCount: 0, refreshToken: UUID())
}
