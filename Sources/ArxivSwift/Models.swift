import Foundation

/// Represents an author of an arXiv paper
public struct ArxivAuthor: Codable, Equatable, Sendable {
    /// The author's name
    public let name: String
    
    /// Optional affiliation information
    public let affiliation: String?
    
    /// Initialize a new ArxivAuthor
    /// - Parameters:
    ///   - name: The author's name
    ///   - affiliation: Optional affiliation information
    public init(name: String, affiliation: String? = nil) {
        self.name = name
        self.affiliation = affiliation
    }
}

/// Represents a link associated with an arXiv entry
public struct ArxivLink: Codable, Equatable, Sendable{
    /// The URL of the link
    public let href: String
    
    /// The relationship type (e.g., "alternate", "related")
    public let rel: String?
    
    /// The MIME type of the linked resource
    public let type: String?
    
    /// Optional title for the link
    public let title: String?
    
    /// Initialize a new ArxivLink
    /// - Parameters:
    ///   - href: The URL of the link
    ///   - rel: The relationship type
    ///   - type: The MIME type
    ///   - title: Optional title
    public init(href: String, rel: String? = nil, type: String? = nil, title: String? = nil) {
        self.href = href
        self.rel = rel
        self.type = type
        self.title = title
    }
}

/// Represents a category classification for an arXiv paper
public struct ArxivCategory: Codable, Equatable, Sendable {
    /// The category term (e.g., "cs.AI", "math.NT")
    public let term: String
    
    /// The scheme/taxonomy this category belongs to
    public let scheme: String?
    
    /// Human-readable label for the category
    public let label: String?
    
    /// Initialize a new ArxivCategory
    /// - Parameters:
    ///   - term: The category term
    ///   - scheme: The scheme/taxonomy
    ///   - label: Human-readable label
    public init(term: String, scheme: String? = nil, label: String? = nil) {
        self.term = term
        self.scheme = scheme
        self.label = label
    }
}

/// Represents a complete arXiv paper entry
public struct ArxivEntry: Codable, Equatable, Sendable {
    /// The arXiv ID (e.g., "2301.12345v1")
    public let id: String
    
    /// The paper title
    public let title: String
    
    /// The paper abstract
    public let abstract: String
    
    /// List of authors
    public let authors: [ArxivAuthor]
    
    /// Publication date
    public let published: Date
    
    /// Last updated date
    public let updated: Date
    
    /// Primary category
    public let primaryCategory: ArxivCategory?
    
    /// All categories this paper belongs to
    public let categories: [ArxivCategory]
    
    /// Associated links (PDF, abstract page, etc.)
    public let links: [ArxivLink]
    
    /// Optional comment from the authors
    public let comment: String?
    
    /// Optional journal reference
    public let journalReference: String?
    
    /// Optional DOI
    public let doi: String?
    
    /// Optional report number
    public let reportNumber: String?
    
    /// Initialize a new ArxivEntry
    /// - Parameters:
    ///   - id: The arXiv ID
    ///   - title: The paper title
    ///   - abstract: The paper abstract
    ///   - authors: List of authors
    ///   - published: Publication date
    ///   - updated: Last updated date
    ///   - primaryCategory: Primary category
    ///   - categories: All categories
    ///   - links: Associated links
    ///   - comment: Optional comment
    ///   - journalReference: Optional journal reference
    ///   - doi: Optional DOI
    ///   - reportNumber: Optional report number
    public init(
        id: String,
        title: String,
        abstract: String,
        authors: [ArxivAuthor],
        published: Date,
        updated: Date,
        primaryCategory: ArxivCategory? = nil,
        categories: [ArxivCategory] = [],
        links: [ArxivLink] = [],
        comment: String? = nil,
        journalReference: String? = nil,
        doi: String? = nil,
        reportNumber: String? = nil
    ) {
        self.id = id
        self.title = title
        self.abstract = abstract
        self.authors = authors
        self.published = published
        self.updated = updated
        self.primaryCategory = primaryCategory
        self.categories = categories
        self.links = links
        self.comment = comment
        self.journalReference = journalReference
        self.doi = doi
        self.reportNumber = reportNumber
    }
}

// MARK: - Convenience Extensions

public extension ArxivEntry {
    /// Get the PDF download URL if available
    var pdfURL: String? {
        return links.first { $0.title?.lowercased().contains("pdf") == true }?.href
    }
    
    /// Get the abstract page URL if available
    var abstractURL: String? {
        return links.first { $0.rel == "alternate" && $0.type == "text/html" }?.href
    }
    
    /// Get a clean arXiv ID without version number
    var cleanArxivId: String {
        // Remove version number (e.g., "2301.12345v1" -> "2301.12345")
        if let vIndex = id.lastIndex(of: "v") {
            return String(id[..<vIndex])
        }
        return id
    }
    
    /// Get the primary category term as a string
    var primaryCategoryTerm: String? {
        return primaryCategory?.term
    }
    
    /// Get all category terms as an array of strings
    var categoryTerms: [String] {
        return categories.map { $0.term }
    }
    
    /// Check if this entry belongs to a specific category
    /// - Parameter category: The category term to check for
    /// - Returns: True if the entry belongs to the specified category
    func belongsToCategory(_ category: String) -> Bool {
        return categoryTerms.contains(category) || primaryCategoryTerm == category
    }
    
    /// Get a formatted author list as a string
    var formattedAuthors: String {
        switch authors.count {
        case 0:
            return "Unknown"
        case 1:
            return authors[0].name
        case 2:
            return "\(authors[0].name) and \(authors[1].name)"
        default:
            let firstAuthors = authors.prefix(authors.count - 1).map { $0.name }.joined(separator: ", ")
            return "\(firstAuthors), and \(authors.last!.name)"
        }
    }
}

public extension ArxivAuthor {
    /// Get the author's last name (assuming Western name format)
    var lastName: String {
        let components = name.components(separatedBy: " ")
        return components.last ?? name
    }
    
    /// Get the author's first name (assuming Western name format)
    var firstName: String {
        let components = name.components(separatedBy: " ")
        return components.first ?? name
    }
} 