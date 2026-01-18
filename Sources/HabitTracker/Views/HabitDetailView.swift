import SwiftUI
import Charts

struct HabitDetailView: View {
    @EnvironmentObject var store: HabitStore
    @Environment(\.dismiss) private var dismiss
    
    let habit: Habit
    
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var selectedDate = Date()
    
    var currentHabit: Habit {
        store.habits.first { $0.id == habit.id } ?? habit
    }
    
    var category: HabitCategory? {
        store.category(for: currentHabit)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            Divider()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Stats cards
                    statsSection
                    
                    // Calendar section
                    calendarSection
                    
                    // Completion history chart
                    historyChartSection
                    
                    // Details section
                    detailsSection
                    
                    // Actions section
                    actionsSection
                }
                .padding(24)
            }
        }
        .frame(width: 600, height: 700)
        .sheet(isPresented: $showingEditSheet) {
            HabitEditorView(habit: currentHabit)
                .environmentObject(store)
        }
        .alert("Delete Habit", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                store.deleteHabit(currentHabit)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete \"\(currentHabit.title)\"? This action cannot be undone.")
        }
    }
    
    // MARK: - Header Section
    var headerSection: some View {
        HStack(spacing: 16) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.borderless)
            
            ZStack {
                Circle()
                    .fill(Color(hex: currentHabit.colorHex).gradient)
                    .frame(width: 60, height: 60)
                    .shadow(color: Color(hex: currentHabit.colorHex).opacity(0.4), radius: 8)
                
                Image(systemName: currentHabit.icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(currentHabit.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let category = category {
                    HStack(spacing: 4) {
                        Image(systemName: category.icon)
                            .font(.caption)
                        Text(category.name)
                            .font(.caption)
                    }
                    .foregroundColor(Color(hex: category.colorHex))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: category.colorHex).opacity(0.1))
                    .cornerRadius(6)
                }
            }
            
            Spacer()
            
            // Quick complete button
            Button(action: toggleTodayCompletion) {
                HStack(spacing: 8) {
                    Image(systemName: currentHabit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                    Text(currentHabit.isCompletedToday ? "Completed" : "Mark Complete")
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .foregroundColor(currentHabit.isCompletedToday ? .white : Color(hex: currentHabit.colorHex))
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(currentHabit.isCompletedToday ? Color(hex: currentHabit.colorHex) : Color(hex: currentHabit.colorHex).opacity(0.1))
                )
            }
            .buttonStyle(.borderless)
            
            Button(action: { showingEditSheet = true }) {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.borderless)
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    // MARK: - Stats Section
    var statsSection: some View {
        HStack(spacing: 16) {
            DetailStatCard(
                title: "Current Streak",
                value: "\(currentHabit.currentStreak)",
                subtitle: "days",
                icon: "flame.fill",
                color: .orange
            )
            
            DetailStatCard(
                title: "Best Streak",
                value: "\(currentHabit.longestStreak)",
                subtitle: "days",
                icon: "trophy.fill",
                color: .yellow
            )
            
            DetailStatCard(
                title: "This Month",
                value: "\(Int(currentHabit.completionRateThisMonth * 100))%",
                subtitle: "completion",
                icon: "chart.pie.fill",
                color: .blue
            )
            
            DetailStatCard(
                title: "Total",
                value: "\(currentHabit.completedDates.count)",
                subtitle: "completions",
                icon: "checkmark.seal.fill",
                color: .green
            )
        }
    }
    
    // MARK: - Calendar Section
    var calendarSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                Text("Completion Calendar")
                    .font(.headline)
                
                MonthCalendarView(habit: currentHabit, selectedDate: $selectedDate) { date in
                    store.toggleCompletion(for: currentHabit, on: date)
                }
            }
        } label: {
            Label("Calendar", systemImage: "calendar")
        }
    }
    
    // MARK: - History Chart Section
    var historyChartSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                Text("Weekly Progress")
                    .font(.headline)
                
                let weekData = last7DaysData()
                
                Chart(weekData, id: \.date) { item in
                    BarMark(
                        x: .value("Day", item.date, unit: .day),
                        y: .value("Completed", item.completed ? 1 : 0)
                    )
                    .foregroundStyle(item.completed ? Color(hex: currentHabit.colorHex).gradient : Color.gray.opacity(0.3).gradient)
                    .cornerRadius(4)
                }
                .frame(height: 100)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(values: [0, 1]) { value in
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text(intValue == 1 ? "✓" : "")
                            }
                        }
                    }
                }
            }
        } label: {
            Label("Progress", systemImage: "chart.bar.fill")
        }
    }
    
    // MARK: - Details Section
    var detailsSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                // Notes
                if !currentHabit.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(currentHabit.notes)
                            .font(.body)
                    }
                }
                
                Divider()
                
                // Schedule
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Frequency")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack(spacing: 4) {
                            Image(systemName: currentHabit.frequency.icon)
                            Text(currentHabit.frequency.rawValue)
                        }
                        .font(.body)
                    }
                    
                    Spacer()
                    
                    if currentHabit.frequency == .custom {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Days")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            HStack(spacing: 4) {
                                ForEach(currentHabit.customDays.sorted(), id: \.self) { day in
                                    Text(Calendar.current.shortWeekdaySymbols[day - 1].prefix(1))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .frame(width: 24, height: 24)
                                        .background(Color(hex: currentHabit.colorHex).opacity(0.2))
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                // Reminder
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reminder")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if currentHabit.reminderEnabled, let time = currentHabit.reminderTime {
                            HStack(spacing: 4) {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(.orange)
                                Text(time, style: .time)
                            }
                            .font(.body)
                        } else {
                            Text("Not set")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Created")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(currentHabit.createdAt, style: .date)
                            .font(.body)
                    }
                }
            }
        } label: {
            Label("Details", systemImage: "info.circle")
        }
    }
    
    // MARK: - Actions Section
    var actionsSection: some View {
        HStack(spacing: 16) {
            Button(action: { showingEditSheet = true }) {
                Label("Edit Habit", systemImage: "pencil")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            if currentHabit.isArchived {
                Button(action: { store.unarchiveHabit(currentHabit) }) {
                    Label("Unarchive", systemImage: "tray.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
            } else {
                Button(action: { store.archiveHabit(currentHabit) }) {
                    Label("Archive", systemImage: "archivebox")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }
            
            Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                Label("Delete", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
    
    // MARK: - Helper Methods
    private func toggleTodayCompletion() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            store.toggleCompletion(for: currentHabit)
        }
    }
    
    private func last7DaysData() -> [(date: Date, completed: Bool)] {
        let calendar = Calendar.current
        return (0..<7).reversed().compactMap { offset -> (Date, Bool)? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            return (date, currentHabit.isCompleted(on: date))
        }
    }
}

// MARK: - Detail Stat Card
struct DetailStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Month Calendar View
struct MonthCalendarView: View {
    let habit: Habit
    @Binding var selectedDate: Date
    let onToggle: (Date) -> Void
    
    @State private var displayedMonth = Date()
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    
    var body: some View {
        VStack(spacing: 16) {
            // Month navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                }
                .buttonStyle(.borderless)
                
                Spacer()
                
                Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                }
                .buttonStyle(.borderless)
            }
            
            // Day headers
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day.prefix(2))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar days
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            isCompleted: habit.isCompleted(on: date),
                            isToday: calendar.isDateInToday(date),
                            isFuture: date > Date(),
                            habitColor: habit.colorHex,
                            onTap: { onToggle(date) }
                        )
                    } else {
                        Color.clear
                            .frame(height: 36)
                    }
                }
            }
        }
    }
    
    private func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
    
    private func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
    
    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var days: [Date?] = []
        var current = monthFirstWeek.start
        
        while current < monthInterval.end || days.count % 7 != 0 {
            if calendar.isDate(current, equalTo: displayedMonth, toGranularity: .month) {
                days.append(current)
            } else {
                days.append(nil)
            }
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }
        
        return days
    }
}

// MARK: - Calendar Day View
struct CalendarDayView: View {
    let date: Date
    let isCompleted: Bool
    let isToday: Bool
    let isFuture: Bool
    let habitColor: String
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            if !isFuture {
                onTap()
            }
        }) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 14, weight: isToday ? .bold : .regular))
                .foregroundColor(textColor)
                .frame(width: 36, height: 36)
                .background(backgroundColor)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isToday ? Color.primary : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.borderless)
        .disabled(isFuture)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var textColor: Color {
        if isFuture { return .secondary.opacity(0.5) }
        if isCompleted { return .white }
        return .primary
    }
    
    private var backgroundColor: Color {
        if isCompleted { return Color(hex: habitColor) }
        if isHovered && !isFuture { return Color(hex: habitColor).opacity(0.2) }
        return Color.clear
    }
}
