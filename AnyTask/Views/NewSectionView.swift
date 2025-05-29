import SwiftUI

struct NewSectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sectionName: String
    @State private var selectedColor: String
    @State private var selectedIcon: String
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
        self._sectionName = State(initialValue: initialName)
        self._selectedColor = State(initialValue: initialColor)
        self._selectedIcon = State(initialValue: initialIconName)
        self.onCreate = onCreate
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name")) {
                    TextField("Enter section name", text: $sectionName)
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
                                        .stroke(selectedColor == colorName ? Color.primary : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    selectedColor = colorName
                                }
                        }
                    }
                    .padding()
                }
                Section(header: Text("Icon")) {
                    iconPicker
                }
            }
            .navigationTitle("New Section")
            .navigationBarItems(
                leading: Button("Cancel", action: { dismiss() }),
                trailing: Button("Done") {
                    onCreate(sectionName, selectedColor, selectedIcon)
                    dismiss()
                }
                .disabled(sectionName.isEmpty)
            )
            .scrollDismissesKeyboard(.immediately)
            .ignoresSafeArea(.keyboard)
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }

    private var iconPicker: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
            ForEach(availableIcons, id: \.self) { icon in
                Button(action: { selectedIcon = icon }) {
                    Image(systemName: icon)
                        .font(.title2)
                        .padding()
                        .background(selectedIcon == icon ? Color.fromName(selectedColor) : Color.clear)
                        .clipShape(Circle())
                        .foregroundColor(Color.primary)
                }
            }
        }
        .padding(.vertical)
    }
}
