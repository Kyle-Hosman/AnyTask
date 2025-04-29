//
//  Extensions.swift
//  AnyTask
//
//  Created by Kyle Hosman on 1/10/25.
//

import SwiftUI

extension Color {
    static func fromName(_ name: String) -> Color {
        switch name {
        case ".blue": return .blue
        case ".red": return .red
        case ".green": return .green
        case ".yellow": return .yellow
        case ".black": return .black
        case ".white": return .white
        default: return .gray // Default color for unknown names
        }
    }
}
