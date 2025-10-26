import SwiftUI
import UIKit // Explicitly import UIKit for UIImage

struct CoverSelectionView: View {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    // FIX: Using consistent naming ("Book Cover [Number]") for all assets.
    // NOTE: All 10 images must exist in your Assets.xcassets with these exact names.
    let availableCovers: [UIImage] = [
        UIImage(named: "cover1")!,
        UIImage(named: "cover2")!,
        UIImage(named: "cover3")!,
        UIImage(named: "cover4")!,
        UIImage(named: "cover5")!,
        UIImage(named: "cover6")!,
        UIImage(named: "cover7")!,
        UIImage(named: "cover8")!,
        UIImage(named: "cover9")!,
        UIImage(named: "cover10")!,
        UIImage(named: "cover11")!,
        UIImage(named: "cover12")!,
        UIImage(named: "cover13")!,
        UIImage(named: "cover14")!
    ]
    
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 2)
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(availableCovers, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .onTapGesture {
                                self.selectedImage = image
                                dismiss()
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Select a Cover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
}
