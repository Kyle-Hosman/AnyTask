//
//  Item.swift
//  AnyTask
//
//  Created by Kyle Hosman on 1/10/25.
//

import Foundation
import SwiftData
import SwiftUICore
import Combine

@Model
final class Item: Identifiable {
    var id: UUID
    var taskText: String
    var taskComplete: Bool
    var timestamp: Date
    var order: Int
    var parentSection: TaskSection?
    var dueDate: Date?
    var previousOrder: Int?
    var completedAt: Date?
    // Repeat notification properties
    var repeatNotification: Bool
    var repeatInterval: TimeInterval?

    init(taskText: String, taskComplete: Bool, timestamp: Date, order: Int, parentSection: TaskSection?, dueDate: Date? = nil, previousOrder: Int? = nil, completedAt: Date? = nil, repeatNotification: Bool = false, repeatInterval: TimeInterval? = nil) {
        self.id = UUID()
        self.taskText = taskText
        self.taskComplete = taskComplete
        self.timestamp = timestamp
        self.order = order
        self.parentSection = parentSection
        self.dueDate = dueDate
        self.previousOrder = previousOrder
        self.completedAt = completedAt
        self.repeatNotification = repeatNotification
        self.repeatInterval = repeatInterval
    }
}
