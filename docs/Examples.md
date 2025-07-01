# ArxivSwift Examples

This document provides comprehensive examples of how to use ArxivSwift for various common tasks.

## Table of Contents

- [Basic Usage](#basic-usage)
- [Search Examples](#search-examples)
- [Advanced Queries](#advanced-queries)
- [Working with Results](#working-with-results)
- [Error Handling](#error-handling)
- [Pagination](#pagination)
- [Real-World Use Cases](#real-world-use-cases)

## Basic Usage

### Simple Paper Search

```swift
import ArxivSwift

let client = ArxivClient()

// Search for papers about "neural networks"
do {
    let papers = try await client.searchByTitle("neural networks", maxResults: 10)
    
    for paper in papers {
        print("📄 \(paper.title)")
        print("👤 \(paper.formattedAuthors)")
        print("📅 \(paper.published)")
        print("🔗 \(paper.pdfURL ?? "No PDF available")")
        print("---")
    }
} catch {
    print("Error searching papers: \(error)")
}
```

### Using the Shared Client

```swift
import ArxivSwift

// Use the shared client instance for convenience
let papers = try await ArxivClient.shared.searchByCategory("cs.AI", maxResults: 5)
```

## Search Examples

### Search by Author

```swift
// Find papers by a specific author
let hintonPapers = try await client.searchByAuthor("Geoffrey Hinton", maxResults: 20)

// Search with custom sorting
let recentHintonPapers = try await client.searchByAuthor(
    "Geoffrey Hinton",
    maxResults: 10,
    sortBy: .submittedDate
)
```

### Search by Category

```swift
// Computer Science - Artificial Intelligence
let aiPapers = try await client.searchByCategory("cs.AI", maxResults: 15)

// Mathematics - Number Theory
let mathPapers = try await client.searchByCategory("math.NT", maxResults: 10)

// Physics - High Energy Physics
let physicsPapers = try await client.searchByCategory("hep-th", maxResults: 5)
```

### Search by Abstract Content

```swift
// Find papers about specific techniques
let transformerPapers = try await client.searchByAbstract("transformer", maxResults: 25)

// Search for methodology papers
let surveyPapers = try await client.searchByAbstract("survey review", maxResults: 10)
```

### Get Latest Papers

```swift
// Get the most recent papers across all categories
let latestPapers = try await client.getLatestEntries(maxResults: 20)

// Get latest papers in a specific category
let latestAI = try await client.getLatestEntries(maxResults: 15, category: "cs.LG")
```

## Advanced Queries

### Complex Multi-Field Search

```swift
// Build a complex query with multiple criteria
let complexQuery = ArxivQuery()
    .addSearch(field: .category, value: "cs.CV")  // Computer Vision
    .addSearch(field: .title, value: "detection") // Title contains "detection"
    .addSearch(field: .abstract, value: "deep learning") // Abstract mentions deep learning
    .sort(by: .submittedDate, order: .descending)
    .maxResults(30)

let results = try await client.getEntries(for: complexQuery)
```

### Author and Institution Search

```swift
// Search for papers by multiple criteria
let query = ArxivQuery()
    .addSearch(field: .author, value: "LeCun")
    .addSearch(field: .category, value: "cs.LG")
    .sort(by: .lastUpdatedDate, order: .descending)
    .maxResults(15)

let lecunMLPapers = try await client.getEntries(for: query)
```

### Boolean Search Operations

```swift
// Note: arXiv API supports AND operations by default when using multiple search terms
let booleanQuery = ArxivQuery()
    .addSearch(field: .title, value: "neural AND network")  // Title must contain both words
    .addSearch(field: .abstract, value: "reinforcement learning")
    .maxResults(20)

let results = try await client.getEntries(for: booleanQuery)
```

### Time-Based Searches

```swift
// Get papers from the last month (approximately)
let recentQuery = ArxivQuery()
    .addSearch(field: .category, value: "cs.AI")
    .sort(by: .submittedDate, order: .descending)
    .maxResults(100)  // Get more results to filter by date

let recentPapers = try await client.getEntries(for: recentQuery)

// Filter papers from the last 30 days
let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
let lastMonthPapers = recentPapers.filter { $0.published >= thirtyDaysAgo }
```

## Working with Results

### Extracting Paper Information

```swift
let papers = try await client.searchByCategory("cs.AI", maxResults: 5)

for paper in papers {
    // Basic information
    print("Title: \(paper.title)")
    print("ID: \(paper.cleanArxivId)")
    print("Authors: \(paper.formattedAuthors)")
    
    // Dates
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    print("Published: \(formatter.string(from: paper.published))")
    print("Updated: \(formatter.string(from: paper.updated))")
    
    // Categories
    print("Primary Category: \(paper.primaryCategoryTerm ?? "Unknown")")
    print("All Categories: \(paper.categoryTerms.joined(separator: ", "))")
    
    // Links
    if let pdfURL = paper.pdfURL {
        print("PDF: \(pdfURL)")
    }
    
    if let abstractURL = paper.abstractURL {
        print("Abstract: \(abstractURL)")
    }
    
    // Optional fields
    if let comment = paper.comment {
        print("Comment: \(comment)")
    }
    
    if let journal = paper.journalReference {
        print("Journal: \(journal)")
    }
    
    if let doi = paper.doi {
        print("DOI: \(doi)")
    }
    
    print("---")
}
```

### Filtering and Processing Results

```swift
let papers = try await client.searchByAbstract("machine learning", maxResults: 50)

// Filter papers by category
let deepLearningPapers = papers.filter { paper in
    paper.belongsToCategory("cs.LG") || paper.belongsToCategory("cs.AI")
}

// Find papers with specific authors
let collaborations = papers.filter { paper in
    paper.authors.count > 5  // Papers with many authors
}

// Extract unique authors
let allAuthors = papers.flatMap { $0.authors }
let uniqueAuthors = Array(Set(allAuthors.map { $0.name })).sorted()
print("Unique authors: \(uniqueAuthors.joined(separator: ", "))")

// Group papers by primary category
let papersByCategory = Dictionary(grouping: papers) { paper in
    paper.primaryCategoryTerm ?? "Unknown"
}

for (category, categoryPapers) in papersByCategory {
    print("\(category): \(categoryPapers.count) papers")
}
```

## Error Handling

### Comprehensive Error Handling

```swift
import ArxivSwift

func searchPapersWithErrorHandling() async {
    do {
        let papers = try await ArxivClient.shared.searchByTitle("quantum computing")
        
        // Process successful results
        print("Found \(papers.count) papers")
        
    } catch ArxivError.networkError(let underlyingError) {
        print("Network error occurred: \(underlyingError.localizedDescription)")
        // Handle network issues - maybe retry with exponential backoff
        
    } catch ArxivError.rateLimited {
        print("Rate limited by arXiv API")
        // Wait before retrying
        try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
        
    } catch ArxivError.parsingError(let message) {
        print("Failed to parse response: \(message)")
        // This might indicate an API change or temporary issue
        
    } catch ArxivError.invalidQuery(let message) {
        print("Invalid query: \(message)")
        // Fix the query parameters
        
    } catch ArxivError.timeout {
        print("Request timed out")
        // Retry with a smaller query or check connection
        
    } catch {
        print("Unexpected error: \(error)")
        // Handle any other errors
    }
}
```

### Retry Logic

```swift
func searchWithRetry<T>(
    maxRetries: Int = 3,
    delay: TimeInterval = 1.0,
    operation: () async throws -> T
) async throws -> T {
    var lastError: Error?
    
    for attempt in 1...maxRetries {
        do {
            return try await operation()
        } catch ArxivError.rateLimited {
            // Wait longer for rate limiting
            let backoffDelay = delay * Double(attempt * 2)
            try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
            lastError = ArxivError.rateLimited
        } catch ArxivError.networkError {
            // Exponential backoff for network errors
            let backoffDelay = delay * Double(attempt)
            try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
            lastError = ArxivError.networkError(NSError(domain: "Retry", code: 0))
        } catch {
            // Don't retry for other errors
            throw error
        }
    }
    
    throw lastError ?? ArxivError.unknown("Max retries exceeded")
}

// Usage
let papers = try await searchWithRetry {
    try await ArxivClient.shared.searchByCategory("cs.AI", maxResults: 20)
}
```

## Pagination

### Basic Pagination

```swift
func fetchAllPapers(in category: String, maxTotal: Int = 100) async throws -> [ArxivEntry] {
    let pageSize = 20
    var allPapers: [ArxivEntry] = []
    var startIndex = 0
    
    while allPapers.count < maxTotal {
        let query = ArxivQuery.byCategory(category)
            .maxResults(pageSize)
            .start(startIndex)
            .sort(by: .submittedDate, order: .descending)
        
        let papers = try await ArxivClient.shared.getEntries(for: query)
        
        if papers.isEmpty {
            break // No more results
        }
        
        allPapers.append(contentsOf: papers)
        startIndex += pageSize
        
        // Add delay to be respectful to the API
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
    }
    
    return Array(allPapers.prefix(maxTotal))
}

// Usage
let allAIPapers = try await fetchAllPapers(in: "cs.AI", maxTotal: 200)
```

### Async Sequence for Pagination

```swift
struct ArxivPaginator: AsyncSequence {
    typealias Element = ArxivEntry
    
    private let query: ArxivQuery
    private let pageSize: Int
    private let client: ArxivClient
    
    init(query: ArxivQuery, pageSize: Int = 20, client: ArxivClient = .shared) {
        self.query = query
        self.pageSize = pageSize
        self.client = client
    }
    
    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(query: query, pageSize: pageSize, client: client)
    }
    
    struct AsyncIterator: AsyncIteratorProtocol {
        private let query: ArxivQuery
        private let pageSize: Int
        private let client: ArxivClient
        private var startIndex = 0
        private var currentPage: [ArxivEntry] = []
        private var currentPageIndex = 0
        
        init(query: ArxivQuery, pageSize: Int, client: ArxivClient) {
            self.query = query
            self.pageSize = pageSize
            self.client = client
        }
        
        mutating func next() async throws -> ArxivEntry? {
            if currentPageIndex >= currentPage.count {
                // Fetch next page
                let pagedQuery = query
                    .maxResults(pageSize)
                    .start(startIndex)
                
                currentPage = try await client.getEntries(for: pagedQuery)
                currentPageIndex = 0
                startIndex += pageSize
                
                if currentPage.isEmpty {
                    return nil // No more results
                }
            }
            
            defer { currentPageIndex += 1 }
            return currentPage[currentPageIndex]
        }
    }
}

// Usage
let paginator = ArxivPaginator(
    query: ArxivQuery.byCategory("cs.LG").sort(by: .submittedDate, order: .descending),
    pageSize: 10
)

var count = 0
for try await paper in paginator {
    print("\(count + 1). \(paper.title)")
    count += 1
    
    if count >= 50 { // Limit to first 50 papers
        break
    }
}
```

## Real-World Use Cases

### Building a Research Paper Recommendation System

```swift
class PaperRecommendationService {
    private let client = ArxivClient.shared
    
    func getRecommendations(for interests: [String], maxPapers: Int = 20) async throws -> [ArxivEntry] {
        var allPapers: [ArxivEntry] = []
        
        for interest in interests {
            let papers = try await client.searchByAbstract(interest, maxResults: maxPapers / interests.count)
            allPapers.append(contentsOf: papers)
        }
        
        // Remove duplicates based on arXiv ID
        let uniquePapers = Array(Set(allPapers.map { $0.cleanArxivId }))
            .compactMap { id in allPapers.first { $0.cleanArxivId == id } }
        
        // Sort by publication date (most recent first)
        return uniquePapers.sorted { $0.published > $1.published }
    }
}

// Usage
let recommender = PaperRecommendationService()
let interests = ["transformer", "attention mechanism", "natural language processing"]
let recommendations = try await recommender.getRecommendations(for: interests, maxPapers: 30)
```

### Author Collaboration Analysis

```swift
class CollaborationAnalyzer {
    private let client = ArxivClient.shared
    
    func analyzeAuthorCollaborations(author: String) async throws -> CollaborationReport {
        let papers = try await client.searchByAuthor(author, maxResults: 100)
        
        // Find co-authors
        var collaborators: [String: Int] = [:]
        var categories: [String: Int] = [:]
        
        for paper in papers {
            // Count collaborators
            for coAuthor in paper.authors {
                if coAuthor.name != author {
                    collaborators[coAuthor.name, default: 0] += 1
                }
            }
            
            // Count categories
            for category in paper.categoryTerms {
                categories[category, default: 0] += 1
            }
        }
        
        return CollaborationReport(
            totalPapers: papers.count,
            topCollaborators: collaborators.sorted { $0.value > $1.value }.prefix(10),
            researchAreas: categories.sorted { $0.value > $1.value }.prefix(5),
            timeSpan: (papers.map { $0.published }.min(), papers.map { $0.published }.max())
        )
    }
}

struct CollaborationReport {
    let totalPapers: Int
    let topCollaborators: ArraySlice<Dictionary<String, Int>.Element>
    let researchAreas: ArraySlice<Dictionary<String, Int>.Element>
    let timeSpan: (Date?, Date?)
}
```

### Conference Paper Tracker

```swift
class ConferencePaperTracker {
    private let client = ArxivClient.shared
    
    func trackConferencePapers(venues: [String]) async throws -> [String: [ArxivEntry]] {
        var venuesPapers: [String: [ArxivEntry]] = [:]
        
        for venue in venues {
            // Search for papers mentioning the conference
            let papers = try await client.searchByAbstract(venue, maxResults: 50)
            
            // Filter papers that likely belong to this venue
            let venuePapers = papers.filter { paper in
                paper.abstract.localizedCaseInsensitiveContains(venue) ||
                paper.comment?.localizedCaseInsensitiveContains(venue) == true ||
                paper.journalReference?.localizedCaseInsensitiveContains(venue) == true
            }
            
            venuesPapers[venue] = venuePapers.sorted { $0.published > $1.published }
        }
        
        return venuesPapers
    }
}

// Usage
let tracker = ConferencePaperTracker()
let venues = ["NIPS", "ICML", "ICLR", "NeurIPS"]
let venuePapers = try await tracker.trackConferencePapers(venues: venues)

for (venue, papers) in venuePapers {
    print("\n\(venue): \(papers.count) papers")
    for paper in papers.prefix(5) {
        print("  - \(paper.title)")
    }
}
```

These examples demonstrate the flexibility and power of ArxivSwift for building sophisticated research tools and applications. The library's async/await support makes it easy to build responsive applications that can handle multiple concurrent requests while respecting the arXiv API's rate limits.