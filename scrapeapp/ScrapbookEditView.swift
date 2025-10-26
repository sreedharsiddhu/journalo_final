import SwiftUI
import CoreData
import UIKit

struct ScrapbookEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss

    var isNewScrapbook: Bool
    var onSave: ((Scrapbook) -> Void)?    // ✅ Callback to parent

    @State private var scrapbookToEdit: Scrapbook?
    @State private var scrapbookTitle: String
    @State private var coverImage: UIImage?
    @State private var showingCoverSelection = false
    @State private var selectedPageStyle: String

    let availableStyles = ["Plain", "Lined", "Grid", "Dotted"]

    init(isNewScrapbook: Bool, scrapbookToEdit: Scrapbook? = nil, onSave: ((Scrapbook) -> Void)? = nil) {
        self.isNewScrapbook = isNewScrapbook
        self._scrapbookToEdit = State(initialValue: scrapbookToEdit)
        self.onSave = onSave
        
        if let existingScrapbook = scrapbookToEdit {
            self._scrapbookTitle = State(initialValue: existingScrapbook.title ?? "")
            self._selectedPageStyle = State(initialValue: existingScrapbook.pageStyle ?? "Plain")
            if let imageData = existingScrapbook.coverImageData {
                self._coverImage = State(initialValue: UIImage(data: imageData))
            }
        } else {
            self._scrapbookTitle = State(initialValue: "")
            self._selectedPageStyle = State(initialValue: "Plain")
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Cover section
                ZStack(alignment: .topTrailing) {
                    if let image = coverImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 220, height: 320)
                            .clipped()
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black, lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    } else {
                        Rectangle()
                            .fill(Color(red: 0.6, green: 0.74, blue: 0.87))
                            .frame(width: 220, height: 320)
                            .cornerRadius(12)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white.opacity(0.8))
                                    Text("Add a Cover")
                                        .foregroundColor(.white.opacity(0.8))
                                        .font(.subheadline)
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black, lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.25), radius: 21.5, x: 0, y: 26)
                    }

                    // Edit cover icon
                    Button {
                        showingCoverSelection = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 44, height: 44)
                                .shadow(radius: 2)
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                                .font(.system(size: 25, weight: .bold))
                        }
                        .padding(10)
                    }
                }
                .padding(.top, 20)
                
                // Scrapbook Info Card
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Scrapbook Title")
                            .font(.headline)
                        TextField("e.g. Summer in Rome", text: $scrapbookTitle)
                            .padding(12)
                            .background(Color(uiColor: .systemGray6))
                            .cornerRadius(10)
                    }

                    // Paper selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Paper Type")
                            .font(.headline)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(availableStyles, id: \.self) { style in
                                    VStack(spacing: 6) {
                                        PaperPreview(style: style)
                                            .frame(width: 65, height: 100)
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(selectedPageStyle == style ? Color.blue : Color.clear, lineWidth: 2)
                                            )
                                            .shadow(radius: 2)
                                        Text(style)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedPageStyle = style
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 2)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .background(Color(red: 0.95, green: 0.94, blue: 0.92).ignoresSafeArea())
        .navigationTitle(scrapbookTitle.isEmpty ? (isNewScrapbook ? "New Scrapbook" : "Edit Scrapbook") : scrapbookTitle.uppercased())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button { saveScrapbook() } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
                // Allow saving even if empty; we'll provide defaults in saveScrapbook()
            }
        }
        .sheet(isPresented: $showingCoverSelection) {
            CoverSelectionView(selectedImage: $coverImage)
                .environment(\.managedObjectContext, viewContext)
        }
    }

    private func saveScrapbook() {
        let scrapbook: Scrapbook
        
        if let existing = scrapbookToEdit {
            scrapbook = existing
        } else {
            scrapbook = Scrapbook(context: viewContext)
            scrapbook.creationDate = Date()
            scrapbook.scrapbookID = UUID()
        }

        // Default title if empty
        let finalTitle = scrapbookTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled" : scrapbookTitle
        scrapbook.title = finalTitle

        scrapbook.pageStyle = selectedPageStyle
        
        // Default cover if none selected
        if let image = coverImage {
            scrapbook.coverImageData = image.jpegData(compressionQuality: 0.8)
        } else if let defaultCover = UIImage(named: "cover0") {
            scrapbook.coverImageData = defaultCover.jpegData(compressionQuality: 0.8)
            // Also set local state so the UI shows it immediately if needed
            coverImage = defaultCover
        } else {
            // If asset missing, generate a simple placeholder image
            let placeholder = generatePlaceholderCover(title: finalTitle)
            scrapbook.coverImageData = placeholder.jpegData(compressionQuality: 0.8)
            coverImage = placeholder
        }

        do {
            try viewContext.save()
            scrapbookToEdit = scrapbook
            onSave?(scrapbook)   // ✅ Callback to parent
            dismiss()            // ✅ Close sheet
        } catch {
            print("Error saving scrapbook setup: \(error.localizedDescription)")
        }
    }

    // Simple programmatic placeholder if no asset is available
    private func generatePlaceholderCover(title: String) -> UIImage {
        let size = CGSize(width: 440, height: 640) // 2x display of 220x320
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            // Background
            UIColor(red: 0.6, green: 0.74, blue: 0.87, alpha: 1.0).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            // Title
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 40, weight: .semibold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9),
                .paragraphStyle: paragraph
            ]
            let text = NSString(string: title)
            let textRect = CGRect(x: 20, y: size.height/2 - 30, width: size.width - 40, height: 60)
            text.draw(in: textRect, withAttributes: attrs)
        }
    }
}

// MARK: - Paper Preview Mini Views
struct PaperPreview: View {
    var style: String

    var body: some View {
        ZStack {
            Color.white
            switch style {
            case "Lined":
                VStack(spacing: 10) {
                    ForEach(0..<10, id: \.self) { _ in
                        Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                    }
                }
            case "Grid":
                VStack(spacing: 10) {
                    ForEach(0..<10, id: \.self) { _ in
                        HStack(spacing: 10) {
                            ForEach(0..<6, id: \.self) { _ in
                                Rectangle().fill(Color.gray.opacity(0.3)).frame(width: 1, height: 10)
                            }
                        }
                        Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                    }
                }
            case "Dotted":
                VStack(spacing: 8) {
                    ForEach(0..<10, id: \.self) { _ in
                        HStack(spacing: 8) {
                            ForEach(0..<6, id: \.self) { _ in
                                Circle().fill(Color.gray.opacity(0.4)).frame(width: 3, height: 3)
                            }
                        }
                    }
                }
            default:
                EmptyView()
            }
        }
        .cornerRadius(10)
    }
}

#Preview {
    NavigationStack {
        ScrapbookEditView(isNewScrapbook: true)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
