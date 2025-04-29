//
//  Item.swift
//  AnyTask
//
//  Created by Kyle Hosman on 1/10/25.
//

import Foundation
import SwiftData
import SwiftUICore

@Model
final class Item: Identifiable {
    var id: UUID
    var taskText: String
    var taskComplete: Bool
    var timestamp: Date
    var order: Int // Ensure this exists
    var parentSection: TaskSection?

    init(taskText: String, taskComplete: Bool, timestamp: Date, order: Int, parentSection: TaskSection?) {
        self.id = UUID()
        self.taskText = taskText
        self.taskComplete = taskComplete
        self.timestamp = timestamp
        self.order = order
        self.parentSection = parentSection
    }
}

