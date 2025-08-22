//
//  AnyTaskAppIntent.swift
//  AnyTask
//
//  Created by Kyle Hosman on 7/21/25.
//

import AppIntents
import WidgetKit
import SwiftData

@available(iOS 17.0, *)
public struct CompleteTaskIntent: AppIntent {
    public static var title: LocalizedStringResource = "Complete Task"
        @Parameter(title: "Task ID") public var taskID: String

        public init() { self.taskID = "" }
        public init(taskID: String) { self.taskID = taskID }

        public func perform() async throws -> some IntentResult {
            // Use UserDefaults to communicate with the main app
            let defaults = UserDefaults(suiteName: "group.com.kylehosman.AnyTask")
            let now = Date().timeIntervalSince1970
            var toggles = defaults?.array(forKey: "TasksToToggle") as? [[String: Any]] ?? []
            toggles.append(["id": taskID, "time": now])
            defaults?.set(toggles, forKey: "TasksToToggle")
            defaults?.synchronize()
            // Let the main app handle the SwiftData update when it becomes active
            WidgetCenter.shared.reloadAllTimelines()
            return .result()
        }
}

@available(iOS 17.0, *)
public struct SwitchSectionIntent: AppIntent {
    public static var title: LocalizedStringResource = "Switch Section"
    @Parameter(title: "Section ID") public var sectionID: String
    @Parameter(title: "Section Name") public var sectionName: String
    @Parameter(title: "Section Color Name") public var sectionColorName: String
    @Parameter(title: "Section Icon Name") public var sectionIconName: String

    public init() {
        self.sectionID = ""
        self.sectionName = ""
        self.sectionColorName = ""
        self.sectionIconName = ""
    }
    public init(sectionID: String, sectionName: String, sectionColorName: String, sectionIconName: String) {
        self.sectionID = sectionID
        self.sectionName = sectionName
        self.sectionColorName = sectionColorName
        self.sectionIconName = sectionIconName
    }

    public func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.com.kylehosman.AnyTask")
        defaults?.set(sectionID, forKey: "LastSelectedSectionID") // <-- Widget reads this key
        defaults?.set(sectionName, forKey: "WidgetSectionName")
        defaults?.set(sectionColorName, forKey: "WidgetSectionColor")
        defaults?.set(sectionIconName, forKey: "WidgetSectionIcon")
        defaults?.set(sectionID, forKey: "WidgetDidSwitchSectionID") // Set flag for app to update task list
        // --- Instantly sync list items for the new section ---
        defaults?.synchronize()
        WidgetCenter.shared.reloadAllTimelines() // <-- Force widget to reload
        return .result()
    }
}

@available(iOS 17.0, *)
public struct QuickAddTaskIntent: AppIntent {
    public static var title: LocalizedStringResource = "Quick Add Task"

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.com.kylehosman.AnyTask")
        // Find the 'Any' section
        let modelContainer = try? ModelContainer(for: Item.self, TaskSection.self)
        let context = modelContainer?.mainContext
        let sections = (try? context?.fetch(FetchDescriptor<TaskSection>())) ?? []
        if let anySection = sections.first(where: { $0.name == "Any" }) {
            defaults?.set(anySection.id.uuidString, forKey: "LastSelectedSectionID")
        }
        defaults?.set(true, forKey: "ShouldFocusTaskInput")
        defaults?.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
