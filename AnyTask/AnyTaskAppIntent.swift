//
//  AnyTaskAppIntent.swift
//  AnyTask
//
//  Created by Kyle Hosman on 7/21/25.
//

import AppIntents
import WidgetKit

@available(iOS 17.0, *)
public struct CompleteTaskIntent: AppIntent {
    public static var title: LocalizedStringResource = "Complete Task"
    @Parameter(title: "Task ID") public var taskID: String

    public init() { self.taskID = "" }
    public init(taskID: String) { self.taskID = taskID }

    public func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.com.kylehosman.AnyTask")
        var completedIDs = Set(defaults?.stringArray(forKey: "WidgetCompletedTaskIDs") ?? [])
        if completedIDs.contains(taskID) {
            completedIDs.remove(taskID)
        } else {
            completedIDs.insert(taskID)
        }
        defaults?.set(Array(completedIDs), forKey: "WidgetCompletedTaskIDs")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
