# HabitTracker

A beautiful, colorful, and animated SwiftUI-based macOS Habit Tracker application. Track your daily habits, visualize your progress with charts, and stay motivated with an intuitive and playful interface.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS%2013.0+-lightgrey.svg)
![Swift](https://img.shields.io/badge/swift-5.9+-orange.svg)

## Features

### Analytics Dashboard
- **Progress Charts**: Visualize your habit completion history
- **Category Distribution**: See which categories you focus on most
- **Interactive Graphs**: Built with SwiftUI Charts framework
- **Real-time Statistics**: Track your success rates and streaks

### Habit Management
- **Create & Edit Habits**: Define custom habits with colors and categories
- **Flexible Frequency**: Daily, Weekly, Weekends, or Custom schedules
- **Quick Completion**: Toggle habit completion with animated feedback
- **Archive System**: Soft-delete habits without losing data
- **Restore Functionality**: Unarchive habits anytime

### Category System
- **Custom Categories**: Create personalized categories
- **Color Coding**: Visual organization with custom colors
- **Category Filtering**: View habits by category
- **Easy Management**: Add and remove categories on the fly

### Beautiful UI
- **Colorful Cards**: Each habit has its own vibrant color
- **Smooth Animations**: Engaging transitions and effects
- **Hover Effects**: Interactive feedback on user actions
- **Modern Design**: Clean SwiftUI interface
- **Sidebar Navigation**: Easy access to all features

## System Requirements

- macOS 13.0 (Ventura) or later
- Xcode 14.0 or later (for development)
- Swift 5.9+

## Installation

### Option 1: Run from Xcode

1. **Clone the repository**
   ```bash
   git clone https://github.com/ajaym-7/HabitTracker.git
   cd HabitTracker
   ```

2. **Open in Xcode**
   ```bash
   open Package.swift
   ```

3. **Build and Run**
   - Select "HabitTracker" scheme
   - Press `Cmd+R` or click the Run button

### Option 2: Build with Swift Package Manager

```bash
# Clone the repository
git clone https://github.com/ajaym-7/HabitTracker.git
cd HabitTracker

# Build the project
swift build

# Run the app
swift run
```

### Option 3: Use Pre-built App

If available, download the `.app` from releases and move it to your Applications folder.

## Usage

### Creating a Habit

1. Click the **"+"** button in the sidebar
2. Enter habit details:
   - **Title**: Name your habit
   - **Description**: Optional details
   - **Category**: Choose or create a category
   - **Color**: Pick a color for visual identification
   - **Frequency**: Select how often (Daily, Weekly, etc.)
3. Click **"Save"**

### Tracking Completion

- Click the **checkmark** on any habit card to mark as complete
- Click again to undo
- Animations provide instant feedback

### Viewing Analytics

- Navigate to **"Dashboard"** in the sidebar
- View completion history chart
- See category distribution
- Check success statistics

### Managing Categories

1. Go to **"Categories"** in the sidebar
2. Add new categories with custom names and colors
3. Delete unused categories (habits will be updated)

## Development

### Project Structure

```
HabitTracker/
├── Sources/HabitTracker/
│   ├── HabitTrackerApp.swift       # App entry point
│   ├── Models/
│   │   └── Habit.swift             # Data models
│   ├── ViewModels/
│   │   └── HabitStore.swift        # Business logic & persistence
│   ├── Views/
│   │   ├── ContentView.swift       # Main container
│   │   ├── HabitListView.swift     # Habits list
│   │   ├── HabitCardView.swift     # Individual habit card
│   │   ├── HabitDetailView.swift   # Create/Edit form
│   │   ├── HabitEditorView.swift   # Edit interface
│   │   ├── AnalyticsDashboardView.swift # Charts & stats
│   │   ├── CategoryManagerView.swift    # Category management
│   │   ├── SettingsView.swift      # App settings
│   │   └── ProfileView.swift       # User profile
│   └── Extensions/
│       └── Extensions.swift        # Color & Date utilities
├── Tests/
│   └── HabitTrackerTests/
│       └── HabitStoreCRUDTests.swift # Unit tests
├── Package.swift                   # Swift Package manifest
├── README.md
└── LICENSE

```

### Running Tests

```bash
# Run all tests
swift test

# Run with verbose output
swift test --verbose
```

**Test Coverage:**
- Create habits
- Read/filter habits
- Update habit properties
- Delete/archive habits
- Toggle completion status
- Full CRUD lifecycle

### Data Persistence

- **Storage**: JSON files in `Application Support/<bundle-id>/`
- **Format**: Human-readable JSON
- **Automatic**: Saves on every change
- **Location**: `~/Library/Application Support/com.yourname.HabitTracker/habits.json`

### Key Technologies

- **SwiftUI**: Modern declarative UI framework
- **Charts**: Native SwiftUI charting (macOS 13+)
- **Combine**: Reactive state management
- **Swift Package Manager**: Dependency & build management
- **JSON**: Simple file-based persistence

## Customization

### Adding New Frequencies

Edit `Habit.swift` and add to the `Frequency` enum:

```swift
enum Frequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case weekends = "Weekends"
    case custom = "Custom"
    // Add your custom frequency here
}
```

### Changing Default Colors

Modify the color palette in `Extensions.swift`:

```swift
static let habitColors: [Color] = [
    .blue, .green, .orange, .purple, .pink, .red, .yellow, .cyan
    // Add more colors
]
```

## Known Issues

- Charts require macOS 13.0+ (graceful degradation on older versions)
- App bundle identifier needs to be configured for distribution
- Persistence path is user-specific

## Contributing

Contributions are welcome! Here's how:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Write tests for new features
- Follow SwiftUI best practices
- Keep code readable and documented
- Ensure all tests pass before submitting

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with SwiftUI and love
- Charts powered by SwiftUI Charts framework
- Inspired by habit tracking best practices

## Support

For issues, questions, or feature requests:
- Open an [issue](https://github.com/ajaym-7/HabitTracker/issues)
- Submit a [pull request](https://github.com/ajaym-7/HabitTracker/pulls)

---


