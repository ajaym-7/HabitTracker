import SwiftUI
import Charts

struct AnalyticsDashboardView: View {
    @EnvironmentObject var store: HabitStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Analytics Dashboard")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Done") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Summary Cards
                    summaryCardsSection
                    
                    // Charts Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        // Completion History
                        completionHistoryChart
                        
                        // Category Distribution
                        categoryPieChart
                        
                        // Streak Leaderboard
                        streakLeaderboard
                        
                        // Heat Map
                        heatMapView
                    }
                }
                .padding()
            }
        }
        .frame(width: 900, height: 700)
    }
    
    // MARK: - Summary Cards
    var summaryCardsSection: some View {
        HStack(spacing: 16) {
            SummaryStatCard(
                title: "Total Habits",
                value: "\(store.habits.filter { !$0.isArchived }.count)",
                subtitle: "\(store.habits.filter { $0.isArchived }.count) archived",
                icon: "list.bullet.rectangle.fill",
                color: .blue
            )
            
            SummaryStatCard(
                title: "Best Streak",
                value: "\(store.bestCurrentStreak)",
                subtitle: "days in a row",
                icon: "flame.fill",
                color: .orange
            )
            
            SummaryStatCard(
                title: "This Week",
                value: "\(Int(store.weeklyCompletionRate() * 100))%",
                subtitle: "completion rate",
                icon: "chart.line.uptrend.xyaxis",
                color: .green
            )
            
            SummaryStatCard(
                title: "Total Completions",
                value: "\(store.totalCompletions)",
                subtitle: "all time",
                icon: "checkmark.seal.fill",
                color: .purple
            )
        }
    }
    
    // MARK: - Completion History Chart
    var completionHistoryChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completion History")
                .font(.headline)
            
            Text("Last 14 days")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if #available(macOS 13.0, *) {
                Chart(store.completionsPerDay(last: 14), id: \.date) { item in
                    BarMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Completions", item.count)
                    )
                    .foregroundStyle(Color.accentColor.gradient)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 2)) { value in
                        if value.as(Date.self) != nil {
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        }
                    }
                }
                .frame(height: 200)
            } else {
                Text("Charts require macOS 13.0+")
                    .foregroundColor(.secondary)
            }
        }
        .cardStyle()
    }
    
    // MARK: - Category Pie Chart
    var categoryPieChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Habits by Category")
                .font(.headline)
            
            Text("Distribution")
                .font(.caption)
                .foregroundColor(.secondary)
            
            let distribution = store.categoryDistribution()
            
            if distribution.isEmpty {
                Text("No data")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            } else {
                // Custom pie chart for macOS 13 compatibility
                CustomPieChartView(distribution: distribution)
                    .frame(height: 160)
                
                // Legend
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(distribution, id: \.category.id) { item in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: item.category.colorHex))
                                .frame(width: 10, height: 10)
                            Text(item.category.name)
                                .font(.caption)
                            Spacer()
                            Text("\(item.count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Streak Leaderboard
    var streakLeaderboard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🔥 Streak Leaderboard")
                .font(.headline)
            
            Text("Top performing habits")
                .font(.caption)
                .foregroundColor(.secondary)
            
            let topHabits = store.topStreakHabits(limit: 5)
            
            if topHabits.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "flame")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No streaks yet")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(topHabits.enumerated()), id: \.element.id) { index, habit in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            
                            Circle()
                                .fill(Color(hex: habit.colorHex).gradient)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Image(systemName: habit.icon)
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                )
                            
                            Text(habit.title)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                Text("\(habit.currentStreak)")
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Heat Map
    var heatMapView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Heat Map")
                .font(.headline)
            
            Text("Last 12 weeks")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ContributionGridView()
        }
        .cardStyle()
    }
}

// MARK: - Summary Stat Card
struct SummaryStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(16)
        .shadow(color: color.opacity(isHovered ? 0.3 : 0.1), radius: isHovered ? 12 : 4)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Contribution Grid (GitHub-style)
struct ContributionGridView: View {
    @EnvironmentObject var store: HabitStore
    
