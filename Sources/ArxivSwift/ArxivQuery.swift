import Foundation

/// Defines how results should be sorted when returned from the arXiv API.
///
/// Use this enum to specify the sorting criteria for your search results.
/// The default sorting method is by relevance.
///
/// Example:
/// ```swift
/// let query = ArxivQuery()
///     .sort(by: .submittedDate, order: .descending)
/// ```
public enum SortBy: String, CaseIterable, Sendable {
    /// Sort by relevance to the search query (default)
    case relevance = "relevance"
    /// Sort by the date the paper was last updated
    case lastUpdatedDate = "lastUpdatedDate"
    /// Sort by the date the paper was originally submitted
    case submittedDate = "submittedDate"
}

/// Defines the order in which sorted results should be returned.
///
/// Use this enum in conjunction with `SortBy` to control result ordering.
///
/// Example:
/// ```swift
/// let query = ArxivQuery()
///     .sort(by: .submittedDate, order: .ascending) // Oldest first
/// ```
public enum SortOrder: String, CaseIterable, Sendable {
    /// Sort in ascending order (oldest first for dates, lowest relevance first)
    case ascending = "ascending"
    /// Sort in descending order (newest first for dates, highest relevance first)
    case descending = "descending"
}

/// Defines the searchable fields in arXiv papers.
///
/// Each field corresponds to a specific part of an arXiv entry that can be searched.
/// Use these fields to create targeted searches.
///
/// Example:
/// ```swift
/// let query = ArxivQuery()
///     .addSearch(field: .title, value: "neural networks")
///     .addSearch(field: .category, value: "cs.AI")
/// ```
public enum QueryField: String, CaseIterable, Sendable {
    /// Search in paper titles
    case title = "ti"
    /// Search in author names
    case author = "au"
    /// Search in paper abstracts
    case abstract = "abs"
    /// Search in author comments
    case comment = "co"
    /// Search in journal references
    case journalReference = "jr"
    /// Search in subject categories
    case category = "cat"
    /// Search in report numbers
    case reportNumber = "rn"
    /// Search by arXiv ID
    case id = "id"
    /// Search across all fields
    case all = "all"
}

/// A builder for constructing arXiv API queries using a fluent interface.
///
/// `ArxivQuery` provides a type-safe, chainable API for building complex queries
/// to search the arXiv database. It supports searching across multiple fields,
/// pagination, and various sorting options.
///
/// ## Basic Usage
///
/// ```swift
/// // Simple search
/// let query = ArxivQuery()
///     .addSearch(field: .title, value: "machine learning")
///     .maxResults(20)
///
/// // Complex search with multiple criteria
/// let complexQuery = ArxivQuery()
///     .addSearch(field: .category, value: "cs.AI")
///     .addSearch(field: .author, value: "Hinton")
///     .sort(by: .submittedDate, order: .descending)
///     .maxResults(50)
///     .start(10) // For pagination
/// ```
///
/// ## Convenience Methods
///
/// For common searches, use the static convenience methods:
///
/// ```swift
/// let authorQuery = ArxivQuery.byAuthor("Geoffrey Hinton")
/// let categoryQuery = ArxivQuery.byCategory("cs.CV")
/// ```
///
/// All methods return a new `ArxivQuery` instance, allowing for method chaining
/// while maintaining immutability.
public struct ArxivQuery: Sendable {
    private var searchTerms: [String] = []
    private var start: Int = 0
    private var maxResults: Int = 10
    private var sortBy: SortBy = .relevance
    private var sortOrder: SortOrder = .descending
    
    /// Initialize a new query builder
    public init() {}
    
    /// Add a search term for a specific field
    /// - Parameters:
    ///   - field: The field to search in
    ///   - value: The search term
    /// - Returns: A new ArxivQuery with the search term added
    public func addSearch(field: QueryField, value: String) -> ArxivQuery {
        var newQuery = self
        // Don't encode here - URLComponents will handle encoding
        newQuery.searchTerms.append("\(field.rawValue):\(value)")
        return newQuery
    }
    
