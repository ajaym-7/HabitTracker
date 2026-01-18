import SwiftUI
import Charts

// MARK: - Profile View Model
@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var userName: String {
        didSet { UserDefaults.standard.set(userName, forKey: "userName") }
    }
    @Published var userAvatar: String {
        didSet { UserDefaults.standard.set(userAvatar, forKey: "userAvatar") }
    }
    @Published var joinDate: Date
    @Published var isEditingProfile = false
    @Published var selectedTab: ProfileTab = .overview
    @Published var showingExportSheet = false
    @Published var showingResetAlert = false
    @Published var animateStats = false
    
    enum ProfileTab: String, CaseIterable {
        case overview = "Overview"
        case achievements = "Achievements"
        case insights = "Insights"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .overview: return "person.crop.circle"
            case .achievements: return "trophy.fill"
            case .insights: return "chart.bar.xaxis"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    init() {
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? "Habit Master"
        self.userAvatar = UserDefaults.standard.string(forKey: "userAvatar") ?? "person.crop.circle.fill"
        self.joinDate = UserDefaults.standard.object(forKey: "joinDate") as? Date ?? Date()
        
        if UserDefaults.standard.object(forKey: "joinDate") == nil {
            UserDefaults.standard.set(Date(), forKey: "joinDate")
        }
    }
    
    var membershipDuration: String {
        let days = Calendar.current.dateComponents([.day], from: joinDate, to: Date()).day ?? 0
        if days == 0 { return "Just joined!" }
        if days == 1 { return "1 day" }
        if days < 30 { return "\(days) days" }
        let months = days / 30
        if months == 1 { return "1 month" }
        if months < 12 { return "\(months) months" }
        let years = months / 12
        return years == 1 ? "1 year" : "\(years) years"
    }
}

