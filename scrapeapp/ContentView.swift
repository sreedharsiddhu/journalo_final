import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Scrapbook.creationDate, ascending: false)],
        animation: .default
    )
    private var scrapbooks: FetchedResults<Scrapbook>
    
    @State private var showingCreateSheet = false
    @State private var searchText = ""
    @State private var selectedScrapbook: Scrapbook?
    @State private var showingDetailSheet = false
    @State private var navigateToCanvas = false
    @State private var scrapbookToNavigate: Scrapbook?
    @State private var navigateToDetail = false
    
    // Fixed 2-column grid to match the design
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    // Filtered scrapbooks based on search
    private var filteredScrapbooks: [Scrapbook] {
        if searchText.isEmpty {
            return Array(scrapbooks)
        } else {
            return scrapbooks.filter { scrapbook in
                (scrapbook.title ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Large title header
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 88)
                    .frame(maxWidth: .infinity)

                    .padding(.bottom, 16)

                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search scrapbooks", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.white))
                .cornerRadius(10)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(filteredScrapbooks, id: \.self) { scrapbook in
                            Button {
                                selectedScrapbook = scrapbook
                                // Instead of showing a sheet, push to detail
                                navigateToDetail = true
                            } label: {
                                VStack(spacing: 8) {
                                    ScrapbookCoverView(scrapbook: scrapbook)
                                        .contentShape(Rectangle())
                                    
                                    // Title below the card
                                    Text(scrapbook.title?.uppercased() ?? "UNTITLED")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(scrapbook.title ?? "Untitled Scrapbook")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100) // Space for bottom button
                    
                    if filteredScrapbooks.isEmpty && !searchText.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("No Results")
                                .font(.headline)
                            Text("Try a different search term")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 60)
                    } else if scrapbooks.isEmpty {
                        ContentPlaceholderView(createAction: { showingCreateSheet = true })
                            .padding(.horizontal, 24)
                            .padding(.vertical, 24)
                    }
                }
                
                Spacer()
                
                // Bottom button
                if !scrapbooks.isEmpty {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Text("CREATE SCRAPBOOK")
                            .font(.system(size: 16, weight: .semibold))
                            .tracking(1)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(red: 0.84, green: 0.83, blue: 0.8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.primary, lineWidth: 1)
                                    )
                            )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 10)
                    .background(Color(red: 0.93, green: 0.92, blue: 0.89))
                }
            }
            .background(Color(red: 0.93, green: 0.92, blue: 0.89))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingCreateSheet) {
                // Wrap in NavigationStack so ScrapbookEditView's toolbar (xmark/checkmark) is visible
                NavigationStack {
                    ScrapbookEditView(isNewScrapbook: true) { newScrapbook in
                        // Navigate to canvas after creating
                        scrapbookToNavigate = newScrapbook
                        navigateToCanvas = true
                    }
                    .environment(\.managedObjectContext, viewContext)
                }
            }
            // Push to ScrapbookDetailView
            .navigationDestination(isPresented: $navigateToDetail) {
                if let scrapbook = selectedScrapbook {
                    ScrapbookDetailView(scrapbook: scrapbook)
                        .environment(\.managedObjectContext, viewContext)
                }
            }
            // Push to ScrapbookContentView (used after creating)
            .navigationDestination(isPresented: $navigateToCanvas) {
                if let scrapbook = scrapbookToNavigate {
                    ScrapbookContentView(scrapbook: scrapbook)
                }
            }
        }
    }
}

// MARK: - Placeholder for empty state
private struct ContentPlaceholderView: View {
    var createAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 48, weight: .regular))
                .foregroundStyle(.secondary)
            Text("No Scrapbooks Yet")
                .font(.headline)
            Text("Start your first scrapbook to capture your favorite moments.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                createAction()
            } label: {
                Text("CREATE SCRAPBOOK")
                    .font(.system(size: 16, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary, lineWidth: 1)
                    )
            }
        }
        
        .frame(maxWidth: .infinity)
        .padding()
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
