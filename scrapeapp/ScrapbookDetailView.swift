import SwiftUI
import CoreData
import UIKit

struct ScrapbookDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    
    let scrapbook: Scrapbook
    @State private var navigateToCanvas = false
    @State private var navigateToStorie = false
    @State private var showingCoverSelection = false
    @State private var isEditingTitle = false
    @State private var editedTitle: String
    @State private var coverImage: UIImage?
    
    init(scrapbook: Scrapbook) {
        self.scrapbook = scrapbook
        self._editedTitle = State(initialValue: scrapbook.title ?? "")
        if let imageData = scrapbook.coverImageData {
            self._coverImage = State(initialValue: UIImage(data: imageData))
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Button {
                        saveChanges()
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button {} label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                if isEditingTitle {
                    TextField("Scrapbook Title", text: $editedTitle)
                        .font(.system(size: 28, weight: .bold))
                        .tracking(2)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                        .onSubmit {
                            isEditingTitle = false
                            saveChanges()
                        }
                } else {
                    Button {
                        isEditingTitle = true
                    } label: {
                        Text(editedTitle.uppercased())
                            .font(.system(size: 28, weight: .bold))
                            .tracking(2)
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
                
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
                            .shadow(color: .black.opacity(0.25), radius: 21.5, x: 0, y: 26)
                    } else {
                        Rectangle()
                            .fill(Color(red: 0.6, green: 0.74, blue: 0.87))
                            .frame(width: 220, height: 320)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black, lineWidth: 1)
                            )
                    }
                    
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
                
                if let date = scrapbook.creationDate {
                    Text("Created on \(date, formatter: dateFormatter)")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                        .padding(.top, 24)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button {
                        saveChanges()
                        navigateToStorie = true
                    } label: {
                        Label("View", systemImage: "eye")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    HStack(spacing: 12) {
                        Button {
                            deleteScrapbook()
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                        }
                        
                        Button {
                            saveChanges()
                            navigateToCanvas = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                
                // Invisible NavigationLink to trigger push to canvas
                NavigationLink(isActive: $navigateToCanvas) {
                    ScrapbookContentView(scrapbook: scrapbook)
                        .environment(\.managedObjectContext, viewContext)
                } label: {
                    EmptyView()
                }
                .hidden()
                NavigationLink(isActive: $navigateToStorie) {
                    FullScreenScrapbookView(scrapbook: scrapbook)
                        .environment(\.managedObjectContext, viewContext)
                } label: {
                    EmptyView()
                }
                .hidden()
                
            }
            .background(Color(red: 0.95, green: 0.94, blue: 0.92))
            .navigationBarHidden(true)
            .sheet(isPresented: $showingCoverSelection) {
                CoverSelectionView(selectedImage: $coverImage)
                    .environment(\.managedObjectContext, viewContext)
                    .onDisappear { saveChanges() }
            }
        }
    }
    
    private func saveChanges() {
        scrapbook.title = editedTitle
        if let image = coverImage {
            scrapbook.coverImageData = image.jpegData(compressionQuality: 0.8)
        }
        do { try viewContext.save() } catch {
            print("Error saving scrapbook changes: \(error.localizedDescription)")
        }
    }
    
    private func deleteScrapbook() {
        viewContext.delete(scrapbook)
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error deleting scrapbook: \(error.localizedDescription)")
        }
    }
    
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy"
        return f
    }
}

