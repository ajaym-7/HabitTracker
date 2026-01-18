import SwiftUI

struct CategoryManagerView: View {
    @EnvironmentObject var store: HabitStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var newCategoryName: String = ""
    @State private var newCategoryIcon: String = "folder.fill"
    @State private var newCategoryColor: String = "#5B8DEF"
    @State private var editingCategory: HabitCategory?
    @State private var showingDeleteAlert = false
    @State private var categoryToDelete: HabitCategory?
    
    let icons = [
        "folder.fill", "heart.fill", "star.fill", "bolt.fill", "flame.fill",
        "leaf.fill", "figure.run", "book.fill", "brain.head.profile", "dollarsign.circle.fill",
        "paintbrush.fill", "person.2.fill", "house.fill", "briefcase.fill", "gamecontroller.fill"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Manage Categories")
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
            HStack(spacing: 0) {
                // Categories List
                VStack(alignment: .leading, spacing: 0) {
                    Text("Categories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    List {
                        ForEach(store.categories) { category in
                            CategoryListRow(
                                category: category,
                                isSelected: editingCategory?.id == category.id,
                                onSelect: { editingCategory = category },
                                onDelete: {
                                    categoryToDelete = category
                                    showingDeleteAlert = true
                                }
                            )
                        }
                    }
                    .listStyle(.inset)
                }
                .frame(width: 250)
                
                Divider()
                
                // Editor Panel
                VStack(spacing: 20) {
                    if let category = editingCategory {
                        CategoryEditorPanel(
                            category: category,
                            icons: icons,
                            onSave: { updated in
                                store.updateCategory(updated)
                                editingCategory = updated
                            }
                        )
                    } else {
                        // New Category Form
                        NewCategoryPanel(
                            name: $newCategoryName,
                            icon: $newCategoryIcon,
                            color: $newCategoryColor,
                            icons: icons,
                            onCreate: createCategory
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .frame(width: 600, height: 450)
        .alert("Delete Category", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let category = categoryToDelete {
                    store.deleteCategory(category)
                    if editingCategory?.id == category.id {
                        editingCategory = nil
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this category? Habits in this category will be moved to another category.")
        }
    }
    
    private func createCategory() {
        guard !newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let category = HabitCategory(
            name: newCategoryName.trimmingCharacters(in: .whitespaces),
            icon: newCategoryIcon,
            colorHex: newCategoryColor
        )
        
        store.addCategory(category)
        newCategoryName = ""
        newCategoryIcon = "folder.fill"
        newCategoryColor = "#5B8DEF"
    }
}

// MARK: - Category List Row
struct CategoryListRow: View {
    let category: HabitCategory
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: category.colorHex).gradient)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: category.icon)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                )
            
            Text(category.name)
                .fontWeight(isSelected ? .semibold : .regular)
            
            Spacer()
            
            if isHovered {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Category Editor Panel
struct CategoryEditorPanel: View {
    @State var category: HabitCategory
    let icons: [String]
    let onSave: (HabitCategory) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Edit Category")
                .font(.headline)
            
            // Preview
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: category.colorHex).gradient)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: category.icon)
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    )
                    .shadow(color: Color(hex: category.colorHex).opacity(0.4), radius: 8)
                
                Text(category.name)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)
            
            // Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Category name", text: $category.name)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Icon
            VStack(alignment: .leading, spacing: 8) {
                Text("Icon")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(36), spacing: 8), count: 5), spacing: 8) {
                    ForEach(icons, id: \.self) { icon in
                        Button(action: { category.icon = icon }) {
                            Image(systemName: icon)
                                .font(.system(size: 16))
                                .frame(width: 36, height: 36)
                                .foregroundColor(category.icon == icon ? .white : .primary)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(category.icon == icon ? Color(hex: category.colorHex) : Color.gray.opacity(0.1))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Color
            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(28), spacing: 8), count: 8), spacing: 8) {
                    ForEach(Color.habitColors, id: \.self) { colorHex in
                        Button(action: { category.colorHex = colorHex }) {
                            Circle()
                                .fill(Color(hex: colorHex))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: category.colorHex == colorHex ? 3 : 0)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Spacer()
            
            Button("Save Changes") {
                onSave(category)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - New Category Panel
struct NewCategoryPanel: View {
    @Binding var name: String
    @Binding var icon: String
    @Binding var color: String
    let icons: [String]
    let onCreate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("New Category")
                .font(.headline)
            
            // Preview
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: color).gradient)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    )
                    .shadow(color: Color(hex: color).opacity(0.4), radius: 8)
                
                Text(name.isEmpty ? "Category Name" : name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(name.isEmpty ? .secondary : .primary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)
            
            // Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Category name", text: $name)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Icon
            VStack(alignment: .leading, spacing: 8) {
                Text("Icon")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(36), spacing: 8), count: 5), spacing: 8) {
                    ForEach(icons, id: \.self) { iconName in
                        Button(action: { icon = iconName }) {
                            Image(systemName: iconName)
                                .font(.system(size: 16))
                                .frame(width: 36, height: 36)
                                .foregroundColor(icon == iconName ? .white : .primary)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(icon == iconName ? Color(hex: color) : Color.gray.opacity(0.1))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Color
            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(28), spacing: 8), count: 8), spacing: 8) {
                    ForEach(Color.habitColors, id: \.self) { colorHex in
                        Button(action: { color = colorHex }) {
                            Circle()
                                .fill(Color(hex: colorHex))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: color == colorHex ? 3 : 0)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Spacer()
            
            Button("Create Category") {
                onCreate()
            }
            .buttonStyle(.borderedProminent)
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
}
