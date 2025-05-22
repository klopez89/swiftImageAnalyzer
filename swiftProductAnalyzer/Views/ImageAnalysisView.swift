import SwiftUI

struct ImageAnalysisView: View {
    @ObservedObject var viewModel: ContentViewModel

    var body: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView {
                LazyVStack(spacing: 15) {
                    ForEach(viewModel.chatMessages) { message in
                        ChatMessageView(message: message)
                            .id(message.id) // For scrolling to new messages
                    }
                    
                    // Placeholder if no messages and not loading
                    if viewModel.chatMessages.isEmpty && !viewModel.isLoading {
                        VStack {
                            Image(systemName: "message.and.waveform") // Icon suggesting conversation/analysis
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.6))
                            Text("Ask a question about your uploaded images (up to 4) to start the analysis.")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.top, 5)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding()
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.chatMessages.count) { _ in
                // Scroll to the bottom when new messages are added
                if let lastMessage = viewModel.chatMessages.last {
                    withAnimation {
                        scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

struct ChatMessageView: View {
    let message: ChatMessage

    var body: some View {
        Group {
            if message.sender == .user {
                UserMessageView(message: message)
            } else {
                BotMessageView(message: message)
            }
        }
    }
}

struct UserMessageView: View {
    let message: ChatMessage

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            // Display images submitted with the query FIRST
            if let queryImages = message.queryImages, !queryImages.isEmpty {
                HStack {
                    Spacer()
                    ForEach(queryImages) { img in
                        Image(nsImage: img.image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            // Display user's query text SECOND
            if let queryText = message.queryText, !queryText.isEmpty {
                Text(queryText)
                    .padding(12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.leading, 60)
        .padding(.trailing, 16)
    }
}

struct BotMessageView: View {
    let message: ChatMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let analyzedImages = message.analyzedImages, !analyzedImages.isEmpty {
                ForEach(analyzedImages) { productImage in
                    HStack(alignment: .top, spacing: 10) {
                        Image(nsImage: productImage.image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))

                        if let result = productImage.analysisResult, !result.isEmpty {
                            Text(result)
                                .padding(12)
                                .background(Color(NSColor.controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .textSelection(.enabled)
                        } else {
                            Text("No analysis result for this image.")
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .padding(10)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Text("I'm ready for your query!")
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 16)
        .padding(.trailing, 60) // Give more space on the right for bot messages
    }
} 