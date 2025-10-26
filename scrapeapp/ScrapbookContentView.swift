import SwiftUI
import CoreData
import PencilKit

struct ScrapbookContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var scrapbook: Scrapbook
    @Environment(\.dismiss) var dismiss

    @State private var pages: [ScrapbookPage] = []
    @State private var currentPageIndex: Int = 0

    // Image Picker
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?

    // Text Sheet
    @State private var showingTextSheet = false
    @State private var newText: String = ""
    
    // Sticker Sheet
    @State private var showingStickerSheet = false

    // PencilKit - now per page
    @State private var showingDrawing = false
    @State private var currentTool: PKInkingTool = PKInkingTool(.pen, color: .black, width: 5)
    @State private var canvasKey = UUID()

    // Page carousel visibility
    @State private var showingPageCarousel = true
    
    // Long press delete
    @State private var pageToDelete: Int?

    // Available pencil colors
    private let pencilColors: [Color] = [.black, .red, .blue, .green, .orange, .purple, .brown]

    var body: some View {
        ZStack {
            backgroundView
            contentLayer
            
            VStack {
                Spacer()
                if showingPageCarousel {
                    pageCarousel
                        .transition(.move(edge: .bottom))
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationTitle(navigationTitleText)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadPages)
        .onDisappear(perform: savePages)
        .onChange(of: currentPageIndex) { _ in
            handlePageChange()
        }
        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
            ImagePicker(image: $inputImage)
        }
        .sheet(isPresented: $showingTextSheet, onDismiss: addTextElement) {
            TextEntrySheet(text: $newText)
        }
        .sheet(isPresented: $showingStickerSheet) {
            StickerPickerSheet { stickerName in
                addSticker(stickerName)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                toolbarContent
            }
        }
    }
    
    // MARK: - Computed Views
    
    private var navigationTitleText: String {
        scrapbook.title ?? "Scrapbook"
    }
    
    private var backgroundView: some View {
        PageBackgroundView(style: scrapbook.pageStyle ?? "Plain")
            .ignoresSafeArea()
    }
    
    private var contentLayer: some View {
        ZStack {
            pageElements
            drawingOverlay
        }
    }
    
    private var pageElements: some View {
        Group {
            if pages.indices.contains(currentPageIndex) {
                ForEach($pages[currentPageIndex].elements) { $element in
                    MovableElementView(element: $element)
                        .zIndex(element.zIndex)
                        .onTapGesture {
                            element.zIndex = Date().timeIntervalSince1970
                        }
                }
            } else {
                Text("Tap '+' in the carousel below to add your first page.")
                    .foregroundColor(.gray)
            }
        }
    }
    
    @ViewBuilder
    private var drawingOverlay: some View {
        if pages.indices.contains(currentPageIndex) {
            PencilCanvas(
                drawing: bindingForCurrentDrawing(),
                tool: currentTool,
                isActive: $showingDrawing
            )
            .id(canvasKey)
            .zIndex(10000)
            .allowsHitTesting(showingDrawing)
        }
    }
    
    // MARK: - Page Carousel
    
    private var pageCarousel: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                            PageThumbnail(
                                page: page,
                                index: index,
                                isSelected: index == currentPageIndex,
                                backgroundStyle: scrapbook.pageStyle ?? "Plain",
                                showDelete: pageToDelete == index
                            )
                            .onTapGesture {
                                if pageToDelete == index {
                                    pageToDelete = nil
                                } else {
                                    withAnimation {
                                        currentPageIndex = index
                                        pageToDelete = nil
                                    }
                                }
                            }
                            .onLongPressGesture(minimumDuration: 0.5) {
                                if pages.count > 1 {
                                    withAnimation(.spring(response: 0.3)) {
                                        pageToDelete = index
                                    }
                                }
                            }
                            .overlay(alignment: .topTrailing) {
                                if pageToDelete == index {
                                    Button {
                                        deletePage(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.red)
                                            .background(Circle().fill(Color.white))
                                    }
                                    .offset(x: 8, y: -8)
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .id(index)
                        }
                        
                        // Add page button
                        Button {
                            addPage()
                        } label: {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5]))
                                .frame(width: 60, height: 100)
                                .overlay(
                                    Image(systemName: "plus")
                                        .font(.title2)
                                        .foregroundColor(.gray)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                .frame(height: 120)
                .onChange(of: currentPageIndex) { newIndex in
                    withAnimation {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
            
            Divider()
        }
        .background(Color.clear)
    }
    
    private func bindingForCurrentDrawing() -> Binding<PKDrawing> {
        Binding<PKDrawing>(
            get: {
                guard pages.indices.contains(currentPageIndex) else { return PKDrawing() }
                if let data = pages[currentPageIndex].drawingData {
                    return (try? PKDrawing(data: data)) ?? PKDrawing()
                }
                return PKDrawing()
            },
            set: { newDrawing in
                guard pages.indices.contains(currentPageIndex) else { return }
                pages[currentPageIndex].drawingData = newDrawing.dataRepresentation()
            }
        )
    }
    
    private var toolbarContent: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // Page carousel toggle
                Button {
                    withAnimation(.spring()) {
                        showingPageCarousel.toggle()
                        pageToDelete = nil
                    }
                } label: {
                    Image(systemName: showingPageCarousel ? "rectangle.stack.fill" : "rectangle.stack")
                }
                
                Divider().frame(height: 30)
                
                if showingDrawing {
                    // Drawing mode: show drawing tools
                    drawingToggleButton
                    drawingTools
                } else {
                    // Normal mode: show content tools
                    contentButtons
                    drawingToggleButton
                }
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private var contentButtons: some View {
        if !showingDrawing {
            Button {
                showingImagePicker = true
            } label: {
                Image(systemName: "photo.on.rectangle.angled")
            }
            .disabled(pages.isEmpty)

            Button {
                showingTextSheet = true
            } label: {
                Image(systemName: "t.square")
            }
            .disabled(pages.isEmpty)
            
            Button {
                showingStickerSheet = true
            } label: {
                Image(systemName: "face.smiling")
            }
            .disabled(pages.isEmpty)
        }
    }
    
    private var drawingToggleButton: some View {
        Button {
            withAnimation {
                showingDrawing.toggle()
            }
        } label: {
            Image(systemName: showingDrawing ? "pencil.tip.crop.circle.badge.minus" : "pencil.tip")
        }
        .foregroundColor(showingDrawing ? .blue : .primary)
    }
    
    @ViewBuilder
    private var drawingTools: some View {
        if showingDrawing {
            colorPicker
            eraserButton
            clearDrawingButton
        }
    }
    
    private var colorPicker: some View {
        ForEach(pencilColors, id: \.self) { color in
            Circle()
                .fill(color)
                .frame(width: 28, height: 28)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: isSelectedColor(color) ? 3 : 0)
                )
                .shadow(radius: 2)
                .onTapGesture {
                    selectColor(color)
                }
        }
    }
    
    private var eraserButton: some View {
        Button {
            currentTool = PKInkingTool(.pen, color: .clear, width: 20)
        } label: {
            Image(systemName: "eraser.fill")
        }
    }
    
    private var clearDrawingButton: some View {
        Button {
            clearCurrentDrawing()
        } label: {
            Image(systemName: "trash")
        }
    }

    // MARK: - Helper Functions
    
    private func handlePageChange() {
        savePages()
        canvasKey = UUID()
    }
    
    private func isSelectedColor(_ color: Color) -> Bool {
        return currentTool.color == UIColor(color)
    }
    
    private func selectColor(_ color: Color) {
        currentTool = PKInkingTool(.pen, color: UIColor(color), width: 5)
    }
    
    private func clearCurrentDrawing() {
        if pages.indices.contains(currentPageIndex) {
            pages[currentPageIndex].drawingData = nil
            canvasKey = UUID()
            savePages()
        }
    }

    // MARK: - Actions

    private func addPage() {
        savePages()
        let newPage = ScrapbookPage()
        pages.append(newPage)
        currentPageIndex = pages.count - 1
        canvasKey = UUID()
        pageToDelete = nil
    }

    private func deletePage(at index: Int) {
        guard pages.count > 1 else {
            pageToDelete = nil
            return
        }
        
        withAnimation {
            pages.remove(at: index)
            if currentPageIndex >= pages.count {
                currentPageIndex = pages.count - 1
            } else if currentPageIndex >= index {
                currentPageIndex = max(0, currentPageIndex - 1)
            }
            pageToDelete = nil
            canvasKey = UUID()
        }
        savePages()
    }

    private func loadImage() {
        guard let inputImage = inputImage, pages.indices.contains(currentPageIndex) else { return }
        let imageData = inputImage.jpegData(compressionQuality: 0.8)
        let newElement = PageElement(imageData: imageData, text: nil)
        pages[currentPageIndex].elements.append(newElement)
        self.inputImage = nil
        savePages()
    }

    private func addTextElement() {
        guard !newText.isEmpty, pages.indices.contains(currentPageIndex) else { return }
        let newElement = PageElement(imageData: nil, text: newText)
        pages[currentPageIndex].elements.append(newElement)
        newText = ""
        savePages()
    }
    
    private func addSticker(_ stickerName: String) {
        guard pages.indices.contains(currentPageIndex) else { return }
        
        // Load the sticker image from assets
        if let stickerImage = UIImage(named: stickerName) {
            let imageData = stickerImage.pngData()
            let newElement = PageElement(imageData: imageData, text: nil)
            pages[currentPageIndex].elements.append(newElement)
            savePages()
        }
    }

    // MARK: - Load/Save

    private func loadPages() {
        if let data = scrapbook.bodyContent {
            do {
                let decoder = JSONDecoder()
                pages = try decoder.decode([ScrapbookPage].self, from: data)
                if pages.isEmpty { pages = [ScrapbookPage()] }
                currentPageIndex = min(currentPageIndex, pages.count - 1)
            } catch {
                print("Failed to decode scrapbook pages: \(error.localizedDescription)")
                pages = [ScrapbookPage()]
            }
        } else {
            pages = [ScrapbookPage()]
        }
    }

    private func savePages() {
        do {
            let encoder = JSONEncoder()
            scrapbook.bodyContent = try encoder.encode(pages)
            try viewContext.save()
        } catch {
            print("Failed to encode and save scrapbook pages: \(error.localizedDescription)")
        }
    }
}

