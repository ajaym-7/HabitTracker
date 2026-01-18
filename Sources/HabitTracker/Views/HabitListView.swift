import SwiftUI

struct HabitListView: View {
    @EnvironmentObject var store: HabitStore
    @Binding var habitToEdit: Habit?
    @Binding var showingCreateHabit: Bool
    @State private var hoveredHabitId: UUID?
    @State private var selectedHabitForDetail: Habit?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView(showingCreateHabit: $showingCreateHabit)
            
            Divider()
            
            // Content
            if store.filteredHabits.isEmpty {
                EmptyStateView(showingCreateHabit: $showingCreateHabit)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(store.filteredHabits) { habit in
                            HabitCardView(
                                habit: habit,
                                isHovered: hoveredHabitId == habit.id,
                                onEdit: { habitToEdit = habit }
                            )
                            .onHover { hovering in
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    hoveredHabitId = hovering ? habit.id : nil
                                }
                            }
                            .onTapGesture {
                                selectedHabitForDetail = habit
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(item: $selectedHabitForDetail) { habit in
            HabitDetailView(habit: habit)
                .environmentObject(store)
        }
    }
}

// MARK: - Header
struct HeaderView: View {
    @EnvironmentObject var store: HabitStore
    @Binding var showingCreateHabit: Bool
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<21: return "Good Evening"
        default: return "Good Night"
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            // Left side: Greeting and progress
            VStack(alignment: .leading, spacing: 8) {
                Text(greeting)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(Date(), style: .date)
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                // Today's Progress
                HStack(spacing: 16) {
                    ProgressRing(progress: store.todayProgress, size: 60)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(Int(store.todayProgress * 100))% Complete")
                            .font(.headline)
                        Text("\(store.totalCompletionsToday) of \(store.habits.filter { $0.isDueToday && !$0.isArchived }.count) habits done")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 8)
            }
            
            Spacer()
            
            // Right side: Quick stats
            HStack(spacing: 16) {
                QuickStatCard(
                    title: "Best Streak",
                    value: "\(store.bestCurrentStreak)",
                    icon: "flame.fill",
                    color: .orange
                )
                
                QuickStatCard(
                    title: "This Week",
                    value: "\(Int(store.weeklyCompletionRate() * 100))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
                
                QuickStatCard(
                    title: "Total",
                    value: "\(store.totalCompletions)",
                    icon: "checkmark.seal.fill",
                    color: .blue
                )
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color(nsColor: .controlBackgroundColor), Color(nsColor: .windowBackgroundColor)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Progress Ring
struct ProgressRing: View {
    let progress: Double
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 6)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [.green, .blue, .purple, .green],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
            
            Text("\(Int(progress * 100))")
                .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Quick Stat Card
struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 100, height: 100)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(16)
        .shadow(color: color.opacity(isHovered ? 0.3 : 0.1), radius: isHovered ? 12 : 4)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    @Binding var showingCreateHabit: Bool
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 150, height: 150)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                    .rotationEffect(.degrees(isAnimating ? 10 : -10))
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
            }
            
            VStack(spacing: 8) {
                Text("No Habits Here")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Start building better habits today!\nCreate your first habit to get started.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingCreateHabit = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create New Habit")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.accentColor.gradient)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            isAnimating = true
        }
    }
}
