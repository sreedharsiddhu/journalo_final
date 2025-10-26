import SwiftUI
import PencilKit
import UIKit

struct FullScreenScrapbookView: View {
    @ObservedObject var scrapbook: Scrapbook
    @Environment(\.dismiss) var dismiss

    @State private var pages: [ScrapbookPage] = []
    @State private var currentPageIndex = 0
    @State private var renderedDrawings: [UUID: UIImage] = [:]
    @State private var timer: Timer? = nil
    @State private var showControls = true

    private let impact = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if pages.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No pages to display")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text("Add pages in the editor to view them here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TabView(selection: $currentPageIndex) {
                    ForEach(pages.indices, id: \.self) { index in
                        PageView(
                            page: pages[index],
                            backgroundStyle: scrapbook.pageStyle ?? "Plain",
                            drawingImage: renderedDrawings[pages[index].id]
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: currentPageIndex) { _ in impact.impactOccurred() }
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showControls.toggle()
                    }
                }
                .ignoresSafeArea()

                // Overlay Controls
                if showControls {
                    VStack(spacing: 0) {
                        // Progress Segments at the very top in navigation bar area
                        if pages.count > 1 {
                            ProgressSegments(currentIndex: currentPageIndex, total: pages.count)
                                .padding(.horizontal, 70)
                                .padding(.leading, 10)
                                .padding(.top, -35)
                        }

                        Spacer()

                        // Bottom page counter
                        Text("\(currentPageIndex + 1) / \(pages.count)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Capsule())
                            .padding(.bottom, 40)
                    }
                    .transition(.opacity)
                }
            }
        }
        .statusBar(hidden: !showControls)
        .onAppear {
            loadPages()
            startAutoAdvance()
        }
        .onDisappear {
            stopAutoAdvance()
        }
        .task(id: pages.map(\.id)) {
            await preRenderDrawings()
        }
    }

    // MARK: - Timer Management
    private func startAutoAdvance() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            guard !pages.isEmpty, pages.count > 1 else { return }
            withAnimation {
                currentPageIndex = (currentPageIndex + 1) % pages.count
            }
        }
    }
    
    private func stopAutoAdvance() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Data Loading
    private func loadPages() {
        guard let data = scrapbook.bodyContent else {
            pages = []
            return
        }
        do {
            let decoder = JSONDecoder()
            pages = try decoder.decode([ScrapbookPage].self, from: data)
            currentPageIndex = min(currentPageIndex, max(0, pages.count - 1))
        } catch {
            print("Error decoding scrapbook: \(error.localizedDescription)")
            pages = []
        }
    }

    // MARK: - Rendering
    private func preRenderDrawings() async {
        guard !pages.isEmpty else {
            renderedDrawings = [:]
            return
        }
        var cache: [UUID: UIImage] = [:]
        for page in pages {
            if let data = page.drawingData,
               let drawing = try? PKDrawing(data: data) {
                let scale = UIScreen.main.scale
                let image = drawing.image(from: drawing.bounds, scale: scale)
                cache[page.id] = image
            }
        }
        await MainActor.run {
            renderedDrawings = cache
        }
    }
}

// MARK: - Progress Segments
private struct ProgressSegments: View {
    let currentIndex: Int
    let total: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { i in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                        
                        if i <= currentIndex {
                            Capsule()
                                .fill(Color.white)
                                .frame(width: geo.size.width)
                        }
                    }
                }
                .frame(height: 3)
            }
        }
        .frame(height: 3)
        .animation(.easeInOut(duration: 0.25), value: currentIndex)
    }
}

// MARK: - Page View
private struct PageView: View {
    let page: ScrapbookPage
    let backgroundStyle: String
    let drawingImage: UIImage?

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                PageBackgroundView(style: backgroundStyle)

                if let drawingImage {
                    Image(uiImage: drawingImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size.width, height: size.height)
                }

                ZStack {
                    ForEach(page.elements) { element in
                        MovableElementView(element: .constant(element))
                            .allowsHitTesting(false)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.black)
        .ignoresSafeArea()
    }
}
