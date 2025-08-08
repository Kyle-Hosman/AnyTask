import WidgetKit
import SwiftUI
import AppIntents

struct TaskEntry: TimelineEntry {
    let date: Date
    let sectionName: String
    let sectionColorName: String
    let taskIDs: [String]
    let taskTexts: [String]
    let completedIDs: Set<String>
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(date: Date(), sectionName: "To-Do", sectionColorName: ".green", taskIDs: ["1", "2"], taskTexts: ["Sample Task 1", "Sample Task 2"], completedIDs: [])
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
        let taskIDs = defaults?.stringArray(forKey: "WidgetTaskIDs") ?? []
        let taskTexts = defaults?.stringArray(forKey: "WidgetTaskTexts") ?? []
        let completedIDs = Set(defaults?.stringArray(forKey: "WidgetCompletedTaskIDs") ?? [])
        return TaskEntry(date: Date(), sectionName: sectionName, sectionColorName: sectionColorName, taskIDs: Array(taskIDs.prefix(3)), taskTexts: Array(taskTexts.prefix(3)), completedIDs: completedIDs)
    }
}



struct AnyTaskWidgetEntryView: View {
    var entry: TaskEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.sectionName)
                .font(.headline)
                .padding(.top, 5)
            ForEach(Array(zip(entry.taskIDs, entry.taskTexts)), id: \.0) { (id, text) in
                HStack(spacing: 8) {
                    Button(intent: CompleteTaskIntent(taskID: id)) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.black, lineWidth: 2)
                                .frame(width: 20, height: 20)
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
                .padding(0)
                .background(Color.fromName(entry.sectionColorName))
                .cornerRadius(12)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: 192, alignment: .topLeading)
        .containerBackground(for: .widget) { Color(.systemBackground) }
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

#Preview(as: .systemSmall) {
    AnyTaskWidget()
} timeline: {
    TaskEntry(date: .now, sectionName: "To-Do", sectionColorName: ".green", taskIDs: ["1", "2", "3", "4"], taskTexts: ["Sample Task 1", "Sample Task 2", "Sample Task 3", "Sample Task 4"], completedIDs: [])
}
