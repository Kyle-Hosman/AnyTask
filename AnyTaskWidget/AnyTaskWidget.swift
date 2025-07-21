//
//  AnyTaskWidget.swift
//  AnyTaskWidget
//
//  Created by Kyle Hosman on 7/21/25.
//

import WidgetKit
import SwiftUI

struct TaskEntry: TimelineEntry {
    let date: Date
    let sectionName: String
    let tasks: [String]
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(date: Date(), sectionName: "To-Do", tasks: ["Sample Task 1", "Sample Task 2"])
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
        let tasks = defaults?.stringArray(forKey: "WidgetTasks") ?? []
        return TaskEntry(date: Date(), sectionName: sectionName, tasks: Array(tasks.prefix(3)))
    }
}

struct AnyTaskWidgetEntryView: View {
    var entry: TaskEntry

    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.sectionName)
                .font(.headline)
            ForEach(entry.tasks, id: \.self) { task in
                Text("• \(task)")
                    .font(.body)
            }
        }
        .padding()
        .containerBackground(for: .widget) { Color.clear }
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

//extension ConfigurationAppIntent {
//    fileprivate static var smiley: ConfigurationAppIntent {
//        let intent = ConfigurationAppIntent()
//        intent.favoriteEmoji = "😀"
//        return intent
//    }
//    
//    fileprivate static var starEyes: ConfigurationAppIntent {
//        let intent = ConfigurationAppIntent()
//        intent.favoriteEmoji = "🤩"
//        return intent
//    }
//}

#Preview(as: .systemSmall) {
    AnyTaskWidget()
} timeline: {
    TaskEntry(date: .now, sectionName: "To-Do", tasks: ["Sample Task 1", "Sample Task 2"])
//    TaskEntry(date: .now.addingTimeInterval(3600), sectionName: "In Progress", tasks: ["Sample Task 3", "Sample Task 4"])
}
