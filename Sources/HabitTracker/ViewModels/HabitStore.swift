import Foundation
import SwiftUI
import Combine

// MARK: - Sort Option
enum HabitSortOption: String, CaseIterable {
    case name = "Name"
    case streak = "Streak"
    case completionRate = "Completion Rate"
    case dateCreated = "Date Created"
    case category = "Category"
}

// MARK: - Filter Option
enum HabitFilterOption: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case archived = "Archived"
    case dueToday = "Due Today"
    case completed = "Completed Today"
    case incomplete = "Incomplete Today"
}

// MARK: - HabitStore
@MainActor
final class HabitStore: ObservableObject {
    // MARK: Published Properties
    @Published private(set) var habits: [Habit] = []
    @Published var categories: [HabitCategory] = []
    @Published var sortOption: HabitSortOption = .dateCreated
    @Published var sortAscending: Bool = false
    @Published var filterOption: HabitFilterOption = .active
    @Published var searchText: String = ""
    @Published var selectedCategoryId: UUID? = nil
    
    // MARK: Private Properties
    private let habitsURL: URL
    private let categoriesURL: URL
    private let settingsURL: URL
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: Computed Properties
    var filteredHabits: [Habit] {
        var result = habits
        
        // Apply category filter
        if let categoryId = selectedCategoryId {
            result = result.filter { $0.categoryId == categoryId }
        }
        
        // Apply status filter
        switch filterOption {
        case .all:
            break
        case .active:
            result = result.filter { !$0.isArchived }
        case .archived:
            result = result.filter { $0.isArchived }
        case .dueToday:
            result = result.filter { $0.isDueToday && !$0.isArchived }
        case .completed:
            result = result.filter { $0.isCompletedToday && !$0.isArchived }
        case .incomplete:
            result = result.filter { !$0.isCompletedToday && !$0.isArchived }
        }
        
        // Apply search
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply sort
        result.sort { a, b in
            let comparison: Bool
            switch sortOption {
            case .name:
                comparison = a.title.localizedCompare(b.title) == .orderedAscending
            case .streak:
                comparison = a.currentStreak < b.currentStreak
            case .completionRate:
                comparison = a.completionRateThisMonth < b.completionRateThisMonth
            case .dateCreated:
                comparison = a.createdAt < b.createdAt
            case .category:
                let catA = category(for: a)?.name ?? ""
                let catB = category(for: b)?.name ?? ""
                comparison = catA.localizedCompare(catB) == .orderedAscending
            }
            return sortAscending ? comparison : !comparison
        }
        
        return result
    }
    
    var todayProgress: Double {
        let dueHabits = habits.filter { $0.isDueToday && !$0.isArchived }
        guard !dueHabits.isEmpty else { return 1.0 }
        let completed = dueHabits.filter { $0.isCompletedToday }.count
        return Double(completed) / Double(dueHabits.count)
    }
    
    var totalCompletionsToday: Int {
        habits.filter { $0.isCompletedToday }.count
    }
    
    var bestCurrentStreak: Int {
        habits.map { $0.currentStreak }.max() ?? 0
    }
    
    var totalCompletions: Int {
        habits.reduce(0) { $0 + $1.completedDates.count }
    }
    
    var habitsByCategory: [UUID: [Habit]] {
        Dictionary(grouping: filteredHabits, by: { $0.categoryId })
    }
    
    // MARK: Initialization
    init() {
        let fm = FileManager.default
        let appSupport = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let bundleId = Bundle.main.bundleIdentifier ?? "HabitTracker"
        let dir = appSupport?.appendingPathComponent(bundleId) ?? URL(fileURLWithPath: NSTemporaryDirectory())
        
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        
        self.habitsURL = dir.appendingPathComponent("habits.json")
        self.categoriesURL = dir.appendingPathComponent("categories.json")
        self.settingsURL = dir.appendingPathComponent("settings.json")
        
        load()
        
        if categories.isEmpty {
            categories = HabitCategory.defaults
            saveCategories()
        }
        
        if habits.isEmpty {
            createSampleData()
        }
    }
    
    // MARK: Category Methods
    func category(for habit: Habit) -> HabitCategory? {
        categories.first { $0.id == habit.categoryId }
    }
    
    func addCategory(_ category: HabitCategory) {
        guard !categories.contains(where: { $0.name == category.name }) else { return }
        categories.append(category)
        categories.sort { $0.name < $1.name }
        saveCategories()
    }
    
    func updateCategory(_ category: HabitCategory) {
        guard let idx = categories.firstIndex(where: { $0.id == category.id }) else { return }
        categories[idx] = category
        saveCategories()
    }
    
    func deleteCategory(_ category: HabitCategory) {
        // Move habits to first available category
        if let fallbackCategory = categories.first(where: { $0.id != category.id }) {
            for i in habits.indices where habits[i].categoryId == category.id {
                habits[i].categoryId = fallbackCategory.id
            }
            saveHabits()
        }
        categories.removeAll { $0.id == category.id }
        saveCategories()
    }
    
    func habitsCount(for category: HabitCategory) -> Int {
        habits.filter { $0.categoryId == category.id && !$0.isArchived }.count
    }
    
    // MARK: Habit CRUD
    func addHabit(_ habit: Habit) {
        habits.insert(habit, at: 0)
        saveHabits()
    }
    
