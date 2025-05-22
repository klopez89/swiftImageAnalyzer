import Foundation

enum AppError: Error, LocalizedError {
    case imageLoadingError(String)
    case apiError(String)
    case generalError(String)

    var errorDescription: String? {
        switch self {
        case .imageLoadingError(let message):
            return "Image Loading Error: \(message)"
        case .apiError(let message):
            return "API Error: \(message)"
        case .generalError(let message):
            return "Error: \(message)"
        }
    }
}