// MARK: - Achievement Model
@MainActor
struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
    let tier: Tier
    let requirement: @MainActor (HabitStore) -> Bool
    let progress: @MainActor (HabitStore) -> Double
    
    enum Tier: Int, CaseIterable {
        case bronze = 1, silver = 2, gold = 3, platinum = 4, diamond = 5
        
        var name: String {
            switch self {
            case .bronze: return "Bronze"
            case .silver: return "Silver"
            case .gold: return "Gold"
            case .platinum: return "Platinum"
            case .diamond: return "Diamond"
            }
        }
        
        var glowColor: Color {
            switch self {
            case .bronze: return .orange
            case .silver: return .gray
            case .gold: return .yellow
            case .platinum: return .cyan
            case .diamond: return .purple
            }
        }
    }
    
    static let all: [Achievement] = [
        // Starter achievements
        Achievement(
            title: "First Step",
            description: "Complete your first habit",
            icon: "figure.walk",
            color: .green,
            tier: .bronze,
            requirement: { store in store.totalCompletions >= 1 },
            progress: { store in min(Double(store.totalCompletions) / 1.0, 1.0) }
        ),
        Achievement(
            title: "Getting Started",
            description: "Create 3 habits",
            icon: "plus.circle.fill",
            color: .blue,
            tier: .bronze,
            requirement: { store in store.habits.count >= 3 },
            progress: { store in min(Double(store.habits.count) / 3.0, 1.0) }
        ),
        
        // Streak achievements
        Achievement(
            title: "Week Warrior",
            description: "Maintain a 7-day streak",
            icon: "flame.fill",
            color: .orange,
            tier: .silver,
            requirement: { store in store.bestCurrentStreak >= 7 },
            progress: { store in min(Double(store.bestCurrentStreak) / 7.0, 1.0) }
        ),
        Achievement(
            title: "Fortnight Fighter",
            description: "Maintain a 14-day streak",
            icon: "flame.circle.fill",
            color: .orange,
            tier: .gold,
            requirement: { store in store.bestCurrentStreak >= 14 },
            progress: { store in min(Double(store.bestCurrentStreak) / 14.0, 1.0) }
        ),
        Achievement(
            title: "Monthly Master",
            description: "Maintain a 30-day streak",
            icon: "calendar.badge.checkmark",
            color: .red,
            tier: .platinum,
            requirement: { store in store.bestCurrentStreak >= 30 },
            progress: { store in min(Double(store.bestCurrentStreak) / 30.0, 1.0) }
        ),
        Achievement(
            title: "Legendary Streak",
            description: "Maintain a 100-day streak",
            icon: "crown.fill",
            color: .purple,
            tier: .diamond,
            requirement: { store in store.bestCurrentStreak >= 100 },
            progress: { store in min(Double(store.bestCurrentStreak) / 100.0, 1.0) }
        ),
        
        // Completion achievements
        Achievement(
            title: "Dedicated",
            description: "Complete 50 habits total",
            icon: "checkmark.circle.fill",
            color: .teal,
            tier: .silver,
            requirement: { store in store.totalCompletions >= 50 },
            progress: { store in min(Double(store.totalCompletions) / 50.0, 1.0) }
        ),
        Achievement(
            title: "Century Club",
            description: "Complete 100 habits total",
            icon: "100.circle.fill",
            color: .indigo,
            tier: .gold,
            requirement: { store in store.totalCompletions >= 100 },
            progress: { store in min(Double(store.totalCompletions) / 100.0, 1.0) }
        ),
        Achievement(
            title: "Habit Hero",
            description: "Complete 500 habits total",
            icon: "star.circle.fill",
            color: .yellow,
            tier: .platinum,
            requirement: { store in store.totalCompletions >= 500 },
            progress: { store in min(Double(store.totalCompletions) / 500.0, 1.0) }
        ),
        Achievement(
            title: "Grandmaster",
            description: "Complete 1000 habits total",
            icon: "sparkles",
            color: .purple,
            tier: .diamond,
            requirement: { store in store.totalCompletions >= 1000 },
            progress: { store in min(Double(store.totalCompletions) / 1000.0, 1.0) }
        ),
        
        // Organization achievements
        Achievement(
            title: "Organizer",
            description: "Create 5 categories",
            icon: "folder.fill",
            color: .cyan,
            tier: .silver,
            requirement: { store in store.categories.count >= 5 },
            progress: { store in min(Double(store.categories.count) / 5.0, 1.0) }
        ),
        Achievement(
            title: "Multi-Tasker",
            description: "Have 10 active habits",
            icon: "list.bullet.rectangle.fill",
            color: .mint,
            tier: .gold,
            requirement: { store in store.habits.filter { !$0.isArchived }.count >= 10 },
            progress: { store in min(Double(store.habits.filter { !$0.isArchived }.count) / 10.0, 1.0) }
        ),
        
        // Perfect day achievements
        Achievement(
            title: "Perfect Day",
            description: "Complete all habits in a day (min 3)",
            icon: "checkmark.seal.fill",
            color: .yellow,
            tier: .silver,
            requirement: { store in store.todayProgress >= 1.0 && store.habits.filter { $0.isDueToday && !$0.isArchived }.count >= 3 },
            progress: { store in store.todayProgress }
        ),
        Achievement(
            title: "Consistent",
            description: "Achieve 80% weekly completion rate",
            icon: "chart.line.uptrend.xyaxis",
            color: .green,
            tier: .gold,
            requirement: { store in store.weeklyCompletionRate() >= 0.8 },
            progress: { store in min(store.weeklyCompletionRate() / 0.8, 1.0) }
        ),
    ]
}

// MARK: - Main Profile View
struct ProfileView: View {
    @EnvironmentObject var store: HabitStore
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    @Namespace private var animation
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            profileHeader
            
            Divider()
            
            // Tab Bar
            tabBar
            
            Divider()
            