    let weeks = 12
    let days = 7
    
    var contributionData: [[Int]] {
        let calendar = Calendar.current
        var data: [[Int]] = []
        
        for week in 0..<weeks {
            var weekData: [Int] = []
            for day in 0..<days {
                let daysAgo = (weeks - 1 - week) * 7 + (days - 1 - day)
                guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else {
                    weekData.append(0)
                    continue
                }
                
                let count = store.habits.reduce(0) { sum, habit in
                    sum + (habit.isCompleted(on: date) ? 1 : 0)
                }
                weekData.append(count)
            }
            data.append(weekData)
        }
        
        return data
    }
    
    func colorForCount(_ count: Int) -> Color {
        switch count {
        case 0: return Color.gray.opacity(0.15)
        case 1: return Color.green.opacity(0.3)
        case 2: return Color.green.opacity(0.5)
        case 3: return Color.green.opacity(0.7)
        default: return Color.green
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Day labels
            HStack(spacing: 4) {
                Text("")
                    .frame(width: 20)
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .frame(width: 12)
                }
            }
            
            // Grid
            HStack(alignment: .top, spacing: 4) {
                ForEach(0..<weeks, id: \.self) { week in
                    VStack(spacing: 4) {
                        ForEach(0..<days, id: \.self) { day in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(colorForCount(contributionData[week][day]))
                                .frame(width: 12, height: 12)
                        }
                    }
                }
            }
            
            // Legend
            HStack(spacing: 4) {
                Text("Less")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                ForEach([0, 1, 2, 3, 4], id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorForCount(level))
                        .frame(width: 12, height: 12)
                }
                
                Text("More")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Custom Pie Chart (macOS 13 compatible)
struct CustomPieChartView: View {
    let distribution: [(category: HabitCategory, count: Int)]
    
    var body: some View {
        GeometryReader { geometry in
            let total = distribution.reduce(0) { $0 + $1.count }
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = size / 2 * 0.9
            let innerRadius = radius * 0.5
            
            ZStack {
                ForEach(Array(sliceData(total: total).enumerated()), id: \.offset) { index, slice in
                    PieSliceShape(
                        startAngle: slice.startAngle,
                        endAngle: slice.endAngle,
                        innerRadius: innerRadius,
                        outerRadius: radius
                    )
                    .fill(Color(hex: distribution[index].category.colorHex))
                }
            }
            .frame(width: size, height: size)
            .position(center)
        }
    }
    
    private func sliceData(total: Int) -> [(startAngle: Angle, endAngle: Angle)] {
        var slices: [(startAngle: Angle, endAngle: Angle)] = []
        var currentAngle = Angle.degrees(-90)
        
        for item in distribution {
            let proportion = Double(item.count) / Double(total)
            let sliceAngle = Angle.degrees(proportion * 360)
            slices.append((startAngle: currentAngle, endAngle: currentAngle + sliceAngle))
            currentAngle = currentAngle + sliceAngle
        }
        
        return slices
    }
}

struct PieSliceShape: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        // Start at inner radius
        let innerStart = CGPoint(
            x: center.x + innerRadius * CGFloat(cos(startAngle.radians)),
            y: center.y + innerRadius * CGFloat(sin(startAngle.radians))
        )
        
        path.move(to: innerStart)
        
        // Line to outer radius at start angle
        let outerStart = CGPoint(
            x: center.x + outerRadius * CGFloat(cos(startAngle.radians)),
            y: center.y + outerRadius * CGFloat(sin(startAngle.radians))
        )
        path.addLine(to: outerStart)
        
        // Arc along outer radius
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        
        // Line to inner radius at end angle
        let innerEnd = CGPoint(
            x: center.x + innerRadius * CGFloat(cos(endAngle.radians)),
            y: center.y + innerRadius * CGFloat(sin(endAngle.radians))
        )
        path.addLine(to: innerEnd)
        
        // Arc back along inner radius
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: endAngle,
            endAngle: startAngle,
            clockwise: true
        )
        
        path.closeSubpath()
        return path
    }
}