//
//  NewSectionView.swift
//  AnyTask
//
//  Created by Kyle Hosman on 1/10/25.
//

import SwiftUI

struct NewSectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sectionName: String
    @State private var selectedColor: String
    @FocusState private var isTextFieldFocused: Bool // Track focus state
    let onCreate: (String, String) -> Void

    let colors: [String: Color] = [
        ".blue": .blue,
        ".red": .red,
        ".green": .green,
        ".yellow": .yellow,
        ".purple": .purple
    ]

    init(initialName: String = "", initialColor: String = ".blue", onCreate: @escaping (String, String) -> Void) {
        self._sectionName = State(initialValue: initialName)
        self._selectedColor = State(initialValue: initialColor)
        self.onCreate = onCreate
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Styled TextField for Section Name
                TextField("Enter section name", text: $sectionName)
                    .padding()
                    .background(Color(.systemGray6)) // Light gray background
                    .cornerRadius(16) // Rounded corners
                    .font(.system(size: 18)) // Slightly larger font
                    .focused($isTextFieldFocused) // Automatically focus
                    .padding(.horizontal)

                // Color Picker
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

                // Save Button
                Button("Done") {
                    onCreate(sectionName, selectedColor)
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
                isTextFieldFocused = true // Automatically focus the text field
            }
        }
    }
}