            // Content
            TabView(selection: $viewModel.selectedTab) {
                overviewTab
                    .tag(ProfileViewModel.ProfileTab.overview)
                
                achievementsTab
                    .tag(ProfileViewModel.ProfileTab.achievements)
                
                insightsTab
                    .tag(ProfileViewModel.ProfileTab.insights)
                
                settingsTab
                    .tag(ProfileViewModel.ProfileTab.settings)
            }
            .tabViewStyle(.automatic)
        }
        .frame(width: 750, height: 800)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                viewModel.animateStats = true
            }
        }
        .alert("Reset All Data", isPresented: $viewModel.showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset Everything", role: .destructive) {
                store.resetAllData()
                dismiss()
            }
        } message: {
            Text("This will permanently delete all your habits, categories, and progress. This action cannot be undone.")
        }
    }
    
    // MARK: - Header
    private var profileHeader: some View {
        HStack(spacing: 20) {
            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])
            
            Spacer()
            
            // Avatar and info
            HStack(spacing: 16) {
                // Animated Avatar
                ZStack {
                    // Outer ring with gradient animation
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [.purple, .blue, .cyan, .green, .yellow, .orange, .red, .purple],
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(viewModel.animateStats ? 360 : 0))
                        .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: viewModel.animateStats)
                    
                    // Avatar circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Text(String(viewModel.userName.prefix(1)).uppercased())
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.userName)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 12) {
                        Label("Level \(userLevel)", systemImage: "star.fill")
                            .foregroundColor(.yellow)
                        
                        Label(viewModel.membershipDuration, systemImage: "clock.fill")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }
            }
            
            Spacer()
            
            // Quick stats
            HStack(spacing: 24) {
                QuickStatView(
                    value: "\(store.totalCompletions)",
                    label: "Completions",
                    color: .green,
                    animate: viewModel.animateStats
                )
                
                QuickStatView(
                    value: "\(store.bestCurrentStreak)",
                    label: "Best Streak",
                    color: .orange,
                    animate: viewModel.animateStats
                )
                
                QuickStatView(
                    value: "\(unlockedAchievementsCount)/\(Achievement.all.count)",
                    label: "Achievements",
                    color: .purple,
                    animate: viewModel.animateStats
                )
            }
            
            Spacer()
            
            Color.clear.frame(width: 30)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    // MARK: - Tab Bar
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(ProfileViewModel.ProfileTab.allCases, id: \.self) { tab in
                Button(action: { 
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.selectedTab = tab
                    }
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18))
                        Text(tab.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(viewModel.selectedTab == tab ? .accentColor : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Group {
                            if viewModel.selectedTab == tab {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.accentColor.opacity(0.1))
                                    .matchedGeometryEffect(id: "tab", in: animation)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - Overview Tab
    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Level Progress Card
                levelProgressCard
                
                // Statistics Grid
                statisticsGrid
                
                // Recent Activity
                recentActivityCard
                
                // Category Breakdown
                categoryBreakdownCard
            }
            .padding(24)
        }
    }
    
    private var levelProgressCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Level \(userLevel)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text(levelTitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Level badge
                ZStack {
                    Circle()
                        .fill(levelColor.gradient)
                        .frame(width: 60, height: 60)
                        .shadow(color: levelColor.opacity(0.5), radius: 10)
                    
                    Text("\(userLevel)")
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                }
            }
            
            // Progress to next level
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(store.totalCompletions) / \(nextLevelRequirement) completions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(levelProgress * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(levelColor)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [levelColor, levelColor.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: viewModel.animateStats ? geometry.size.width * levelProgress : 0)
                            .animation(.spring(response: 0.8, dampingFraction: 0.6), value: viewModel.animateStats)
                    }
                }
                .frame(height: 12)
            }
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(16)
    }
    
    private var statisticsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(
                title: "Active Habits",
                value: "\(store.habits.filter { !$0.isArchived }.count)",
                icon: "list.bullet.circle.fill",
                color: .blue,
                animate: viewModel.animateStats
            )
            
            StatCard(
                title: "Today's Progress",
                value: "\(Int(store.todayProgress * 100))%",
                icon: "sun.max.fill",
                color: .yellow,
                animate: viewModel.animateStats
            )
            
            StatCard(
                title: "Weekly Rate",
                value: "\(Int(store.weeklyCompletionRate() * 100))%",
                icon: "calendar.circle.fill",
                color: .green,
                animate: viewModel.animateStats
            )
            
            StatCard(
                title: "Current Streak",
                value: "\(store.bestCurrentStreak)",
                icon: "flame.circle.fill",
                color: .orange,
                animate: viewModel.animateStats
            )
            
            StatCard(
                title: "Categories",
                value: "\(store.categories.count)",
                icon: "folder.circle.fill",
                color: .purple,
                animate: viewModel.animateStats
            )
            
            StatCard(
                title: "Avg per Day",
                value: String(format: "%.1f", averagePerDay),
                icon: "chart.line.uptrend.xyaxis.circle.fill",
                color: .teal,
                animate: viewModel.animateStats
            )
            
            StatCard(
                title: "Archived",
                value: "\(store.habits.filter { $0.isArchived }.count)",
                icon: "archivebox.circle.fill",
                color: .gray,
                animate: viewModel.animateStats
            )
            
            StatCard(
                title: "Total Done",
                value: "\(store.totalCompletions)",
                icon: "checkmark.circle.fill",
                color: .mint,
                animate: viewModel.animateStats
            )
        }
    }
    
    private var recentActivityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Last 14 Days Activity")
                .font(.headline)
            
            let data = store.completionsPerDay(last: 14)
            
            Chart(data, id: \.date) { item in
                BarMark(
                    x: .value("Date", item.date, unit: .day),
                    y: .value("Completions", viewModel.animateStats ? item.count : 0)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day())
                }
            }
            .frame(height: 150)
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: viewModel.animateStats)
            
            HStack {
                Label("\(data.reduce(0) { $0 + $1.count }) total", systemImage: "checkmark.circle")
                Spacer()
                Label("Avg \(String(format: "%.1f", Double(data.reduce(0) { $0 + $1.count }) / 14.0))/day", systemImage: "chart.bar")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(16)
    }
    
    private var categoryBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Habits by Category")
                .font(.headline)
            
            ForEach(store.categories.sorted(by: { store.habitsCount(for: $0) > store.habitsCount(for: $1) })) { category in
                CategoryProgressRow(
                    category: category,
                    count: store.habitsCount(for: category),
                    maxCount: store.categories.map { store.habitsCount(for: $0) }.max() ?? 1,
                    animate: viewModel.animateStats
                )
            }
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(16)
    }
    
    // MARK: - Achievements Tab
    private var achievementsTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Achievement summary
                achievementSummary
                
                // Achievements by tier
                ForEach(Achievement.Tier.allCases, id: \.self) { tier in
                    achievementTierSection(tier: tier)
                }
            }
            .padding(24)
        }
    }
    
    private var achievementSummary: some View {
        HStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("\(unlockedAchievementsCount)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text("Unlocked")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(height: 60)
            
            VStack(spacing: 8) {
                Text("\(Achievement.all.count - unlockedAchievementsCount)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                Text("Locked")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(height: 60)
            
            VStack(spacing: 8) {
                Text("\(Int(Double(unlockedAchievementsCount) / Double(Achievement.all.count) * 100))%")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text("Complete")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(16)
    }
    
    private func achievementTierSection(tier: Achievement.Tier) -> some View {
        let tierAchievements = Achievement.all.filter { $0.tier == tier }
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: tierIcon(for: tier))
                    .foregroundColor(tier.glowColor)
                Text("\(tier.name) Achievements")
                    .font(.headline)
                Spacer()
                Text("\(tierAchievements.filter { $0.requirement(store) }.count)/\(tierAchievements.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 16) {
                ForEach(tierAchievements) { achievement in
                    AchievementCard(
                        achievement: achievement,
                        isUnlocked: achievement.requirement(store),
                        progress: achievement.progress(store)
                    )
                }
            }
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(16)
    }
    
    private func tierIcon(for tier: Achievement.Tier) -> String {
        switch tier {
        case .bronze: return "medal"
        case .silver: return "medal.fill"
        case .gold: return "trophy"
        case .platinum: return "trophy.fill"
        case .diamond: return "crown.fill"
        }
    }
    
    // MARK: - Insights Tab
    private var insightsTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Weekly pattern
                weeklyPatternCard
                
                // Productivity insights
                productivityInsightsCard
                
                // Habit performance
                habitPerformanceCard
            }
            .padding(24)
        }
    }
    
    private var weeklyPatternCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Pattern")
                .font(.headline)
            
            HStack(spacing: 12) {
                ForEach(0..<7, id: \.self) { dayIndex in
                    let dayName = Calendar.current.shortWeekdaySymbols[dayIndex]
                    let completions = completionsForDayOfWeek(dayIndex)
                    let maxCompletions = (0..<7).map { completionsForDayOfWeek($0) }.max() ?? 1
                    let height = maxCompletions > 0 ? CGFloat(completions) / CGFloat(maxCompletions) * 100 : 0
                    
                    VStack(spacing: 8) {
                        Text("\(completions)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [dayColor(dayIndex), dayColor(dayIndex).opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 40, height: viewModel.animateStats ? max(height, 10) : 10)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(dayIndex) * 0.1), value: viewModel.animateStats)
                        
                        Text(dayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 150)
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(16)
    }
    
    private func dayColor(_ index: Int) -> Color {
        let colors: [Color] = [.red, .orange, .yellow, .green, .teal, .blue, .purple]
        return colors[index]
    }
    
    private func completionsForDayOfWeek(_ dayIndex: Int) -> Int {
        store.habits.reduce(0) { total, habit in
            total + habit.completedDates.filter {
                Calendar.current.component(.weekday, from: $0) == dayIndex + 1
            }.count
        }
    }
    
    private var productivityInsightsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Productivity Insights")
                .font(.headline)
            
            HStack(spacing: 20) {
                InsightCard(
                    title: "Most Productive Day",
                    value: mostProductiveDay,
                    icon: "calendar.badge.checkmark",
                    color: .green
                )
                
                InsightCard(
                    title: "Completion Rate",
                    value: "\(Int(overallCompletionRate * 100))%",
                    icon: "percent",
                    color: .blue
                )
                
                InsightCard(
                    title: "Habits on Track",
                    value: "\(habitsOnTrack)/\(store.habits.filter { !$0.isArchived }.count)",
                    icon: "checkmark.shield",
                    color: .teal
                )
            }
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(16)
    }
    
    private var habitPerformanceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Performing Habits")
                .font(.headline)
            
            let topHabits = store.habits
                .filter { !$0.isArchived }
                .sorted { $0.currentStreak > $1.currentStreak }
                .prefix(5)
            
            if topHabits.isEmpty {
                Text("Complete some habits to see your top performers!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(Array(topHabits.enumerated()), id: \.element.id) { index, habit in
                    HStack(spacing: 12) {
                        Text("#\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .frame(width: 30)
                        
                        ZStack {
                            Circle()
                                .fill(Color(hex: habit.colorHex).gradient)
                                .frame(width: 36, height: 36)
                            Image(systemName: habit.icon)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(habit.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("\(habit.currentStreak) day streak • \(habit.completedDates.count) total")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Performance indicator
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("\(habit.currentStreak)")
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                    .padding(.vertical, 8)
                    
                    if index < topHabits.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(16)
    }
    
    // MARK: - Settings Tab
    private var settingsTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile settings
                profileSettingsCard
                
                // App preferences
                appPreferencesCard
                
                // Data management
                dataManagementCard
                
                // About
                aboutCard
            }
            .padding(24)
        }
    }
    
    private var profileSettingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Profile")
                .font(.headline)
            
            HStack {
                Text("Display Name")
                Spacer()
                TextField("Your name", text: $viewModel.userName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
            }
            
            Divider()
            
            HStack {
                Text("Member Since")
                Spacer()
                Text(viewModel.joinDate, style: .date)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(16)
    }
    
    private var appPreferencesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preferences")
                .font(.headline)
            
            HStack {
                Label("Notifications", systemImage: "bell.badge")
                Spacer()
                Text("System Settings")
                    .foregroundColor(.secondary)
                Button(action: openNotificationSettings) {
                    Image(systemName: "arrow.up.forward.square")
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            HStack {
                Label("Keyboard Shortcuts", systemImage: "keyboard")
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ShortcutDisplay(keys: "⌘N", action: "New Habit")
                ShortcutDisplay(keys: "⌘,", action: "Settings")
                ShortcutDisplay(keys: "⇧⌘A", action: "Analytics")
                ShortcutDisplay(keys: "⌘F", action: "Search")
                ShortcutDisplay(keys: "⌘W", action: "Close Window")
                ShortcutDisplay(keys: "Esc", action: "Cancel")
            }
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(16)
    }
    
    private var dataManagementCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data Management")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Export Data")
                    Text("Download all your data as JSON")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Export") {
                    exportData()
                }
                .buttonStyle(.bordered)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reset All Data")
                        .foregroundColor(.red)
                    Text("Permanently delete all habits and progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Reset", role: .destructive) {
                    viewModel.showingResetAlert = true
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(16)
    }
    
    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Habit Tracker")
                        .font(.headline)
                    Text("Version 1.0.0 (Build 1)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            Text("Built with ❤️ using SwiftUI")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("© 2025 All rights reserved")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(16)
    }
    
    // MARK: - Computed Properties
    private var userLevel: Int {
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
    
    private var levelTitle: String {
        switch userLevel {
        case 1: return "Beginner"
        case 2: return "Novice"
        case 3: return "Apprentice"
        case 4: return "Regular"
        case 5: return "Dedicated"
        case 6: return "Expert"
        case 7: return "Master"
        case 8: return "Grandmaster"
        case 9: return "Legend"
        case 10: return "Habit God"
        default: return "Unknown"
        }
    }
    
    private var levelColor: Color {
        switch userLevel {
        case 1...2: return .gray
        case 3...4: return .green
        case 5...6: return .blue
        case 7...8: return .purple
        case 9...10: return .orange
        default: return .gray
        }
    }
    
    private var nextLevelRequirement: Int {
        switch userLevel {
        case 1: return 5
        case 2: return 15
        case 3: return 30
        case 4: return 50
        case 5: return 100
        case 6: return 200
        case 7: return 300
        case 8: return 500
        case 9: return 1000
        default: return store.totalCompletions
        }
    }
    
    private var levelProgress: Double {
        let current = store.totalCompletions
        let next = nextLevelRequirement
        let previous: Int
        switch userLevel {
        case 1: previous = 0
        case 2: previous = 5
        case 3: previous = 15
        case 4: previous = 30
        case 5: previous = 50
        case 6: previous = 100
        case 7: previous = 200
        case 8: previous = 300
        case 9: previous = 500
        default: previous = 1000
        }
        
        if userLevel == 10 { return 1.0 }
        return Double(current - previous) / Double(next - previous)
    }
    
    private var unlockedAchievementsCount: Int {
        Achievement.all.filter { $0.requirement(store) }.count
    }
    
    private var averagePerDay: Double {
        guard let firstDate = store.habits.flatMap({ $0.completedDates }).min() else { return 0 }
        let daysSinceStart = max(1, Calendar.current.dateComponents([.day], from: firstDate, to: Date()).day ?? 1)
        return Double(store.totalCompletions) / Double(daysSinceStart)
    }
    
    private var mostProductiveDay: String {
        var maxCompletions = 0
        var maxDay = 0
        for day in 0..<7 {
            let completions = completionsForDayOfWeek(day)
            if completions > maxCompletions {
                maxCompletions = completions
                maxDay = day
            }
        }
        return Calendar.current.weekdaySymbols[maxDay]
    }
    
    private var overallCompletionRate: Double {
        store.weeklyCompletionRate()
    }
    
    private var habitsOnTrack: Int {
        store.habits.filter { !$0.isArchived && $0.currentStreak > 0 }.count
    }
    
    // MARK: - Actions
    private func exportData() {
        guard let data = store.exportData() else { return }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "habit_tracker_export.json"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? data.write(to: url)
            }
        }
    }
    
    private func openNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Supporting Views

struct QuickStatView: View {
    let value: String
    let label: String
    let color: Color
    let animate: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
                .scaleEffect(animate ? 1 : 0.5)
                .opacity(animate ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animate)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let animate: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .scaleEffect(animate ? 1 : 0.5)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animate)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct CategoryProgressRow: View {
    let category: HabitCategory
    let count: Int
    let maxCount: Int
    let animate: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.title3)
                .foregroundColor(Color(hex: category.colorHex))
                .frame(width: 24)
            
            Text(category.name)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            GeometryReader { geometry in
                let barWidth = maxCount > 0 ? (CGFloat(count) / CGFloat(maxCount)) * geometry.size.width : 0
                
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: category.colorHex).opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: category.colorHex).gradient)
                        .frame(width: animate ? barWidth : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animate)
                }
            }
            .frame(width: 120, height: 8)
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let progress: Double
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? achievement.color.gradient : Color.gray.opacity(0.3).gradient)
                    .frame(width: 50, height: 50)
                
                if isUnlocked {
                    Circle()
                        .stroke(achievement.tier.glowColor.opacity(0.5), lineWidth: 2)
                        .frame(width: 56, height: 56)
                        .blur(radius: 2)
                }
                
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(isUnlocked ? .white : .gray)
            }
            .shadow(color: isUnlocked ? achievement.color.opacity(0.4) : .clear, radius: 8)
            
            VStack(spacing: 4) {
                Text(achievement.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                
                if !isUnlocked {
                    ProgressView(value: progress)
                        .tint(achievement.color)
                        .frame(width: 60)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .textBackgroundColor))
                .shadow(color: isHovered ? achievement.color.opacity(0.2) : .clear, radius: 8)
        )
        .opacity(isUnlocked ? 1 : 0.7)
        .scaleEffect(isHovered ? 1.02 : 1)
        .animation(.spring(response: 0.3), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .help(achievement.description)
    }
}

struct InsightCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(nsColor: .textBackgroundColor))
        .cornerRadius(12)
    }
}

struct ShortcutDisplay: View {
    let keys: String
    let action: String
    
    var body: some View {
        HStack {
            Text(keys)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(6)
            
            Text(action)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}
