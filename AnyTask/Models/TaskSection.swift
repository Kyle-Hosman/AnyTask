//
//  Section.swift
//  AnyTask
//
//  Created by Kyle Hosman on 1/10/25.
//

import Foundation
import SwiftData
import SwiftUICore

@Model
final class TaskSection {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorName: String
    var isEditable: Bool
    var order: Int // Property to maintain the order

    init(id: UUID = UUID(), name: String, colorName: String, isEditable: Bool = true, order: Int) {
        self.id = id
        self.name = name
        self.colorName = colorName
        self.isEditable = isEditable
        self.order = order
    }
}

