import SwiftUI
import AppKit

// Helper to make sheet become key window for text input
struct BecomeKeyWindow: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            view.window?.makeKey()
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct HabitEditorView: View {
    @EnvironmentObject var store: HabitStore
    @Environment(\.dismiss) private var dismiss
    
    let habit: Habit?
    
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var selectedIcon: String = "star.fill"
    @State private var selectedColor: String = "#5B8DEF"
    @State private var selectedCategoryId: UUID?
    @State private var frequency: HabitFrequency = .daily
    @State private var customDays: Set<Int> = []
    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    
    var isEditing: Bool { habit != nil }
    var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty && selectedCategoryId != nil }
    
    let icons = [
        "star.fill", "heart.fill", "bolt.fill", "flame.fill", "leaf.fill",
        "drop.fill", "moon.fill", "sun.max.fill", "cloud.fill", "snowflake",
        "figure.run", "figure.walk", "figure.yoga", "figure.strengthtraining.traditional",
        "book.fill", "pencil", "graduationcap.fill", "brain.head.profile",
        "cup.and.saucer.fill", "fork.knife", "pill.fill", "cross.fill",
        "bed.double.fill", "alarm.fill", "clock.fill", "calendar",
        "dollarsign.circle.fill", "creditcard.fill", "cart.fill", "gift.fill",
        "music.note", "paintbrush.fill", "camera.fill", "gamecontroller.fill",
        "phone.fill", "envelope.fill", "bubble.left.fill", "person.2.fill"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Text(isEditing ? "Edit Habit" : "New Habit")
                    .font(.headline)
                
                Spacer()
                
                Button(isEditing ? "Save" : "Create") {
                    saveHabit()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Content - Using Form for better macOS text input handling
            Form {
                Section("Habit Details") {
                    TextField("Title", text: $title, prompt: Text("e.g., Morning Run"))
                    
                    TextField("Notes", text: $notes, prompt: Text("Optional notes..."), axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Appearance") {
                    // Preview
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: selectedColor).gradient)
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: selectedIcon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title.isEmpty ? "Habit Name" : title)
                                .font(.headline)
                                .foregroundColor(title.isEmpty ? .secondary : .primary)
                            
                            if let category = store.categories.first(where: { $0.id == selectedCategoryId }) {
                                HStack(spacing: 4) {
                                    Image(systemName: category.icon)
                                        .font(.caption2)
                                    Text(category.name)
                                        .font(.caption)
                                }
                                .foregroundColor(Color(hex: category.colorHex))
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    
                    // Icon selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Icon")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(36), spacing: 8), count: 10), spacing: 8) {
                            ForEach(icons, id: \.self) { icon in
                                Button(action: { selectedIcon = icon }) {
                                    Image(systemName: icon)
                                        .font(.system(size: 16))
                                        .frame(width: 36, height: 36)
                                        .foregroundColor(selectedIcon == icon ? .white : .primary)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedIcon == icon ? Color(hex: selectedColor) : Color.gray.opacity(0.1))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Color selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(32), spacing: 8), count: 10), spacing: 8) {
                            ForEach(Color.habitColors, id: \.self) { colorHex in
                                Button(action: { selectedColor = colorHex }) {
                                    Circle()
                                        .fill(Color(hex: colorHex))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: selectedColor == colorHex ? 3 : 0)
                                        )
                                        .shadow(color: selectedColor == colorHex ? Color(hex: colorHex).opacity(0.5) : .clear, radius: 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                Section("Category") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                        ForEach(store.categories) { category in
                            Button(action: { selectedCategoryId = category.id }) {
                                HStack(spacing: 6) {
                                    Image(systemName: category.icon)
                                        .font(.system(size: 12))
                                    Text(category.name)
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .foregroundColor(selectedCategoryId == category.id ? .white : .primary)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedCategoryId == category.id ? Color(hex: category.colorHex) : Color.gray.opacity(0.1))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Section("Schedule") {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(HabitFrequency.allCases, id: \.self) { freq in
                            HStack {
                                Image(systemName: freq.icon)
                                Text(freq.rawValue)
                            }
                            .tag(freq)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if frequency == .custom {
                        HStack(spacing: 8) {
                            ForEach(1...7, id: \.self) { day in
                                let dayName = Calendar.current.shortWeekdaySymbols[day - 1]
                                Button(action: { toggleDay(day) }) {
                                    Text(String(dayName.prefix(1)))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .frame(width: 32, height: 32)
                                        .foregroundColor(customDays.contains(day) ? .white : .primary)
                                        .background(
                                            Circle()
                                                .fill(customDays.contains(day) ? Color(hex: selectedColor) : Color.gray.opacity(0.1))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                Section("Reminder") {
                    Toggle(isOn: $reminderEnabled) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.orange)
                            Text("Daily Reminder")
                        }
                    }
                    
                    if reminderEnabled {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 550, height: 700)
        .background(BecomeKeyWindow())
        .onAppear {
            if let habit = habit {
                title = habit.title
                notes = habit.notes
                selectedIcon = habit.icon
                selectedColor = habit.colorHex
                selectedCategoryId = habit.categoryId
                frequency = habit.frequency
                customDays = Set(habit.customDays)
                reminderEnabled = habit.reminderEnabled
                reminderTime = habit.reminderTime ?? Date()
            } else if let firstCategory = store.categories.first {
                selectedCategoryId = firstCategory.id
            }
        }
    }
    
    private func toggleDay(_ day: Int) {
        if customDays.contains(day) {
            customDays.remove(day)
        } else {
            customDays.insert(day)
        }
    }
    
    private func saveHabit() {
        guard let categoryId = selectedCategoryId else { return }
        
        if var existingHabit = habit {
            existingHabit.title = title.trimmingCharacters(in: .whitespaces)
            existingHabit.notes = notes
            existingHabit.icon = selectedIcon
            existingHabit.colorHex = selectedColor
            existingHabit.categoryId = categoryId
            existingHabit.frequency = frequency
            existingHabit.customDays = Array(customDays)
            existingHabit.reminderEnabled = reminderEnabled
            existingHabit.reminderTime = reminderEnabled ? reminderTime : nil
            
            store.updateHabit(existingHabit)
        } else {
            let newHabit = Habit(
                title: title.trimmingCharacters(in: .whitespaces),
                notes: notes,
                icon: selectedIcon,
                colorHex: selectedColor,
                categoryId: categoryId,
                frequency: frequency,
                customDays: Array(customDays),
                reminderEnabled: reminderEnabled,
                reminderTime: reminderEnabled ? reminderTime : nil
            )
            store.addHabit(newHabit)
        }
        
        dismiss()
    }
}
