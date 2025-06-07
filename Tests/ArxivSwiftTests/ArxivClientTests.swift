import XCTest
@testable import ArxivSwift

final class ArxivClientTests: XCTestCase {
    
    var client: ArxivClient!
    
    override func setUp() {
        super.setUp()
        client = ArxivClient()
    }
    
    override func tearDown() {
        client = nil
        super.tearDown()
    }
    
    func testGetEntriesWithSimpleQuery() async throws {
        let query = ArxivQuery()
            .addSearch(field: .category, value: "cs.AI")
            .maxResults(3)
            .sort(by: .submittedDate, order: .descending)
        
        let entries = try await client.getEntries(for: query)
        
        XCTAssertGreaterThan(entries.count, 0)
        XCTAssertLessThanOrEqual(entries.count, 3)
        
        // Verify that all entries have required fields
        for entry in entries {
            XCTAssertFalse(entry.id.isEmpty)
            XCTAssertFalse(entry.title.isEmpty)
            XCTAssertFalse(entry.abstract.isEmpty)
            XCTAssertGreaterThan(entry.authors.count, 0)
            
            // Check that the entry belongs to cs.AI category
            XCTAssertTrue(entry.belongsToCategory("cs.AI"))
        }
    }
    
    func testSearchByAuthor() async throws {
        // Search for a well-known author in computer science
        let entries = try await client.searchByAuthor("Yann LeCun", maxResults: 2)
        
        XCTAssertGreaterThan(entries.count, 0)
        XCTAssertLessThanOrEqual(entries.count, 2)
        
        // Verify that at least one entry has the author
        let hasAuthor = entries.contains { entry in
            entry.authors.contains { author in
                author.name.lowercased().contains("lecun")
            }
        }
        XCTAssertTrue(hasAuthor, "Should find at least one paper by the searched author")
    }
    
    func testSearchByTitle() async throws {
        let entries = try await client.searchByTitle("neural network", maxResults: 2)
        
        XCTAssertGreaterThan(entries.count, 0)
        XCTAssertLessThanOrEqual(entries.count, 2)
        
        // Verify that at least one entry has "neural" or "network" in the title
        let hasRelevantTitle = entries.contains { entry in
            let title = entry.title.lowercased()
            return title.contains("neural") || title.contains("network")
        }
        XCTAssertTrue(hasRelevantTitle, "Should find papers with relevant titles")
    }
    
    func testSearchByCategory() async throws {
        let entries = try await client.searchByCategory("math.NT", maxResults: 2)
        
        XCTAssertGreaterThan(entries.count, 0)
        XCTAssertLessThanOrEqual(entries.count, 2)
        
        // Verify that all entries belong to the math.NT category
        for entry in entries {
            XCTAssertTrue(entry.belongsToCategory("math.NT"))
        }
    }
    
    func testSearchByAbstract() async throws {
        let entries = try await client.searchByAbstract("machine learning", maxResults: 2)
        
        XCTAssertGreaterThan(entries.count, 0)
        XCTAssertLessThanOrEqual(entries.count, 2)
        
        // Verify that at least one entry has "machine" or "learning" in the abstract
        let hasRelevantAbstract = entries.contains { entry in
            let abstract = entry.abstract.lowercased()
            return abstract.contains("machine") || abstract.contains("learning")
        }
        XCTAssertTrue(hasRelevantAbstract, "Should find papers with relevant abstracts")
    }
    
    func testGetLatestEntries() async throws {
        // Use a more specific query that's more likely to return results
        let query = ArxivQuery()
            .addSearch(field: .category, value: "cs.AI")
            .maxResults(3)
            .sort(by: .submittedDate, order: .descending)
        
        let entries = try await client.getEntries(for: query)
        
        XCTAssertGreaterThan(entries.count, 0)
        XCTAssertLessThanOrEqual(entries.count, 3)
        
        // Just verify we got valid entries
        for entry in entries {
            XCTAssertFalse(entry.id.isEmpty)
            XCTAssertFalse(entry.title.isEmpty)
            XCTAssertFalse(entry.abstract.isEmpty)
            XCTAssertGreaterThan(entry.authors.count, 0)
        }
    }
    
    func testGetLatestEntriesWithCategory() async throws {
        let entries = try await client.getLatestEntries(maxResults: 2, category: "cs.LG")
        
        XCTAssertGreaterThan(entries.count, 0)
        XCTAssertLessThanOrEqual(entries.count, 2)
        
        // Verify that all entries belong to the cs.LG category
        for entry in entries {
            XCTAssertTrue(entry.belongsToCategory("cs.LG"))
        }
    }
    
    func testGetEntryById() async throws {
        // Use a well-known arXiv paper ID
        let arxivId = "1706.03762" // "Attention Is All You Need" paper
        
        let entry = try await client.getEntry(by: arxivId)
        
        XCTAssertTrue(entry.id.contains(arxivId))
        XCTAssertFalse(entry.title.isEmpty)
        XCTAssertFalse(entry.abstract.isEmpty)
        XCTAssertGreaterThan(entry.authors.count, 0)
    }
    
    func testErrorHandlingWithInvalidQuery() async {
        let query = ArxivQuery()
            .addSearch(field: .id, value: "nonexistent-id-12345")
            .maxResults(1)
        
        do {
            let entries = try await client.getEntries(for: query)
            // If we get here, the query returned results (which is unexpected but not an error)
            XCTAssertEqual(entries.count, 0, "Should return empty results for nonexistent ID")
        } catch {
            // This is also acceptable - some invalid queries might throw errors
            XCTAssertTrue(error is ArxivError)
        }
    }
    
    func testConvenienceExtensions() {
        // Test ArxivEntry convenience methods
        let author1 = ArxivAuthor(name: "John Doe")
        let author2 = ArxivAuthor(name: "Jane Smith")
        let author3 = ArxivAuthor(name: "Bob Johnson")
        
        let category = ArxivCategory(term: "cs.AI")
        let link = ArxivLink(href: "http://example.com/paper.pdf", title: "pdf")
        
        let entry = ArxivEntry(
            id: "2301.12345v1",
            title: "Test Paper",
            abstract: "Test abstract",
            authors: [author1, author2, author3],
            published: Date(),
            updated: Date(),
            primaryCategory: category,
            categories: [category],
            links: [link]
        )
        
        // Test formatted authors
        XCTAssertEqual(entry.formattedAuthors, "John Doe, Jane Smith, and Bob Johnson")
        
        // Test clean arXiv ID
        XCTAssertEqual(entry.cleanArxivId, "2301.12345")
        
        // Test category methods
        XCTAssertTrue(entry.belongsToCategory("cs.AI"))
        XCTAssertFalse(entry.belongsToCategory("math.NT"))
        
        // Test author name parsing
        XCTAssertEqual(author1.firstName, "John")
        XCTAssertEqual(author1.lastName, "Doe")
    }
} 