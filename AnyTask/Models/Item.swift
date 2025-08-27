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

enum RepeatIntervalType: Int, Codable, CaseIterable {
    case never = 0
    case hourly
    case daily
    case weekly
    case biweekly
    case monthly
    case bimonthly
    case yearly

    var timeInterval: TimeInterval? {
        switch self {
        case .never: return nil
        case .hourly: return 3600
        case .daily: return 86400
        case .weekly: return 604800
        case .biweekly: return 1209600
        case .monthly: return 2629800 // approx 1 month
        case .bimonthly: return 5259600 // approx 2 months
        case .yearly: return 31557600 // approx 1 year
        }
    }

    var displayName: String {
        switch self {
        case .never: return "Never"
        case .hourly: return "Hourly"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .biweekly: return "Biweekly"
        case .monthly: return "Monthly"
        case .bimonthly: return "Bimonthly"
        case .yearly: return "Yearly"
        }
    }
}

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
    var repeatIntervalType: RepeatIntervalType?

    init(taskText: String, taskComplete: Bool, timestamp: Date, order: Int, parentSection: TaskSection?, dueDate: Date? = nil, previousOrder: Int? = nil, completedAt: Date? = nil, repeatIntervalType: RepeatIntervalType? = nil) {
        self.id = UUID()
        self.taskText = taskText
        self.taskComplete = taskComplete
        self.timestamp = timestamp
        self.order = order
        self.parentSection = parentSection
        self.dueDate = dueDate
        self.previousOrder = previousOrder
        self.completedAt = completedAt
        self.repeatIntervalType = repeatIntervalType
    }
}
