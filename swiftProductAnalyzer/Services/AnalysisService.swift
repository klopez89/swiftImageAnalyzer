import Foundation
import Combine
import FirebaseCore
import FirebaseVertexAI // Updated import
import SwiftUI // For NSImage manipulation, though ideally keep UI types out of service

// TODO: Replace with your actual API Key
private let GEMINI_API_KEY = "YOUR_API_KEY"

class AnalysisService {
    private var cancellables = Set<AnyCancellable>()

    // Initialize the Vertex AI generative model.
    // Using "gemini-pro-vision" as a widely available model for multimodal tasks.
    // Ensure your Firebase project is configured for Vertex AI and the necessary APIs are enabled.
    private lazy var generativeModel = VertexAI.vertexAI().generativeModel(modelName: "gemini-2.0-flash-001")

    // Placeholder for your actual parsing function - YOU NEED TO IMPLEMENT THIS
    private func parseIndividualAnalyses(from responseText: String, imageCount: Int) -> [String] {
        print("Attempting to parse: \"\(responseText)\" for \(imageCount) images.")
        var results = [String](repeating: "Analysis not available or parsing failed.", count: imageCount)
        if imageCount == 0 { return [] }

        // First check if we have any "imageN:" delimiters
        var hasImageDelimiters = false
        for i in 1...imageCount {
            if responseText.localizedCaseInsensitiveContains("image\(i):") {
                hasImageDelimiters = true
                break
            }
        }

        // If no image delimiters found and we have content, treat as single image response
        if !hasImageDelimiters {
            if !responseText.isEmpty {
                print("Parser: No image delimiters found. Treating as single image response.")
                results[0] = responseText.trimmingCharacters(in: .whitespacesAndNewlines)
                for i in 1..<imageCount {
                    results[i] = "Individual analysis not parsed. Full response assigned to first image."
                }
            }
            return results
        }

        // Parse with imageN: delimiters
        var currentSearchStartIndex = responseText.startIndex

        for i in 0..<imageCount {
            let imageNumber = i + 1
            let delimiterPattern = "image\(imageNumber):"
            
            guard let startRange = responseText.range(of: delimiterPattern, options: .caseInsensitive, range: currentSearchStartIndex..<responseText.endIndex) else {
                print("Parser: Did not find delimiter '\(delimiterPattern)' for image \(imageNumber)")
                continue
            }

            let analysisTextStartIndex = startRange.upperBound
            var analysisTextEndIndex = responseText.endIndex

            // Look for next image delimiter if not the last image
            if i + 1 < imageCount {
                let nextDelimiterPattern = "image\(imageNumber + 1):"
                if let nextStartRange = responseText.range(of: nextDelimiterPattern, options: .caseInsensitive, range: analysisTextStartIndex..<responseText.endIndex) {
                    analysisTextEndIndex = nextStartRange.lowerBound
                }
            }
            
            var extractedText = String(responseText[analysisTextStartIndex..<analysisTextEndIndex])
            extractedText = extractedText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if extractedText.hasSuffix(".") {
                extractedText = String(extractedText.dropLast())
            }
            
            results[i] = extractedText
            print("Parser: Successfully parsed for image \(imageNumber): \"\(results[i])\"")
            
            currentSearchStartIndex = analysisTextEndIndex
        }

        return results
    }

    func analyzeImages(images: [ProductImage], query: String) -> AnyPublisher<[ProductImage], AppError> {
        // Future to bridge async/await with Combine
        return Future<[ProductImage], AppError> { promise in
            Task {
                do {
                    // 1. Prepare parts for the multimodal prompt
                    var parts: [any Part] = []

                    for productImage in images {
                        // Convert NSImage to Data. Using PNG representation.
                        // Ensure this conversion is robust.
                        guard let imageData = productImage.image.pngData() else {
                            throw AppError.imageLoadingError("Could not get PNG data for image \(productImage.id)")
                        }
                        // Add image part - Changed DataPart to InlineDataPart
                        parts.append(InlineDataPart(data: imageData, mimeType: "image/png"))
                    }

                    // Format the query to request specific response structure
                    let formattedQuery = """
                    \(query)
                    
                    Please format your response using "image1:", "image2:", etc. for each image analysis. For example:
                    image1: [analysis for first image]
                    image2: [analysis for second image]
                    """
                    
                    // Add the formatted text query part
                    parts.append(TextPart(formattedQuery))

                    // 2. Make the API call
                    // Wrap the parts in a Content object with a "user" role.
                    let userMessage = ModelContent(role: "user", parts: parts)
                    // Pass an array of Content objects to generateContent.
                    let response = try await self.generativeModel.generateContent([userMessage])

                    // 3. Process the response
                    var updatedImages = images
                    if let textResponse = response.text {
                        let individualAnalyses = self.parseIndividualAnalyses(from: textResponse, imageCount: updatedImages.count)
                        
                        if individualAnalyses.count == updatedImages.count {
                            for i in 0..<updatedImages.count {
                                updatedImages[i].analysisResult = individualAnalyses[i]
                            }
                            promise(.success(updatedImages))
                        } else {
                            // Parsing failed to return the correct number of results
                            // Fallback: assign full text to first image or handle error
                             print("Parsing error: Expected \(updatedImages.count) analyses, got \(individualAnalyses.count). Using raw response for first image if available.")
                            if !updatedImages.isEmpty {
                                updatedImages[0].analysisResult = "Failed to parse results correctly. Full response: \(textResponse)"
                                for k in 1..<updatedImages.count { updatedImages[k].analysisResult = "Parsing error." }
                            } 
                            promise(.success(updatedImages)) // Or .failure if this is critical
                        }
                    } else {
                        // If there's no text, but also no error, it might be an empty response or a function call.
                        // For this app, we expect text.
                        promise(.failure(AppError.apiError("No text content in API response.")))
                    }

                } catch let error as NSError {
                    var specificMessage = error.localizedDescription // Default to localizedDescription

                    // Attempt to get a more specific message from userInfo
                    if let failureReason = error.userInfo[NSLocalizedFailureReasonErrorKey] as? String {
                        specificMessage = failureReason
                    } else if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
                        // If there's an underlying error, prefer its description or failure reason
                        specificMessage = underlyingError.userInfo[NSLocalizedFailureReasonErrorKey] as? String ?? underlyingError.localizedDescription
                    } else if let details = error.userInfo["details"] as? String { // Common key for additional details
                        specificMessage = details
                    } else if let firebaseErrorMessage = error.userInfo["FIRAuthErrorUserInfoNameKey"] as? String { // Key seen in FIRAuth errors
                         specificMessage = firebaseErrorMessage
                    }
                    // Add the specific error message you saw in the logs, if it's consistently available under a specific key
                    // For instance, if the server message was always in error.userInfo[" ನಮ್ಮServerMessageKey"] (replace with actual key if found)

                    let messageForUI = "API Error: \(specificMessage)"
                    print("Firebase AI Error Details: code=\(error.code), domain=\(error.domain), userInfo=\(error.userInfo)")
                    promise(.failure(AppError.apiError(messageForUI)))
                } catch {
                    // Catch any other Swift errors
                    promise(.failure(AppError.generalError("An unexpected error occurred: \(error.localizedDescription)")))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

// Helper to convert NSImage to Data (example for PNG)
extension NSImage {
    func pngData() -> Data? {
        guard let tiffRepresentation = tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else {
            return nil
        }
        return bitmapImage.representation(using: .png, properties: [:])
    }
} 
