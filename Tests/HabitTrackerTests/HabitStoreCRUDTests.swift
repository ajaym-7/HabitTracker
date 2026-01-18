import XCTest
@testable import HabitTracker

@MainActor
final class HabitStoreCRUDTests: XCTestCase {
    
    var store: HabitStore!
    var testCategory: HabitCategory!
    
    override func setUp() async throws {
        store = HabitStore()
        // Reset to clean state
        store.resetAllData()
        
        // Get or create a test category
        testCategory = store.categories.first ?? HabitCategory(
            name: "Test Category",
            icon: "star.fill",
            colorHex: "#FF0000"
        )
        
        if store.categories.isEmpty {
            store.addCategory(testCategory)
        }
    }
    
    override func tearDown() async throws {
        store.resetAllData()
        store = nil
    }
    
    // MARK: - CREATE Tests
    
    func testCreateHabit() async throws {
        // Given
        let initialCount = store.habits.count
        let newHabit = Habit(
            title: "Test Habit",
            notes: "Test notes for the habit",
            icon: "star.fill",
            colorHex: "#5B8DEF",
            categoryId: testCategory.id,
            frequency: .daily
        )
        
        // When
        store.addHabit(newHabit)
        
        // Then
        XCTAssertEqual(store.habits.count, initialCount + 1, "Habit count should increase by 1")
        XCTAssertNotNil(store.habits.first(where: { $0.id == newHabit.id }), "New habit should exist in store")
        
        let savedHabit = store.habits.first(where: { $0.id == newHabit.id })!
        XCTAssertEqual(savedHabit.title, "Test Habit")
        XCTAssertEqual(savedHabit.notes, "Test notes for the habit")
        XCTAssertEqual(savedHabit.icon, "star.fill")
        XCTAssertEqual(savedHabit.frequency, .daily)
        
        print("✅ CREATE: Successfully created habit '\(savedHabit.title)'")
    }
    
    func testCreateMultipleHabits() async throws {
        // Given
        let initialCount = store.habits.count
        
        let habit1 = Habit(title: "Habit 1", notes: "", icon: "star.fill", colorHex: "#FF0000", categoryId: testCategory.id, frequency: .daily)
        let habit2 = Habit(title: "Habit 2", notes: "", icon: "heart.fill", colorHex: "#00FF00", categoryId: testCategory.id, frequency: .weekdays)
        let habit3 = Habit(title: "Habit 3", notes: "", icon: "bolt.fill", colorHex: "#0000FF", categoryId: testCategory.id, frequency: .weekends)
        
        // When
        store.addHabit(habit1)
        store.addHabit(habit2)
        store.addHabit(habit3)
        
        // Then
        XCTAssertEqual(store.habits.count, initialCount + 3, "Should have 3 new habits")
        
        print("✅ CREATE: Successfully created 3 habits")
    }
    
    // MARK: - READ Tests
    
    func testReadHabit() async throws {
        // Given
        let newHabit = Habit(
            title: "Read Test Habit",
            notes: "Notes to read",
            icon: "book.fill",
            colorHex: "#A78BFA",
            categoryId: testCategory.id,
            frequency: .daily
        )
        store.addHabit(newHabit)
        
        // When
        let foundHabit = store.habits.first(where: { $0.id == newHabit.id })
        
        // Then
        XCTAssertNotNil(foundHabit, "Should be able to find the habit")
        XCTAssertEqual(foundHabit?.title, "Read Test Habit")
        XCTAssertEqual(foundHabit?.notes, "Notes to read")
        
        print("✅ READ: Successfully read habit '\(foundHabit!.title)'")
    }
    
    func testFilteredHabits() async throws {
        // Given - clear and add fresh habits
        store.resetAllData()
        testCategory = store.categories.first!
        
        let activeHabit = Habit(title: "Active Habit", notes: "", icon: "star.fill", colorHex: "#FF0000", categoryId: testCategory.id, frequency: .daily)
        var archivedHabit = Habit(title: "Archived Habit", notes: "", icon: "star.fill", colorHex: "#FF0000", categoryId: testCategory.id, frequency: .daily)
        archivedHabit.isArchived = true
        
        store.addHabit(activeHabit)
        store.addHabit(archivedHabit)
        
        // When - filter for active only
        store.filterOption = .active
        
        // Then
        let filtered = store.filteredHabits
        XCTAssertTrue(filtered.contains(where: { $0.id == activeHabit.id }), "Active habit should be in filtered results")
        XCTAssertFalse(filtered.contains(where: { $0.id == archivedHabit.id }), "Archived habit should NOT be in filtered results")
        
        print("✅ READ: Filtered habits correctly (active: \(filtered.count))")
    }
    