// MARK: - Sticker Picker Sheet
struct StickerPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    let onStickerSelected: (String) -> Void
    
    private let stickerNames = (1...9).map { "sticker\($0)" }
    private let columns = [
        GridItem(.adaptive(minimum: 80), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(stickerNames, id: \.self) { stickerName in
                        Button {
                            onStickerSelected(stickerName)
                            dismiss()
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 80)
                                
                                Image(stickerName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(Color(red: 0.95, green: 0.94, blue: 0.92))
            .navigationTitle("Choose a Sticker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Page Thumbnail View
struct PageThumbnail: View {
    let page: ScrapbookPage
    let index: Int
    let isSelected: Bool
    let backgroundStyle: String
    let showDelete: Bool
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
            
            PageBackgroundView(style: backgroundStyle)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Canvas drawing preview
            if let drawingData = page.drawingData,
               let drawing = try? PKDrawing(data: drawingData) {
                Image(uiImage: drawing.image(from: drawing.bounds, scale: 0.5))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Selection indicator
            if isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: 3)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            }
        }
        .frame(width: 60, height: 100)
        .shadow(color: isSelected ? .blue.opacity(0.3) : .black.opacity(0.1), radius: isSelected ? 5 : 2)
        .scaleEffect(showDelete ? 0.95 : 1.0)
        .animation(.spring(response: 0.3), value: showDelete)
    }
}

// MARK: - PencilKit Canvas Wrapper
struct PencilCanvas: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let tool: PKInkingTool
    @Binding var isActive: Bool
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.allowsFingerDrawing = true
        canvas.drawing = drawing
        canvas.tool = tool
        canvas.delegate = context.coordinator
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        canvas.drawing = drawing
        canvas.tool = tool
        canvas.isUserInteractionEnabled = isActive
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PencilCanvas
        
        init(_ parent: PencilCanvas) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
        }
    }
}
