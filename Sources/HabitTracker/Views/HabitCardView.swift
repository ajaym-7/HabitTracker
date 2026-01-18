import SwiftUI

struct HabitCardView: View {
    @EnvironmentObject var store: HabitStore
    let habit: Habit
    let isHovered: Bool
    let onEdit: () -> Void
    
    @State private var showConfetti = false
    @State private var completionScale: CGFloat = 1.0
    
    var category: HabitCategory? {
        store.category(for: habit)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Left: Icon and color
            ZStack {
                Circle()
                    .fill(Color(hex: habit.colorHex).gradient)
                    .frame(width: 56, height: 56)
                    .shadow(color: Color(hex: habit.colorHex).opacity(0.4), radius: isHovered ? 10 : 4)
                
                Image(systemName: habit.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
            
            // Center: Info
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(habit.title)
                        .font(.system(size: 16, weight: .semibold))
                        .strikethrough(habit.isCompletedToday, color: .secondary)
                        .foregroundColor(habit.isCompletedToday ? .secondary : .primary)
                    
                    if habit.isArchived {
                        Text("Archived")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                HStack(spacing: 10) {
                    // Category badge
                    if let category = category {
                        HStack(spacing: 4) {
                            Image(systemName: category.icon)
                                .font(.system(size: 10))
                            Text(category.name)
                                .font(.system(size: 11))
                        }
                        .foregroundColor(Color(hex: category.colorHex))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: category.colorHex).opacity(0.15))
                        .cornerRadius(6)
                    }
                    
                    // Frequency badge
                    HStack(spacing: 4) {
                        Image(systemName: habit.frequency.icon)
                            .font(.system(size: 10))
                        Text(habit.frequency.rawValue)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                    
                    // Streak badge
                    if habit.currentStreak > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("\(habit.currentStreak)")
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 11))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(6)
                    }
                }
                
                // Notes preview
                if !habit.notes.isEmpty && isHovered {
                    Text(habit.notes)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            
            Spacer()
            
            // Right: Actions - Always visible action buttons
            HStack(spacing: 12) {
                // Mini progress for the week
                WeekProgressView(habit: habit)
                
                // Action buttons - always visible, more prominent
                HStack(spacing: 6) {
                    // Edit button - always visible and larger
                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("Edit Habit")
                    
                    // Archive/Unarchive button
                    if habit.isArchived {
                        Button(action: { store.unarchiveHabit(habit) }) {
                            Image(systemName: "tray.and.arrow.up.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                        }
                        .buttonStyle(.plain)
                        .help("Unarchive")
                    } else {
                        Button(action: { store.archiveHabit(habit) }) {
                            Image(systemName: "archivebox.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.orange)
                        }
                        .buttonStyle(.plain)
                        .help("Archive")
                    }
                    
                    // Delete button
                    Button(action: { store.deleteHabit(habit) }) {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Delete")
                }
                .opacity(isHovered ? 1.0 : 0.4)
                
                // Completion button - larger and more prominent
                Button(action: toggleCompletion) {
                    ZStack {
                        Circle()
                            .stroke(Color(hex: habit.colorHex), lineWidth: 4)
                            .frame(width: 52, height: 52)
                        
                        if habit.isCompletedToday {
                            Circle()
                                .fill(Color(hex: habit.colorHex).gradient)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            // Show a hint when not completed
                            Circle()
                                .fill(Color(hex: habit.colorHex).opacity(0.1))
                                .frame(width: 44, height: 44)
                        }
                        
                        // Confetti overlay
                        if showConfetti {
                            ConfettiView(color: Color(hex: habit.colorHex))
                        }
                    }
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .scaleEffect(completionScale)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: completionScale)
                .help(habit.isCompletedToday ? "Mark Incomplete" : "Mark Complete")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(
                    color: isHovered ? Color(hex: habit.colorHex).opacity(0.2) : Color.black.opacity(0.05),
                    radius: isHovered ? 12 : 4,
                    y: isHovered ? 6 : 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isHovered ? Color(hex: habit.colorHex).opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
    }
    
    private func toggleCompletion() {
        let wasCompleted = habit.isCompletedToday
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            store.toggleCompletion(for: habit)
            completionScale = 1.2
        }
        
        if !wasCompleted {
            showConfetti = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showConfetti = false
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                completionScale = 1.0
            }
        }
    }
}

// MARK: - Week Progress View
struct WeekProgressView: View {
    let habit: Habit
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { dayOffset in
                let date = Calendar.current.date(byAdding: .day, value: -(6 - dayOffset), to: Date()) ?? Date()
                let isCompleted = habit.isCompleted(on: date)
                let isToday = Calendar.current.isDateInToday(date)
                
                Circle()
                    .fill(isCompleted ? Color(hex: habit.colorHex) : Color.gray.opacity(0.2))
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(isToday ? Color.primary : Color.clear, lineWidth: 1)
                    )
            }
        }
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    let color: Color
    
    var body: some View {
        ZStack {
            ForEach(0..<15, id: \.self) { index in
                ConfettiParticle(color: color, index: index)
            }
        }
    }
}

struct ConfettiParticle: View {
    let color: Color
    let index: Int
    
    @State private var isAnimating = false
    
    var randomAngle: Double {
        Double(index) * (360 / 15) + Double.random(in: -20...20)
    }
    
    var randomDistance: CGFloat {
        CGFloat.random(in: 30...60)
    }
    
    var randomColor: Color {
        [color, .yellow, .orange, .pink, .purple][index % 5]
    }
    
    var body: some View {
        Circle()
            .fill(randomColor)
            .frame(width: 6, height: 6)
            .offset(
                x: isAnimating ? cos(randomAngle * .pi / 180) * randomDistance : 0,
                y: isAnimating ? sin(randomAngle * .pi / 180) * randomDistance : 0
            )
            .opacity(isAnimating ? 0 : 1)
            .scaleEffect(isAnimating ? 0.5 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    isAnimating = true
                }
            }
    }
}