    // MARK: - UPDATE Tests
    
    func testUpdateHabitTitle() async throws {
        // Given
        var habit = Habit(
            title: "Original Title",
            notes: "Original notes",
            icon: "star.fill",
            colorHex: "#5B8DEF",
            categoryId: testCategory.id,
            frequency: .daily
        )
        store.addHabit(habit)
        
        // When
        habit.title = "Updated Title"
        store.updateHabit(habit)
        
        // Then
        let updatedHabit = store.habits.first(where: { $0.id == habit.id })
        XCTAssertEqual(updatedHabit?.title, "Updated Title", "Title should be updated")
        XCTAssertEqual(updatedHabit?.notes, "Original notes", "Notes should remain unchanged")
        
        print("✅ UPDATE: Successfully updated habit title to '\(updatedHabit!.title)'")
    }
    
    func testUpdateHabitFrequency() async throws {
        // Given
        var habit = Habit(
            title: "Frequency Test",
            notes: "",
            icon: "star.fill",
            colorHex: "#5B8DEF",
            categoryId: testCategory.id,
            frequency: .daily
        )
        store.addHabit(habit)
        XCTAssertEqual(habit.frequency, .daily)
        
        // When
        habit.frequency = .weekends
        store.updateHabit(habit)
        
        // Then
        let updatedHabit = store.habits.first(where: { $0.id == habit.id })
        XCTAssertEqual(updatedHabit?.frequency, .weekends, "Frequency should be updated to weekends")
        
        print("✅ UPDATE: Successfully updated frequency to \(updatedHabit!.frequency.rawValue)")
    }
    
    func testToggleCompletion() async throws {
        // Given
        let habit = Habit(
            title: "Completion Test",
            notes: "",
            icon: "star.fill",
            colorHex: "#5B8DEF",
            categoryId: testCategory.id,
            frequency: .daily
        )
        store.addHabit(habit)
        
        let beforeCompletion = store.habits.first(where: { $0.id == habit.id })!
        XCTAssertFalse(beforeCompletion.isCompletedToday, "Should not be completed initially")
        
        // When - mark complete
        store.toggleCompletion(for: habit)
        
        // Then
        let afterCompletion = store.habits.first(where: { $0.id == habit.id })!
        XCTAssertTrue(afterCompletion.isCompletedToday, "Should be completed after toggle")
        
        print("✅ UPDATE: Successfully toggled completion (completed: \(afterCompletion.isCompletedToday))")
        
        // When - toggle again to uncomplete
        store.toggleCompletion(for: afterCompletion)
        
        // Then
        let afterUncomplete = store.habits.first(where: { $0.id == habit.id })!
        XCTAssertFalse(afterUncomplete.isCompletedToday, "Should be uncompleted after second toggle")
        
        print("✅ UPDATE: Successfully toggled completion off (completed: \(afterUncomplete.isCompletedToday))")
    }
    
    // MARK: - DELETE Tests
    
    func testDeleteHabit() async throws {
        // Given
        let habit = Habit(
            title: "To Be Deleted",
            notes: "",
            icon: "trash.fill",
            colorHex: "#FF0000",
            categoryId: testCategory.id,
            frequency: .daily
        )
        store.addHabit(habit)
        let countBeforeDelete = store.habits.count
        XCTAssertNotNil(store.habits.first(where: { $0.id == habit.id }), "Habit should exist before delete")
        
        // When
        store.deleteHabit(habit)
        
        // Then
        XCTAssertEqual(store.habits.count, countBeforeDelete - 1, "Habit count should decrease by 1")
        XCTAssertNil(store.habits.first(where: { $0.id == habit.id }), "Habit should not exist after delete")
        
        print("✅ DELETE: Successfully deleted habit")
    }
    
