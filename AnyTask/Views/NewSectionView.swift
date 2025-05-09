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

    let colors: [String: Color] = [
        ".blue": .blue,
        ".red": .red,
        ".green": .green,
        ".yellow": .yellow,
        ".purple": .purple
    ]

    init(initialName: String = "", initialColor: String = ".blue", initialIconName: String = "folder", onCreate: @escaping (String, String, String) -> Void) {
        self._sectionName = State(initialValue: initialName)
        self._selectedColor = State(initialValue: initialColor)
        self._selectedIcon = State(initialValue: initialIconName)
        self.onCreate = onCreate
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Enter section name", text: $sectionName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .font(.system(size: 18))
                    .focused($isTextFieldFocused)
                    .padding(.horizontal)

                Text("Pick a Color")
                    .font(.headline)
                    .padding(.top)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 20) {
                    ForEach(colors.keys.sorted(), id: \.self) { colorName in
                        Circle()
                            .fill(colors[colorName] ?? .gray)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Circle()
                                    .stroke(selectedColor == colorName ? Color.black : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                selectedColor = colorName
                            }
                    }
                }
                .padding()

                Text("Pick an Icon")
                    .font(.headline)
                    .padding(.top)
                iconPicker

                Button("Done") {
                    onCreate(sectionName, selectedColor, selectedIcon)
                    dismiss()
                }
                .disabled(sectionName.isEmpty)
                .buttonStyle(.borderedProminent)
                .padding()

                Spacer()
            }
            .navigationTitle("New Section")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
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
                        .background(selectedIcon == icon ? (colors[selectedColor] ?? .gray).opacity(1.0) : Color.clear)
                        .clipShape(Circle())
                        .foregroundColor(.black)
                }
            }
        }
        .padding(.vertical)
    }
}