    /// Add a general search term (searches all fields)
    /// - Parameter value: The search term
    /// - Returns: A new ArxivQuery with the search term added
    public func addSearch(_ value: String) -> ArxivQuery {
        return addSearch(field: .all, value: value)
    }
    
    /// Set the starting index for results (for pagination)
    /// - Parameter start: The starting index (0-based)
    /// - Returns: A new ArxivQuery with the start index set
    public func start(_ start: Int) -> ArxivQuery {
        var newQuery = self
        newQuery.start = max(0, start)
        return newQuery
    }
    
    /// Set the maximum number of results to return
    /// - Parameter maxResults: The maximum number of results (1-2000)
    /// - Returns: A new ArxivQuery with the max results set
    public func maxResults(_ maxResults: Int) -> ArxivQuery {
        var newQuery = self
        newQuery.maxResults = min(max(1, maxResults), 2000)
        return newQuery
    }
    
    /// Set the sort criteria
    /// - Parameters:
    ///   - by: What to sort by
    ///   - order: The sort order
    /// - Returns: A new ArxivQuery with the sort criteria set
    public func sort(by: SortBy, order: SortOrder = .descending) -> ArxivQuery {
        var newQuery = self
        newQuery.sortBy = by
        newQuery.sortOrder = order
        return newQuery
    }
    
    /// Build the URL query string for the arXiv API
    /// - Returns: The complete URL string for the API request
    internal func buildURLString() -> String {
        let baseURL = "https://export.arxiv.org/api/query"
        var components = URLComponents(string: baseURL)!
        
        var queryItems: [URLQueryItem] = []
        
        // Add search query
        if !searchTerms.isEmpty {
            let searchQuery = searchTerms.joined(separator: "+AND+")
            queryItems.append(URLQueryItem(name: "search_query", value: searchQuery))
        } else {
            // Default to search all if no specific terms
            queryItems.append(URLQueryItem(name: "search_query", value: "all:*"))
        }
        
        // Add pagination
        queryItems.append(URLQueryItem(name: "start", value: String(start)))
        queryItems.append(URLQueryItem(name: "max_results", value: String(maxResults)))
        
        // Add sorting
        queryItems.append(URLQueryItem(name: "sortBy", value: sortBy.rawValue))
        queryItems.append(URLQueryItem(name: "sortOrder", value: sortOrder.rawValue))
        
        components.queryItems = queryItems
        
        return components.url?.absoluteString ?? baseURL
    }
}

// MARK: - Convenience methods for common queries

public extension ArxivQuery {
    /// Search for papers by a specific author
    /// - Parameter author: The author name to search for
    /// - Returns: A new ArxivQuery configured to search by author
    static func byAuthor(_ author: String) -> ArxivQuery {
        return ArxivQuery().addSearch(field: .author, value: author)
    }
    
    /// Search for papers by title
    /// - Parameter title: The title to search for
    /// - Returns: A new ArxivQuery configured to search by title
    static func byTitle(_ title: String) -> ArxivQuery {
        return ArxivQuery().addSearch(field: .title, value: title)
    }
    
    /// Search for papers in a specific category
    /// - Parameter category: The arXiv category (e.g., "cs.AI", "math.NT")
    /// - Returns: A new ArxivQuery configured to search by category
    static func byCategory(_ category: String) -> ArxivQuery {
        return ArxivQuery().addSearch(field: .category, value: category)
    }
    
    /// Search for papers containing specific terms in the abstract
    /// - Parameter abstract: The terms to search for in abstracts
    /// - Returns: A new ArxivQuery configured to search abstracts
    static func byAbstract(_ abstract: String) -> ArxivQuery {
        return ArxivQuery().addSearch(field: .abstract, value: abstract)
    }
} 