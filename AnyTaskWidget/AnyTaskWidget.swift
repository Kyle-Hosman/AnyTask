import WidgetKit
import SwiftUI
import AppIntents

struct TaskEntry: TimelineEntry {
    let date: Date
    let sectionName: String
    let sectionColorName: String
    let tasks: [String]
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(date: Date(), sectionName: "To-Do", sectionColorName: ".green", tasks: ["Sample Task 1", "Sample Task 2"])
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
        let tasks = defaults?.stringArray(forKey: "WidgetTasks") ?? []
        return TaskEntry(date: Date(), sectionName: sectionName, sectionColorName: sectionColorName, tasks: Array(tasks.prefix(3)))
    }
}



struct AnyTaskWidgetEntryView: View {
    var entry: TaskEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.sectionName)
                .font(.headline)
                .padding(.top, 5)
            ForEach(entry.tasks, id: \.self) { task in
                HStack(spacing: 8) {
                    Button(intent: CompleteTaskIntent(taskID: task)) {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.black, lineWidth: 2)
                            .frame(width: 20, height: 20)
                    }
                    Text(task)
                        .font(.subheadline)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.leading, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color.fromName(entry.sectionColorName))
                .cornerRadius(12)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
    TaskEntry(date: .now, sectionName: "To-Do", sectionColorName: ".green", tasks: ["Sample Task 1", "Sample Task 2"])
}
