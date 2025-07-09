import Foundation
#if os(Linux)
import FoundationNetworking
#endif

/// Errors that can occur when using the ArxivSwift library
public enum ArxivError: Error, LocalizedError, Equatable {
    /// Network-related errors
    case networkError(Error)
    
    /// Invalid URL construction
    case invalidURL(String)
    
    /// XML parsing errors
    case parsingError(String)
    
    /// Invalid response format
    case invalidResponse
    
    /// No data received from the API
    case noData
    
    /// HTTP error with status code
    case httpError(Int)
    
    /// Rate limiting error
    case rateLimited
    
    /// Invalid query parameters
    case invalidQuery(String)
    
    /// Timeout error
    case timeout
    
    /// Unknown error
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .parsingError(let message):
            return "XML parsing error: \(message)"
        case .invalidResponse:
            return "Invalid response format received from arXiv API"
        case .noData:
            return "No data received from arXiv API"
        case .httpError(let statusCode):
            return "HTTP error with status code: \(statusCode)"
        case .rateLimited:
            return "Rate limited by arXiv API. Please wait before making more requests."
        case .invalidQuery(let message):
            return "Invalid query: \(message)"
        case .timeout:
            return "Request timed out"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .networkError:
            return "A network error occurred while communicating with the arXiv API"
        case .invalidURL:
            return "The constructed URL for the API request is invalid"
        case .parsingError:
            return "Failed to parse the XML response from the arXiv API"
        case .invalidResponse:
            return "The response from the arXiv API is not in the expected format"
        case .noData:
            return "The arXiv API returned an empty response"
        case .httpError(let statusCode):
            if statusCode >= 500 {
                return "The arXiv API is experiencing server issues"
            } else if statusCode >= 400 {
                return "The request to the arXiv API was invalid"
            } else {
                return "An HTTP error occurred"
            }
        case .rateLimited:
            return "Too many requests have been made to the arXiv API"
        case .invalidQuery:
            return "The query parameters provided are invalid"
        case .timeout:
            return "The request to the arXiv API took too long to complete"
        case .unknown:
            return "An unexpected error occurred"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Check your internet connection and try again"
        case .invalidURL:
            return "Verify that your query parameters are valid"
        case .parsingError:
            return "This may be a temporary issue with the arXiv API. Try again later."
        case .invalidResponse:
            return "This may be a temporary issue with the arXiv API. Try again later."
        case .noData:
            return "Try a different query or check if the arXiv API is available"
        case .httpError(let statusCode):
            if statusCode >= 500 {
                return "Wait a moment and try again. If the problem persists, the arXiv API may be down."
            } else if statusCode >= 400 {
                return "Check your query parameters and try again"
            } else {
                return "Try again later"
            }
        case .rateLimited:
            return "Wait a few seconds before making another request"
        case .invalidQuery:
            return "Check your query parameters and ensure they follow arXiv API guidelines"
        case .timeout:
            return "Try again with a smaller query or check your internet connection"
        case .unknown:
            return "Try again later or contact support if the problem persists"
        }
    }
    
    // MARK: - Equatable
    
    public static func == (lhs: ArxivError, rhs: ArxivError) -> Bool {
        switch (lhs, rhs) {
        case (.networkError(let lhsError), .networkError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.invalidURL(let lhsURL), .invalidURL(let rhsURL)):
            return lhsURL == rhsURL
        case (.parsingError(let lhsMessage), .parsingError(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.invalidResponse, .invalidResponse),
             (.noData, .noData),
             (.rateLimited, .rateLimited),
             (.timeout, .timeout):
            return true
        case (.httpError(let lhsCode), .httpError(let rhsCode)):
            return lhsCode == rhsCode
        case (.invalidQuery(let lhsMessage), .invalidQuery(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.unknown(let lhsMessage), .unknown(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

// MARK: - Convenience Initializers

public extension ArxivError {
    /// Create a network error from a URLError
    static func from(urlError: URLError) -> ArxivError {
        switch urlError.code {
        case .timedOut:
            return .timeout
        case .notConnectedToInternet, .networkConnectionLost:
            return .networkError(urlError)
        default:
            return .networkError(urlError)
        }
    }
    
    /// Create an HTTP error from a response
    static func from(httpResponse: HTTPURLResponse) -> ArxivError {
        switch httpResponse.statusCode {
        case 429:
            return .rateLimited
        default:
            return .httpError(httpResponse.statusCode)
        }
    }
} 