import Foundation

/// Enum for sorting results from the arXiv API
public enum SortBy: String, CaseIterable {
    case relevance = "relevance"
    case lastUpdatedDate = "lastUpdatedDate"
    case submittedDate = "submittedDate"
}

/// Enum for sort order
public enum SortOrder: String, CaseIterable {
    case ascending = "ascending"
    case descending = "descending"
}

/// Enum for query fields that can be searched
public enum QueryField: String, CaseIterable {
    case title = "ti"
    case author = "au"
    case abstract = "abs"
    case comment = "co"
    case journalReference = "jr"
    case category = "cat"
    case reportNumber = "rn"
    case id = "id"
    case all = "all"
}

/// A builder for constructing arXiv API queries
public struct ArxivQuery {
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
        let baseURL = "http://export.arxiv.org/api/query"
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