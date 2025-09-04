import Foundation
#if os(Linux)
import FoundationNetworking
#endif
/// The main client for interacting with the arXiv API
public actor ArxivClient {
    
    // MARK: - Properties
    
    private let session: URLSession
    private let xmlParser: ArxivXMLParserDelegate
    
    /// Default timeout interval for requests (30 seconds)
    public static let defaultTimeoutInterval: TimeInterval = 30.0
    
    // MARK: - Initialization
    
    /// Initialize a new ArxivClient
    /// - Parameter session: Optional URLSession to use for requests. Defaults to a configured session.
    public init(session: URLSession? = nil) {
        if let session = session {
            self.session = session
        } else {
            // Create a configured session with appropriate timeout
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = Self.defaultTimeoutInterval
            config.timeoutIntervalForResource = Self.defaultTimeoutInterval * 2
            
            // Set a user agent to be respectful to the arXiv API
            config.httpAdditionalHeaders = [
                "User-Agent": "ArxivSwift/1.0 (Swift Package)"
            ]
            
            self.session = URLSession(configuration: config)
        }
        
        self.xmlParser = ArxivXMLParserDelegate()
    }
    
    // MARK: - Public API
    
    /// Fetch arXiv entries based on a query
    /// - Parameter query: The ArxivQuery specifying search criteria
    /// - Returns: Array of ArxivEntry objects matching the query
    /// - Throws: ArxivError if the request fails or parsing fails
    public func getEntries(for query: ArxivQuery) async throws -> [ArxivEntry] {
        let urlString = query.buildURLString()
        
        guard let url = URL(string: urlString) else {
            throw ArxivError.invalidURL(urlString)
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            // Validate HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                guard httpResponse.statusCode == 200 else {
                    throw ArxivError.from(httpResponse: httpResponse)
                }
            }
            
            // Validate that we received data
            guard !data.isEmpty else {
                throw ArxivError.noData
            }
            
            // Parse the XML response
            let entries = try xmlParser.parseEntries(from: data)
            
            return entries
            
        } catch let error as ArxivError {
            throw error
        } catch let urlError as URLError {
            throw ArxivError.from(urlError: urlError)
        } catch {
            throw ArxivError.networkError(error)
        }
    }
    
    /// Fetch a single arXiv entry by its ID
    /// - Parameter arxivId: The arXiv ID (e.g., "2301.12345" or "2301.12345v1")
    /// - Returns: The ArxivEntry if found
    /// - Throws: ArxivError if the request fails, parsing fails, or entry not found
    public func getEntry(by arxivId: String) async throws -> ArxivEntry {
        let query = ArxivQuery().addSearch(field: .id, value: arxivId).maxResults(1)
        let entries = try await getEntries(for: query)
        
        guard let entry = entries.first else {
            throw ArxivError.invalidQuery("No entry found with ID: \(arxivId)")
        }
        
        return entry
    }
    
    /// Search for entries by author
    /// - Parameters:
    ///   - author: The author name to search for
    ///   - maxResults: Maximum number of results to return (default: 10)
    ///   - sortBy: How to sort the results (default: relevance)
    /// - Returns: Array of ArxivEntry objects by the specified author
    /// - Throws: ArxivError if the request fails or parsing fails
    public func searchByAuthor(
        _ author: String,
        maxResults: Int = 10,
        sortBy: SortBy = .relevance
    ) async throws -> [ArxivEntry] {
        let query = ArxivQuery.byAuthor(author)
            .maxResults(maxResults)
            .sort(by: sortBy)
        
        return try await getEntries(for: query)
    }
    
    /// Search for entries by title
    /// - Parameters:
    ///   - title: The title terms to search for
    ///   - maxResults: Maximum number of results to return (default: 10)
    ///   - sortBy: How to sort the results (default: relevance)
    /// - Returns: Array of ArxivEntry objects matching the title search
    /// - Throws: ArxivError if the request fails or parsing fails
    public func searchByTitle(
        _ title: String,
        maxResults: Int = 10,
        sortBy: SortBy = .relevance
    ) async throws -> [ArxivEntry] {
        let query = ArxivQuery.byTitle(title)
            .maxResults(maxResults)
            .sort(by: sortBy)
        
        return try await getEntries(for: query)
    }
    
    /// Search for entries in a specific category
    /// - Parameters:
    ///   - category: The arXiv category (e.g., "cs.AI", "math.NT")
    ///   - maxResults: Maximum number of results to return (default: 10)
    ///   - sortBy: How to sort the results (default: submittedDate)
    /// - Returns: Array of ArxivEntry objects in the specified category
    /// - Throws: ArxivError if the request fails or parsing fails
    public func searchByCategory(
        _ category: String,
        maxResults: Int = 10,
        sortBy: SortBy = .submittedDate
    ) async throws -> [ArxivEntry] {
        let query = ArxivQuery.byCategory(category)
            .maxResults(maxResults)
            .sort(by: sortBy)
        
        return try await getEntries(for: query)
    }
    
    /// Search for entries containing specific terms in the abstract
    /// - Parameters:
    ///   - terms: The terms to search for in abstracts
    ///   - maxResults: Maximum number of results to return (default: 10)
    ///   - sortBy: How to sort the results (default: relevance)
    /// - Returns: Array of ArxivEntry objects matching the abstract search
    /// - Throws: ArxivError if the request fails or parsing fails
    public func searchByAbstract(
        _ terms: String,
        maxResults: Int = 10,
        sortBy: SortBy = .relevance
    ) async throws -> [ArxivEntry] {
        let query = ArxivQuery.byAbstract(terms)
            .maxResults(maxResults)
            .sort(by: sortBy)
        
        return try await getEntries(for: query)
    }
    
    /// Get the latest entries from arXiv
    /// - Parameters:
    ///   - maxResults: Maximum number of results to return (default: 10)
    ///   - category: Optional category to filter by
    /// - Returns: Array of the most recent ArxivEntry objects
    /// - Throws: ArxivError if the request fails or parsing fails
    public func getLatestEntries(
        maxResults: Int = 10,
        category: String? = nil
    ) async throws -> [ArxivEntry] {
        var query = ArxivQuery()
            .maxResults(maxResults)
            .sort(by: .submittedDate, order: .descending)
        
        if let category = category {
            query = query.addSearch(field: .category, value: category)
        }
        
        return try await getEntries(for: query)
    }
}

// MARK: - Convenience Extensions

public extension ArxivClient {
    /// A shared instance of ArxivClient for convenience
    static let shared = ArxivClient()
} 