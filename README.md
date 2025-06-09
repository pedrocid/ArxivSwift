![ArxivSwift Header](assets/header-image.png)

# ArxivSwift

A modern Swift API client for arXiv.org with async/await support.

## Description

ArxivSwift is a clean, simple-to-use Swift package that provides a modern interface for querying the arXiv API. Built with Swift's latest concurrency features (`async/await`), it offers type-safe query building and comprehensive data models for working with academic papers from arXiv.

## Features

- ✅ **Modern Swift Concurrency**: Full `async/await` support
- ✅ **Type-Safe Query Building**: Fluent API with builder pattern
- ✅ **Comprehensive Data Models**: Rich models for papers, authors, categories, and links
- ✅ **Error Handling**: Detailed error types with recovery suggestions
- ✅ **XML Parsing**: Robust parsing of arXiv's Atom feed responses
- ✅ **Convenience Methods**: Easy-to-use search functions for common queries
- ✅ **Well Tested**: Comprehensive unit and integration tests
- ✅ **Documentation**: Full DocC documentation for all public APIs

## Requirements

- iOS 15.0+ / macOS 12.0+ / tvOS 15.0+ / watchOS 8.0+
- Swift 5.9+
- Xcode 15.0+

## Installation

### Swift Package Manager

Add ArxivSwift to your project using Xcode:

1. In Xcode, go to **File** → **Add Package Dependencies**
2. Enter the repository URL: `https://github.com/pedrocid/ArxivSwift.git`
3. Choose the version you want to use
4. Add the package to your target

Or add it to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/pedrocid/ArxivSwift.git", from: "1.0.0")
]
```

## Usage

### Basic Usage

```swift
import ArxivSwift

// Create a client
let client = ArxivClient()

// Or use the shared instance
let client = ArxivClient.shared

// Simple search
do {
    let entries = try await client.searchByTitle("neural networks", maxResults: 5)
    for entry in entries {
        print("\(entry.title) by \(entry.formattedAuthors)")
    }
} catch {
    print("Error: \(error)")
}
```

### Advanced Query Building

```swift
import ArxivSwift

let client = ArxivClient()

// Build a complex query
let query = ArxivQuery()
    .addSearch(field: .category, value: "cs.AI")
    .addSearch(field: .title, value: "transformer")
    .maxResults(10)
    .sort(by: .submittedDate, order: .descending)
    .start(0)

do {
    let entries = try await client.getEntries(for: query)
    print("Found \(entries.count) papers")
} catch {
    print("Search failed: \(error)")
}
```

### Search by Different Criteria

```swift
// Search by author
let papers = try await client.searchByAuthor("Yann LeCun", maxResults: 10)

// Search by category
let aiPapers = try await client.searchByCategory("cs.AI", maxResults: 20)

// Search by abstract content
let mlPapers = try await client.searchByAbstract("machine learning", maxResults: 15)

// Get latest papers
let latest = try await client.getLatestEntries(maxResults: 10)

// Get latest papers in a specific category
let latestAI = try await client.getLatestEntries(maxResults: 10, category: "cs.AI")

// Get a specific paper by ID
let paper = try await client.getEntry(by: "1706.03762") // "Attention Is All You Need"
```

### Working with Results

```swift
let entries = try await client.searchByCategory("cs.AI", maxResults: 5)

for entry in entries {
    print("Title: \(entry.title)")
    print("Authors: \(entry.formattedAuthors)")
    print("Abstract: \(entry.abstract)")
    print("Published: \(entry.published)")
    print("Categories: \(entry.categoryTerms.joined(separator: ", "))")
    
    // Access PDF and abstract URLs
    if let pdfURL = entry.pdfURL {
        print("PDF: \(pdfURL)")
    }
    
    if let abstractURL = entry.abstractURL {
        print("Abstract page: \(abstractURL)")
    }
    
    // Check if paper belongs to specific category
    if entry.belongsToCategory("cs.LG") {
        print("This paper is also in Machine Learning category")
    }
    
    print("---")
}
```

### Convenience Query Methods

```swift
// Quick searches using static methods
let authorPapers = ArxivQuery.byAuthor("Geoffrey Hinton")
let titlePapers = ArxivQuery.byTitle("deep learning")
let categoryPapers = ArxivQuery.byCategory("cs.CV")
let abstractPapers = ArxivQuery.byAbstract("computer vision")

// Chain with additional parameters
let complexQuery = ArxivQuery.byCategory("cs.AI")
    .maxResults(50)
    .sort(by: .lastUpdatedDate, order: .descending)

let results = try await client.getEntries(for: complexQuery)
```

### Error Handling

```swift
do {
    let entries = try await client.searchByTitle("quantum computing")
    // Process results
} catch ArxivError.networkError(let error) {
    print("Network error: \(error.localizedDescription)")
} catch ArxivError.rateLimited {
    print("Rate limited. Please wait before making more requests.")
} catch ArxivError.parsingError(let message) {
    print("Failed to parse response: \(message)")
} catch {
    print("Unexpected error: \(error)")
}
```

## API Reference

### ArxivClient

The main client for interacting with the arXiv API.

#### Methods

- `getEntries(for query: ArxivQuery) async throws -> [ArxivEntry]`
- `getEntry(by arxivId: String) async throws -> ArxivEntry`
- `searchByAuthor(_:maxResults:sortBy:) async throws -> [ArxivEntry]`
- `searchByTitle(_:maxResults:sortBy:) async throws -> [ArxivEntry]`
- `searchByCategory(_:maxResults:sortBy:) async throws -> [ArxivEntry]`
- `searchByAbstract(_:maxResults:sortBy:) async throws -> [ArxivEntry]`
- `getLatestEntries(maxResults:category:) async throws -> [ArxivEntry]`

### ArxivQuery

A builder for constructing arXiv API queries.

#### Methods

- `addSearch(field:value:) -> ArxivQuery`
- `addSearch(_:) -> ArxivQuery`
- `start(_:) -> ArxivQuery`
- `maxResults(_:) -> ArxivQuery`
- `sort(by:order:) -> ArxivQuery`

#### Static Methods

- `byAuthor(_:) -> ArxivQuery`
- `byTitle(_:) -> ArxivQuery`
- `byCategory(_:) -> ArxivQuery`
- `byAbstract(_:) -> ArxivQuery`

### Data Models

- **ArxivEntry**: Represents a complete arXiv paper
- **ArxivAuthor**: Represents a paper author
- **ArxivCategory**: Represents a subject category
- **ArxivLink**: Represents associated links (PDF, abstract page, etc.)
- **ArxivError**: Comprehensive error types with recovery suggestions

## Examples

Check out the test files for more comprehensive examples:
- `Tests/ArxivSwiftTests/ArxivClientTests.swift` - Integration tests with real API calls
- `Tests/ArxivSwiftTests/ArxivQueryTests.swift` - Query builder examples
- `Tests/ArxivSwiftTests/XMLParserTests.swift` - XML parsing examples

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built for the [arXiv](https://arxiv.org/) API
- Inspired by the need for modern Swift interfaces to academic APIs
- Thanks to the arXiv team for providing a free and open API

## Related Links

- [arXiv API Documentation](https://arxiv.org/help/api)
- [arXiv API User Manual](https://arxiv.org/help/api/user-manual)
- [Swift Package Manager](https://swift.org/package-manager/) 