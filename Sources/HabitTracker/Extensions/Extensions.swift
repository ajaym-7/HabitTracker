import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 91, 141, 239)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    static var random: Color {
        Color(hue: Double.random(in: 0...1), saturation: 0.6, brightness: 0.8)
    }
    
    // Preset colors for habit picker
    static let habitColors: [String] = [
        "#FF6B6B", "#4ECDC4", "#5B8DEF", "#FFE66D", "#A78BFA",
        "#F472B6", "#34D399", "#FB923C", "#F87171", "#60A5FA",
        "#FBBF24", "#A3E635", "#E879F9", "#22D3EE", "#F97316"
    ]
}

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
    
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: self) ?? self
    }
    
    var shortWeekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }
    
    var dayOfMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: self)
    }
}

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    func glowEffect(color: Color, radius: CGFloat = 10) -> some View {
        self.shadow(color: color.opacity(0.5), radius: radius)
    }
}

// Haptic feedback helper (no-op on macOS, but keeps code consistent)
struct HapticFeedback {
    static func impact() {
        // macOS doesn't have haptic feedback
    }
    
    static func success() {
        NSSound.beep()
    }
}
