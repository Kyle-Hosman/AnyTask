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
        // Get the current section ID
        guard let sectionID = defaults?.string(forKey: "WidgetSectionID") else {
            return .result()
        }
        // Read the per-section completed IDs dictionary
        var completedDict = defaults?.dictionary(forKey: "WidgetCompletedTaskIDsDict") as? [String: [String]] ?? [:]
        var completedIDs = Set(completedDict[sectionID] ?? [])
        if completedIDs.contains(taskID) {
            completedIDs.remove(taskID)
        } else {
            completedIDs.insert(taskID)
        }
        completedDict[sectionID] = Array(completedIDs)
        defaults?.set(completedDict, forKey: "WidgetCompletedTaskIDsDict")
        // Set the update flag so the app knows to sync
        defaults?.set(sectionID, forKey: "WidgetDidUpdateSectionID")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