    func updateHabit(_ habit: Habit) {
        guard let idx = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[idx] = habit
        saveHabits()
    }
    
    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        saveHabits()
    }
    
    func archiveHabit(_ habit: Habit) {
        guard let idx = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[idx].isArchived = true
        saveHabits()
    }
    
    func unarchiveHabit(_ habit: Habit) {
        guard let idx = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[idx].isArchived = false
        saveHabits()
    }
    
    // MARK: Completion
    func toggleCompletion(for habit: Habit, on date: Date = Date()) {
        guard let idx = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        
        if let existingIdx = habits[idx].completedDates.firstIndex(where: { calendar.isDate($0, inSameDayAs: targetDay) }) {
            habits[idx].completedDates.remove(at: existingIdx)
        } else {
            habits[idx].completedDates.append(targetDay)
        }
        
        habits[idx].completedDates.sort(by: >)
        saveHabits()
    }
    
    // MARK: Analytics
    func completionsPerDay(last days: Int) -> [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<days).reversed().compactMap { offset -> (Date, Int)? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let count = habits.reduce(0) { sum, habit in
                sum + (habit.isCompleted(on: date) ? 1 : 0)
            }
            return (date, count)
        }
    }
    
    func categoryDistribution() -> [(category: HabitCategory, count: Int)] {
        categories.compactMap { category in
            let count = habits.filter { $0.categoryId == category.id && !$0.isArchived }.count
            return count > 0 ? (category, count) : nil
        }.sorted { $0.count > $1.count }
    }
    
    func topStreakHabits(limit: Int = 5) -> [Habit] {
        habits
            .filter { !$0.isArchived && $0.currentStreak > 0 }
            .sorted { $0.currentStreak > $1.currentStreak }
            .prefix(limit)
            .map { $0 }
    }
    
    func weeklyCompletionRate() -> Double {
        let activeHabits = habits.filter { !$0.isArchived }
        guard !activeHabits.isEmpty else { return 0 }
        
        let totalPossible = activeHabits.count * 7
        let totalCompleted = activeHabits.reduce(0) { $0 + $1.completionsInLast(7) }
        
        return Double(totalCompleted) / Double(totalPossible)
    }
    
    // MARK: Persistence
    private func saveHabits() {
        do {
            let data = try JSONEncoder().encode(habits)
            try data.write(to: habitsURL, options: .atomic)
        } catch {
            print("Failed to save habits: \(error)")
        }
    }
    
    private func saveCategories() {
        do {
            let data = try JSONEncoder().encode(categories)
            try data.write(to: categoriesURL, options: .atomic)
        } catch {
            print("Failed to save categories: \(error)")
        }
    }
    
    private func load() {
        // Load habits
        if let data = try? Data(contentsOf: habitsURL),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = decoded
        }
        
        // Load categories
        if let data = try? Data(contentsOf: categoriesURL),
           let decoded = try? JSONDecoder().decode([HabitCategory].self, from: data) {
            categories = decoded
        }
    }
    
    func resetAllData() {
        habits = []
        categories = HabitCategory.defaults
        saveHabits()
        saveCategories()
    }
    
    func exportData() -> Data? {
        let exportData: [String: Any] = [
            "habits": (try? JSONEncoder().encode(habits)) ?? Data(),
            "categories": (try? JSONEncoder().encode(categories)) ?? Data()
        ]
        return try? JSONSerialization.data(withJSONObject: exportData)
    }
    
    // MARK: Sample Data
    private func createSampleData() {
        guard let healthCategory = categories.first(where: { $0.name == "Health" }),
              let learningCategory = categories.first(where: { $0.name == "Learning" }),
              let mindfulnessCategory = categories.first(where: { $0.name == "Mindfulness" }),
              let fitnessCategory = categories.first(where: { $0.name == "Fitness" }) else { return }
        
        let calendar = Calendar.current
        
        var habit1 = Habit(
            title: "Morning Run",
            notes: "30 minutes of cardio to start the day",
            icon: "figure.run",
            colorHex: "#FF6B6B",
            categoryId: fitnessCategory.id,
            frequency: .weekdays
        )
        habit1.completedDates = (0..<5).compactMap { calendar.date(byAdding: .day, value: -$0, to: Date()) }
        
        var habit2 = Habit(
            title: "Read for 30 minutes",
            notes: "Fiction or non-fiction, just read!",
            icon: "book.fill",
            colorHex: "#5B8DEF",
            categoryId: learningCategory.id,
            frequency: .daily
        )
        habit2.completedDates = (0..<10).compactMap { calendar.date(byAdding: .day, value: -$0, to: Date()) }
        
        var habit3 = Habit(
            title: "Meditate",
            notes: "10 minutes of mindfulness",
            icon: "brain.head.profile",
            colorHex: "#A78BFA",
            categoryId: mindfulnessCategory.id,
            frequency: .daily
        )
        habit3.completedDates = (0..<3).compactMap { calendar.date(byAdding: .day, value: -$0, to: Date()) }
        
        var habit4 = Habit(
            title: "Drink 8 glasses of water",
            notes: "Stay hydrated!",
            icon: "drop.fill",
            colorHex: "#4ECDC4",
            categoryId: healthCategory.id,
            frequency: .daily
        )
        habit4.completedDates = [Date()]
        
        habits = [habit1, habit2, habit3, habit4]
        saveHabits()
    }
}
