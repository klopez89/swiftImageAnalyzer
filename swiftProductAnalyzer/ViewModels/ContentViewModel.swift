import SwiftUI
import Combine

class ContentViewModel: ObservableObject {
    // Properties for the input area
    @Published var stagedProductImages: [ProductImage] = []
    @Published var userQuery: String = ""

    // Properties for the chat display
    @Published var chatMessages: [ChatMessage] = []

    // General state properties
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let analysisService = AnalysisService()
    private var cancellables = Set<AnyCancellable>()

    // Called when images are selected via the file importer
    func stageImages(selectedImages: [NSImage]) {
        let newProductImages = selectedImages.map { ProductImage(image: $0) }
        // Ensure we don't exceed 4 images in the staging area
        let availableSlots = 4 - stagedProductImages.count
        if availableSlots > 0 {
            stagedProductImages.append(contentsOf: newProductImages.prefix(availableSlots))
        }
        // If more images were selected than available slots, consider providing feedback to the user.
    }

    // Called to remove an image from the staging area (e.g., by tapping an 'x' on a thumbnail)
    func removeStagedImage(image: ProductImage) {
        stagedProductImages.removeAll { $0.id == image.id }
    }
    
    func removeStagedImage(atOffsets offsets: IndexSet) {
        stagedProductImages.remove(atOffsets: offsets)
    }

    // Called when the user submits their query
    func submitQuery() {
        guard !stagedProductImages.isEmpty else {
            errorMessage = "Please add at least one image to analyze."
            return
        }
        guard !userQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a query."
            return
        }

        isLoading = true
        errorMessage = nil

        // Create and add the user's message to the chat
        let userMessage = ChatMessage.userMessage(query: userQuery, images: stagedProductImages)
        chatMessages.append(userMessage)

        // Keep a copy of staged images and current query for the service call
        let imagesToAnalyze = stagedProductImages
        let currentQuery = userQuery

        // Clear the input area *before* the async call (optimistic update)
        // Alternatively, clear after successful API response
        stagedProductImages.removeAll()
        self.userQuery = ""

        analysisService.analyzeImages(images: imagesToAnalyze, query: currentQuery)
            .receive(on: DispatchQueue.main)
            .sink {
                [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                    // Optionally, add an error message to chatMessages as well, or revert optimistic clearing
                    print("Error analyzing images: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] analyzedImagesFromService in
                // Create and add the bot's response to the chat
                // The `analyzedImagesFromService` should have individual analysis results populated by the service
                let botMessage = ChatMessage.botMessage(analyzedImages: analyzedImagesFromService)
                self?.chatMessages.append(botMessage)
            }
            .store(in: &cancellables)
    }
} 