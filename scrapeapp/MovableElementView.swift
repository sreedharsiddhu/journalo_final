import SwiftUI

struct MovableElementView: View {
    @Binding var element: PageElement
    @State private var showingEditSheet = false
    
    // State to track the temporary translation (drag offset)
    @State private var currentTranslation: CGSize = .zero
    
    // Gestures State (updating remains the same)
    @GestureState private var startPosition: CGPoint? = nil
    @GestureState private var startScale: CGFloat? = nil
    
    // Gesture for Moving the Element
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Apply the translation directly to the current state
                currentTranslation = value.translation
            }
            .onEnded { value in
                // On end, update the element's absolute position and reset translation
                element.position.x += value.translation.width
                element.position.y += value.translation.height
                currentTranslation = .zero // Reset translation for the next drag
            }
    }
    
    // Gesture for Scaling/Resizing the Element
    var pinchGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let startScl = startScale ?? element.scale
                element.scale = min(max(startScl * value, 0.5), 3.0)
            }
            .updating($startScale) { (value, state, transaction) in
                state = state ?? element.scale
            }
    }
    
    var body: some View {
        Group {
            if let image = element.uiImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150) // Fixed base size
                    .scaleEffect(element.scale) // Apply visual scale
                    .rotationEffect(.degrees(element.rotation))
                    
            } else if let text = element.text {
                Text(text)
                    // Apply base font size and custom color
                    .font(.system(size: element.fontSize))
                    .foregroundColor(element.textColor)
                    .padding(8)
                    .background(Color.clear)
                    .cornerRadius(5 / element.scale)
                    // Double-tap gesture to open the editor
                    .onTapGesture(count: 2) {
                        showingEditSheet = true
                    }
            }
        }
        // Apply saved absolute position
        .position(element.position)
        // Apply temporary drag offset only during drag operation
        .offset(currentTranslation)
        // Apply the overall scale
        .scaleEffect(element.scale)
        
        // Combine Drag and Pinch gestures
        .gesture(dragGesture.simultaneously(with: pinchGesture))
        .sheet(isPresented: $showingEditSheet) {
            if element.text != nil {
                RichTextEditSheet(element: $element)
            }
        }
    }
}