    func testArchiveHabit() async throws {
        // Given
        let habit = Habit(
            title: "To Be Archived",
            notes: "",
            icon: "archivebox.fill",
            colorHex: "#FFA500",
            categoryId: testCategory.id,
            frequency: .daily
        )
        store.addHabit(habit)
        XCTAssertFalse(store.habits.first(where: { $0.id == habit.id })!.isArchived, "Should not be archived initially")
        
        // When
        store.archiveHabit(habit)
        
        // Then
        let archivedHabit = store.habits.first(where: { $0.id == habit.id })
        XCTAssertNotNil(archivedHabit, "Habit should still exist after archive")
        XCTAssertTrue(archivedHabit!.isArchived, "Habit should be archived")
        
        print("✅ DELETE (soft): Successfully archived habit '\(archivedHabit!.title)'")
    }
    
    func testUnarchiveHabit() async throws {
        // Given
        var habit = Habit(
            title: "To Be Unarchived",
            notes: "",
            icon: "archivebox.fill",
            colorHex: "#FFA500",
            categoryId: testCategory.id,
            frequency: .daily
        )
        habit.isArchived = true
        store.addHabit(habit)
        
        // When
        store.unarchiveHabit(habit)
        
        // Then
        let unarchivedHabit = store.habits.first(where: { $0.id == habit.id })
        XCTAssertFalse(unarchivedHabit!.isArchived, "Habit should be unarchived")
        
        print("✅ RESTORE: Successfully unarchived habit '\(unarchivedHabit!.title)'")
    }
    
    // MARK: - Full CRUD Lifecycle Test
    
    func testFullCRUDLifecycle() async throws {
        print("\n🔄 Starting Full CRUD Lifecycle Test...\n")
        
        // CREATE
        let habit = Habit(
            title: "Lifecycle Test Habit",
            notes: "Testing full CRUD cycle",
            icon: "repeat.circle.fill",
            colorHex: "#10B981",
            categoryId: testCategory.id,
            frequency: .daily
        )
        store.addHabit(habit)
        print("1️⃣ CREATE: Added '\(habit.title)'")
        
        // READ
        var currentHabit = store.habits.first(where: { $0.id == habit.id })!
        XCTAssertEqual(currentHabit.title, "Lifecycle Test Habit")
        print("2️⃣ READ: Found habit with title '\(currentHabit.title)'")
        
        // UPDATE - change title
        currentHabit.title = "Updated Lifecycle Habit"
        currentHabit.notes = "Notes have been updated"
        store.updateHabit(currentHabit)
        
        currentHabit = store.habits.first(where: { $0.id == habit.id })!
        XCTAssertEqual(currentHabit.title, "Updated Lifecycle Habit")
        XCTAssertEqual(currentHabit.notes, "Notes have been updated")
        print("3️⃣ UPDATE: Changed title to '\(currentHabit.title)'")
        
        // UPDATE - toggle completion
        store.toggleCompletion(for: currentHabit)
        currentHabit = store.habits.first(where: { $0.id == habit.id })!
        XCTAssertTrue(currentHabit.isCompletedToday)
        print("4️⃣ UPDATE: Marked as completed today ✓")
        
        // SOFT DELETE - archive
        store.archiveHabit(currentHabit)
        currentHabit = store.habits.first(where: { $0.id == habit.id })!
        XCTAssertTrue(currentHabit.isArchived)
        print("5️⃣ ARCHIVE: Soft-deleted (archived) the habit")
        
        // RESTORE
        store.unarchiveHabit(currentHabit)
        currentHabit = store.habits.first(where: { $0.id == habit.id })!
        XCTAssertFalse(currentHabit.isArchived)
        print("6️⃣ RESTORE: Unarchived the habit")
        
        // HARD DELETE
        store.deleteHabit(currentHabit)
        XCTAssertNil(store.habits.first(where: { $0.id == habit.id }))
        print("7️⃣ DELETE: Permanently deleted the habit")
        
        print("\n✅ Full CRUD Lifecycle Test PASSED!\n")
    }
}
