import Foundation
import CoreGraphics
import UIKit
import SwiftUI // Need SwiftUI to use Color

// MARK: - Color Codable Extension
// Utility to allow SwiftUI.Color to be saved to and loaded from Core Data (via Data)

extension Color: Codable {
    // Decoding: Read Hex String and convert to Color
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let hex = try container.decode(String.self)
        
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }

    // Encoding: Convert Color to a Hex String for storage
    public func encode(to encoder: Encoder) throws {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let hex = String(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
        
        var container = encoder.singleValueContainer()
        try container.encode(hex)
    }
}

// MARK: - PageElement Struct
struct PageElement: Identifiable, Codable {
    let id: UUID
    
    // Content data
    var imageData: Data?
    var text: String?
    
    // NEW TEXT CUSTOMIZATION PROPERTIES
    var textColor: Color
    var fontSize: CGFloat
    var fontName: String
    
    // Transformation properties
    var position: CGPoint
    var scale: CGFloat
    var rotation: Double
    var zIndex: Double
    
    init(id: UUID = UUID(),
         imageData: Data? = nil,
         text: String? = nil,
         // Customization defaults
         textColor: Color = .black,
         fontSize: CGFloat = 18,
         fontName: String = "System",
         // Transform defaults
         position: CGPoint = CGPoint(x: 200, y: 300),
         scale: CGFloat = 1.0,
         rotation: Double = 0.0,
         zIndex: Double = Date().timeIntervalSince1970) {
        
        self.id = id
        self.imageData = imageData
        self.text = text
        self.textColor = textColor
        self.fontSize = fontSize
        self.fontName = fontName
        self.position = position
        self.scale = scale
        self.rotation = rotation
        self.zIndex = zIndex
    }
    
    var uiImage: UIImage? {
        if let data = imageData {
            return UIImage(data: data)
        }
        return nil
    }
}

// MARK: - ScrapbookPage Struct
struct ScrapbookPage: Identifiable, Codable {
    let id: UUID
    var elements: [PageElement] = []
    var drawingData: Data? // ADDED: Store PKDrawing as Data for each page
    
    init(id: UUID = UUID(), elements: [PageElement] = [], drawingData: Data? = nil) {
        self.id = id
        self.elements = elements
        self.drawingData = drawingData
    }
}
