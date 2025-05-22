import SwiftUI

struct ProductImage: Identifiable {
    let id = UUID()
    let image: NSImage // Using NSImage for macOS
    var analysisResult: String?
    // TODO: Add any other relevant properties, e.g., original file name
} 