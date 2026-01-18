import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: HabitStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingResetAlert = false
    @State private var showingExportPanel = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Done") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // App Info
                    GroupBox {
                        HStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Habit Tracker")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Version 1.0.0")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Build better habits, one day at a time.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    } label: {
                        Label("About", systemImage: "info.circle")
                    }
                    
                    // Statistics
                    GroupBox {
                        VStack(spacing: 16) {
                            StatRow(label: "Total Habits", value: "\(store.habits.count)")
                            StatRow(label: "Active Habits", value: "\(store.habits.filter { !$0.isArchived }.count)")
                            StatRow(label: "Archived Habits", value: "\(store.habits.filter { $0.isArchived }.count)")
                            StatRow(label: "Categories", value: "\(store.categories.count)")
                            StatRow(label: "Total Completions", value: "\(store.totalCompletions)")
                            StatRow(label: "Best Current Streak", value: "\(store.bestCurrentStreak) days")
                        }
                    } label: {
                        Label("Statistics", systemImage: "chart.bar")
                    }
                    
                    // Data Management
                    GroupBox {
                        VStack(spacing: 12) {
                            Button(action: { showingExportPanel = true }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Export Data")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                            
                            Divider()
                            
                            Button(action: { showingResetAlert = true }) {
                                HStack {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                    Text("Reset All Data")
                                        .foregroundColor(.red)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    } label: {
                        Label("Data Management", systemImage: "externaldrive")
                    }
                    
                    // Keyboard Shortcuts
                    GroupBox {
                        VStack(spacing: 12) {
                            ShortcutRow(keys: "⌘N", description: "Create new habit")
                            ShortcutRow(keys: "⌘,", description: "Open settings")
                            ShortcutRow(keys: "⌘W", description: "Close window")
                        }
                    } label: {
                        Label("Keyboard Shortcuts", systemImage: "keyboard")
                    }
                    
                    // Credits
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Made with ❤️ using SwiftUI")
                                .font(.subheadline)
                            Text("Icons by SF Symbols")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Charts powered by Swift Charts")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } label: {
                        Label("Credits", systemImage: "heart")
                    }
                }
                .padding()
            }
        }
        .frame(width: 450, height: 600)
        .alert("Reset All Data", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                store.resetAllData()
            }
        } message: {
            Text("This will permanently delete all your habits, categories, and completion history. This action cannot be undone.")
        }
    }
}

// MARK: - Helper Views
struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct ShortcutRow: View {
    let keys: String
    let description: String
    
    var body: some View {
        HStack {
            Text(keys)
                .font(.system(.caption, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
            
            Text(description)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}
