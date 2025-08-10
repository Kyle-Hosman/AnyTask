import SwiftUI

class NewSectionViewModel: ObservableObject {
    @Published var sectionName: String
    @Published var selectedColor: String
    @Published var selectedIcon: String
    
    init(sectionName: String = "", selectedColor: String = ".blue", selectedIcon: String = "folder") {
        self.sectionName = sectionName
        self.selectedColor = selectedColor
        self.selectedIcon = selectedIcon
    }
}

struct NewSectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: NewSectionViewModel
    @FocusState private var isTextFieldFocused: Bool

    let availableIcons = [
        "folder", "star", "list.bullet", "checkmark.seal", "cart", "book", "heart", "flag", "bell", "calendar", "bolt", "gift", "leaf", "pencil", "person", "questionmark"
    ]

    let onCreate: (String, String, String) -> Void

    // Use the color names from Extensions.swift
    let colorNames: [String] = [
        ".blue", ".red", ".green", ".yellow", ".purple"
    ]

    init(initialName: String = "", initialColor: String = ".blue", initialIconName: String = "folder", onCreate: @escaping (String, String, String) -> Void) {
        _viewModel = StateObject(wrappedValue: NewSectionViewModel(sectionName: initialName, selectedColor: initialColor, selectedIcon: initialIconName))
        self.onCreate = onCreate
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name")) {
                    TextField("Enter section name", text: $viewModel.sectionName)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .font(.system(size: 18))
                        .focused($isTextFieldFocused)
                        .padding(.horizontal)
                }
                Section(header: Text("Color")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 20) {
                        ForEach(colorNames, id: \.self) { colorName in
                            Circle()
                                .fill(Color.fromName(colorName))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(viewModel.selectedColor == colorName ? Color.primary : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    viewModel.selectedColor = colorName
                                }
                        }
                    }
                    .padding()
                }
                Section(header: Text("Icon")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .padding()
                                .background(viewModel.selectedIcon == icon ? Color.fromName(viewModel.selectedColor) : Color.clear)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(viewModel.selectedIcon == icon ? Color.primary : Color.clear, lineWidth: 2)
                                )
                                .foregroundColor(viewModel.selectedIcon == icon ? .black : .primary)
                                .onTapGesture {
                                    viewModel.selectedIcon = icon
                                }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("New Section")
            .navigationBarItems(
                leading: Button("Cancel", action: { dismiss() }),
                trailing: Button("Done") {
                    onCreate(viewModel.sectionName, viewModel.selectedColor, viewModel.selectedIcon)
                    dismiss()
                }
                .disabled(viewModel.sectionName.isEmpty)
            )
            .scrollDismissesKeyboard(.immediately)
            .ignoresSafeArea(.keyboard)
            .onAppear {
                isTextFieldFocused = true
                // Ensure selectedIcon is valid
                if !availableIcons.contains(viewModel.selectedIcon) {
                    viewModel.selectedIcon = availableIcons.first ?? "folder"
                }
            }
        }
    }
}
