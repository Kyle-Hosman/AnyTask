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
        case ".blue": return .blue.opacity(0.5)
        case ".red": return .red.opacity(0.5)
        case ".green": return .green.opacity(0.5)
        case ".yellow": return .yellow.opacity(0.5)
        case ".purple": return .purple.opacity(0.5)
        case ".black": return .black
        case ".white": return .white
        default: return .gray.opacity(0.5) // Default color for unknown names
        }
    }
    
    static func printAllColorHexCodes() {
        let colorNames = [".blue", ".red", ".green", ".yellow", ".purple", ".black", ".white", "(default)"]
        for name in colorNames {
            let color: Color
            if name == "(default)" {
                color = Color.fromName("unknown")
            } else {
                color = Color.fromName(name)
            }
            #if canImport(UIKit)
            let uiColor = UIColor(color)
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            let hex = String(format: "#%02X%02X%02X%02X", Int(red*255), Int(green*255), Int(blue*255), Int(alpha*255))
            #elseif canImport(AppKit)
            let nsColor = NSColor(color)
            let rgbColor = nsColor.usingColorSpace(.deviceRGB) ?? nsColor
            let red = Int((rgbColor.redComponent * 255).rounded())
            let green = Int((rgbColor.greenComponent * 255).rounded())
            let blue = Int((rgbColor.blueComponent * 255).rounded())
            let alpha = Int((rgbColor.alphaComponent * 255).rounded())
            let hex = String(format: "#%02X%02X%02X%02X", red, green, blue, alpha)
            #else
            let hex = "(platform not supported)"
            #endif
            print("\(name): \(hex)")
        }
    }
}
