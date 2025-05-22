import Foundation
import SwiftUI // For NSImage if we decide to store it directly, or just IDs

struct ChatMessage: Identifiable {
    let id = UUID()
    enum Sender { case user, bot }

    let sender: Sender
    let queryText: String?                     // User's query text
    let queryImages: [ProductImage]?         // Images submitted with the user's query (copies)
    let analyzedImages: [ProductImage]?      // Images with their individual analysis results from the bot
    let timestamp: Date = Date()             // Timestamp for sorting/display

    // Convenience initializers
    static func userMessage(query: String, images: [ProductImage]) -> ChatMessage {
        return ChatMessage(sender: .user, queryText: query, queryImages: images, analyzedImages: nil)
    }

    static func botMessage(analyzedImages: [ProductImage]) -> ChatMessage {
        return ChatMessage(sender: .bot, queryText: nil, queryImages: nil, analyzedImages: analyzedImages)
    }
} 