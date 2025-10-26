import SwiftUI

struct TextEntrySheet: View {
    @Binding var text: String
    @Environment(\.dismiss) var dismiss
    @FocusState private var isTextEditorFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background matching scrapbook theme
                Color(red: 0.95, green: 0.94, blue: 0.92)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Text editor card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Note")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        
                        TextEditor(text: $text)
                            .focused($isTextEditorFocused)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .background(Color(uiColor: .systemBackground))
                            .frame(minHeight: 200)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(uiColor: .separator), lineWidth: 0.5)
                            )
                            .padding(.horizontal, 16)
                        
                        // Character count
                        HStack {
                            Spacer()
                            Text("\(text.count) characters")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        dismiss()
                    }
                    .bold()
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        text = ""
                        dismiss()
                    }
                }
            }
            .toolbarBackground(Color(red: 0.95, green: 0.94, blue: 0.92), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                // Auto-focus keyboard when sheet appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextEditorFocused = true
                }
            }
        }
    }
}
