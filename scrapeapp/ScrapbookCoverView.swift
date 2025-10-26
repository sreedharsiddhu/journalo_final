import SwiftUI
import UIKit
import CoreData

struct ScrapbookCoverView: View {
    @ObservedObject var scrapbook: Scrapbook

    var body: some View {
        Group {
            if let imageData = scrapbook.coverImageData {
                #if os(macOS)
                if let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color(red: 0.6, green: 0.74, blue: 0.87))
                }
                #else
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color(red: 0.6, green: 0.74, blue: 0.87))
                }
                #endif
            } else {
                Rectangle()
                    .fill(Color(red: 0.6, green: 0.74, blue: 0.87))
            }
        }
        .frame(width: 154.38017, height: 230.69321)
        .clipped()
        .cornerRadius(5)
        .shadow(color: .black.opacity(0.25), radius: 21.5, x: 0, y: 26)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .inset(by: 0.5)
                .stroke(.black, lineWidth: 1)
        )
    }
}
