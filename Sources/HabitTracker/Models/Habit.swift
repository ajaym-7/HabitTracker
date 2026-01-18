import Foundation

// MARK: - Frequency
enum HabitFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case weekdays = "Weekdays"
    case weekends = "Weekends"
    case custom = "Custom"
    
    var icon: String {
        switch self {
        case .daily: return "calendar"
        case .weekly: return "calendar.badge.clock"
        case .weekdays: return "briefcase"
        case .weekends: return "sun.max"
        case .custom: return "slider.horizontal.3"
        }
    }
}

// MARK: - Category
struct HabitCategory: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String
    var icon: String
    var colorHex: String
    
    static let defaults: [HabitCategory] = [
        HabitCategory(name: "Health", icon: "heart.fill", colorHex: "#FF6B6B"),
        HabitCategory(name: "Fitness", icon: "figure.run", colorHex: "#4ECDC4"),
        HabitCategory(name: "Learning", icon: "book.fill", colorHex: "#5B8DEF"),
        HabitCategory(name: "Productivity", icon: "bolt.fill", colorHex: "#FFE66D"),
        HabitCategory(name: "Mindfulness", icon: "brain.head.profile", colorHex: "#A78BFA"),
        HabitCategory(name: "Social", icon: "person.2.fill", colorHex: "#F472B6"),
        HabitCategory(name: "Finance", icon: "dollarsign.circle.fill", colorHex: "#34D399"),
        HabitCategory(name: "Creativity", icon: "paintbrush.fill", colorHex: "#FB923C"),
    ]
}

// MARK: - Habit
struct Habit: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var notes: String
    var icon: String
    var colorHex: String
    var categoryId: UUID
    var frequency: HabitFrequency
    var customDays: [Int]
    var targetCount: Int
    var reminderEnabled: Bool
    var reminderTime: Date?
    var isArchived: Bool
    var createdAt: Date
    var completedDates: [Date]
    
    init(
        title: String,
        notes: String = "",
        icon: String = "star.fill",
        colorHex: String = "#5B8DEF",
        categoryId: UUID,
        frequency: HabitFrequency = .daily,
        customDays: [Int] = [],
        targetCount: Int = 1,
        reminderEnabled: Bool = false,
        reminderTime: Date? = nil
    ) {
        self.title = title
        self.notes = notes
        self.icon = icon
        self.colorHex = colorHex
        self.categoryId = categoryId
        self.frequency = frequency
        self.customDays = customDays
        self.targetCount = targetCount
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.isArchived = false
        self.createdAt = Date()
        self.completedDates = []
    }
    
    var isDueToday: Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        
        switch frequency {
        case .daily:
            return true
        case .weekly:
            return weekday == 1
        case .weekdays:
            return weekday >= 2 && weekday <= 6
        case .weekends:
            return weekday == 1 || weekday == 7
        case .custom:
            return customDays.contains(weekday)
        }
    }
}

// MARK: - Habit Extensions
extension Habit {
    func isCompleted(on date: Date) -> Bool {
        let calendar = Calendar.current
        return completedDates.contains { calendar.isDate($0, inSameDayAs: date) }
    }
    
    var isCompletedToday: Bool {
        isCompleted(on: Date())
    }
    
    var currentStreak: Int {
        let calendar = Calendar.current
        let sortedDates = completedDates
            .map { calendar.startOfDay(for: $0) }
            .sorted(by: >)
        
        guard !sortedDates.isEmpty else { return 0 }
        
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        
        if !sortedDates.contains(checkDate) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else { return 0 }
            if !sortedDates.contains(yesterday) { return 0 }
            checkDate = yesterday
        }
        
        while sortedDates.contains(checkDate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        
        return streak
    }
    
    var longestStreak: Int {
        let calendar = Calendar.current
        let sortedDates = completedDates
            .map { calendar.startOfDay(for: $0) }
            .sorted()
        
        guard !sortedDates.isEmpty else { return 0 }
        
        var maxStreak = 1
        var currentStreak = 1
        
        for i in 1..<sortedDates.count {
            if let expectedDate = calendar.date(byAdding: .day, value: 1, to: sortedDates[i-1]),
               calendar.isDate(sortedDates[i], inSameDayAs: expectedDate) {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else if !calendar.isDate(sortedDates[i], inSameDayAs: sortedDates[i-1]) {
                currentStreak = 1
            }
        }
        
        return maxStreak
    }
    
    var completionRateThisMonth: Double {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) else { return 0 }
        
        let daysPassed = max(1, (calendar.dateComponents([.day], from: startOfMonth, to: Date()).day ?? 0) + 1)
        
        let completionsThisMonth = completedDates.filter { date in
            calendar.isDate(date, equalTo: Date(), toGranularity: .month)
        }.count
        
        return Double(completionsThisMonth) / Double(daysPassed)
    }
    
    func completionsInLast(_ days: Int) -> Int {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return completedDates.filter { $0 >= startDate }.count
    }
}
