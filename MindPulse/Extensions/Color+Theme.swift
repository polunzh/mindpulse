import SwiftUI

extension Color {
    // Primary
    static let mpPrimary = Color(hex: "4A90D9")
    static let mpSecondary = Color(hex: "F5A623")

    // Background
    static let mpBackground = Color(hex: "FAFBFC")
    static let mpCard = Color.white
    static let mpSurface = Color(hex: "F0F2F5")

    // Text
    static let mpTitle = Color(hex: "1A1A2E")
    static let mpBody = Color(hex: "4A4A68")
    static let mpCaption = Color(hex: "8E8EA0")

    // Semantic
    static let mpRemembered = Color(hex: "4CAF50")
    static let mpForgot = Color(hex: "FF6B6B")
    static let mpEnergyLow = Color(hex: "FF9800")
    static let mpEnergyHigh = Color(hex: "4CAF50")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
