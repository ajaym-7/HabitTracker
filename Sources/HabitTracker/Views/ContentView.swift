import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: HabitStore
    @State private var showingCreateHabit = false
    @State private var showingSettings = false
    @State private var showingAnalytics = false
    @State private var habitToEdit: Habit?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(
                showingCreateHabit: $showingCreateHabit,
                showingSettings: $showingSettings,
                showingAnalytics: $showingAnalytics
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
        } detail: {
            HabitListView(
                habitToEdit: $habitToEdit,
                showingCreateHabit: $showingCreateHabit
            )
        }
        .frame(minWidth: 900, minHeight: 650)
        .sheet(isPresented: $showingCreateHabit) {
            HabitEditorView(habit: nil)
                .environmentObject(store)
        }
        .sheet(item: $habitToEdit) { habit in
            HabitEditorView(habit: habit)
                .environmentObject(store)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(store)
        }
        .sheet(isPresented: $showingAnalytics) {
            AnalyticsDashboardView()
                .environmentObject(store)
        }
    }
}

// MARK: - Sidebar
struct SidebarView: View {
    @EnvironmentObject var store: HabitStore
    @Binding var showingCreateHabit: Bool
    @Binding var showingSettings: Bool
    @Binding var showingAnalytics: Bool
    @State private var showingCategoryManager = false
    @State private var showingProfile = false
    
    var body: some View {
        List(selection: $store.selectedCategoryId) {
            // Profile Section
            Section {
                Button(action: { showingProfile = true }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)
                            
                            Text(String((UserDefaults.standard.string(forKey: "userName") ?? "H").prefix(1)).uppercased())
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(UserDefaults.standard.string(forKey: "userName") ?? "Habit Master")
                                .font(.headline)
                            Text("Level \(userLevel)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            
            // Quick Filters Section
            Section {
                FilterRow(
                    title: "All Habits",
                    icon: "tray.full.fill",
                    count: store.habits.filter { !$0.isArchived }.count,
                    color: .blue,
                    isSelected: store.selectedCategoryId == nil && store.filterOption == .active
                )
                .tag(nil as UUID?)
                .onTapGesture {
                    store.selectedCategoryId = nil
                    store.filterOption = .active
                }
                
                FilterRow(
                    title: "Due Today",
                    icon: "calendar.badge.clock",
                    count: store.habits.filter { $0.isDueToday && !$0.isArchived }.count,
                    color: .orange,
                    isSelected: store.filterOption == .dueToday
                )
                .onTapGesture {
                    store.selectedCategoryId = nil
                    store.filterOption = .dueToday
                }
                
                FilterRow(
                    title: "Completed",
                    icon: "checkmark.circle.fill",
                    count: store.habits.filter { $0.isCompletedToday && !$0.isArchived }.count,
                    color: .green,
                    isSelected: store.filterOption == .completed
                )
                .onTapGesture {
                    store.selectedCategoryId = nil
                    store.filterOption = .completed
                }
            } header: {
                Text("Quick Filters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Categories Section
            Section {
                ForEach(store.categories) { category in
                    CategoryRow(category: category, isSelected: store.selectedCategoryId == category.id)
                        .tag(category.id as UUID?)
                        .onTapGesture {
                            store.selectedCategoryId = category.id
                            store.filterOption = .active
                        }
                }
            } header: {
                HStack {
                    Text("Categories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: { showingCategoryManager = true }) {
                        Image(systemName: "gear")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Archive Section
            Section {
                FilterRow(
                    title: "Archived",
                    icon: "archivebox.fill",
                    count: store.habits.filter { $0.isArchived }.count,
                    color: .gray,
                    isSelected: store.filterOption == .archived
                )
                .onTapGesture {
                    store.selectedCategoryId = nil
                    store.filterOption = .archived
                }
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingCreateHabit = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .keyboardShortcut("n", modifiers: .command)
                .help("New Habit (⌘N)")
            }
            
            ToolbarItem(placement: .automatic) {
                Button(action: { showingAnalytics = true }) {
                    Image(systemName: "chart.bar.fill")
                }
                .help("Analytics")
            }
            
            ToolbarItem(placement: .automatic) {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                }
                .help("Settings")
            }
        }
        .sheet(isPresented: $showingCategoryManager) {
            CategoryManagerView()
                .environmentObject(store)
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
                .environmentObject(store)
        }
        .navigationTitle("Habits")
    }
    
    var userLevel: Int {
        let completions = store.totalCompletions
        if completions >= 1000 { return 10 }
        if completions >= 500 { return 9 }
        if completions >= 300 { return 8 }
        if completions >= 200 { return 7 }
        if completions >= 100 { return 6 }
        if completions >= 50 { return 5 }
        if completions >= 30 { return 4 }
        if completions >= 15 { return 3 }
        if completions >= 5 { return 2 }
        return 1
    }
}

// MARK: - Filter Row
struct FilterRow: View {
    let title: String
    let icon: String
    let count: Int
    let color: Color
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .fontWeight(isSelected ? .semibold : .regular)
            
            Spacer()
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.15))
                .cornerRadius(8)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Category Row
struct CategoryRow: View {
    @EnvironmentObject var store: HabitStore
    let category: HabitCategory
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: category.colorHex).gradient)
                .frame(width: 24, height: 24)
                .overlay(
                    Image(systemName: category.icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            Text(category.name)
                .fontWeight(isSelected ? .semibold : .regular)
            
            Spacer()
            
            Text("\(store.habitsCount(for: category))")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.15))
                .cornerRadius(8)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(HabitStore())
    }
}
