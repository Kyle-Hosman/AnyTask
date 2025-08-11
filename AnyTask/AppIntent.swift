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
        let wasCompleted = completedIDs.contains(taskID)
        if wasCompleted {
            completedIDs.remove(taskID)
        } else {
            completedIDs.insert(taskID)
        }
        completedDict[sectionID] = Array(completedIDs)
        defaults?.set(completedDict, forKey: "WidgetCompletedTaskIDsDict")
        // Set the update flag so the app knows to sync
        defaults?.set(sectionID, forKey: "WidgetDidUpdateSectionID")
        // --- Force a sync to disk so the widget sees the new completedIDs immediately ---
        defaults?.synchronize()

        // --- Immediately update only completedDict and reload the widget (for instant checkmark) ---
        completedDict[sectionID] = Array(completedIDs)
        defaults?.set(completedDict, forKey: "WidgetCompletedTaskIDsDict")
        defaults?.set(sectionID, forKey: "WidgetDidUpdateSectionID")
        defaults?.synchronize()
        WidgetCenter.shared.reloadTimelines(ofKind: "AnyTaskWidget")

        // --- After 2 seconds, update the visible list to move completed item down ---
        if !wasCompleted {
            //try? await Task.sleep(nanoseconds: 2_000_000_000)
            let allTaskIDs = defaults?.stringArray(forKey: "AllSectionTaskIDs_\(sectionID)") ?? []
            let allTaskTexts = defaults?.stringArray(forKey: "AllSectionTaskTexts_\(sectionID)") ?? []
            let updatedCompletedIDs = Set(completedDict[sectionID] ?? [])
            let incompleteIDs = allTaskIDs.filter { !updatedCompletedIDs.contains($0) }
            let completeIDs = allTaskIDs.filter { updatedCompletedIDs.contains($0) }
            let newWidgetTaskIDs = Array((incompleteIDs + completeIDs).prefix(3))
            let newWidgetTaskTexts = newWidgetTaskIDs.compactMap { id in
                if let idx = allTaskIDs.firstIndex(of: id) {
                    return allTaskTexts[idx]
                }
                return nil
            }
            defaults?.set(newWidgetTaskIDs, forKey: "WidgetTaskIDs")
            defaults?.set(newWidgetTaskTexts, forKey: "WidgetTaskTexts")
            defaults?.synchronize()
            WidgetCenter.shared.reloadTimelines(ofKind: "AnyTaskWidget")
        }
        return .result()
    }
}
