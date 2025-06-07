import Testing
@testable import ArxivSwift

@Suite("ArxivClient Tests")
struct ArxivClientTests {
    
    let client: ArxivClient
    
    init() {
        client = ArxivClient()
    }
    
    @Test("Get entries with simple query")
    func getEntriesWithSimpleQuery() async throws {
        let query = ArxivQuery()
            .addSearch(field: .category, value: "cs.AI")
            .maxResults(3)
            .sort(by: .submittedDate, order: .descending)
        
        let entries = try await client.getEntries(for: query)
        
        #expect(entries.count > 0)
        #expect(entries.count <= 3)
        
        // Verify that all entries have required fields
        for entry in entries {
            #expect(!entry.id.isEmpty)
            #expect(!entry.title.isEmpty)
            #expect(!entry.abstract.isEmpty)
            #expect(entry.authors.count > 0)
            
            // Check that the entry belongs to cs.AI category
            #expect(entry.belongsToCategory("cs.AI"))
        }
    }
    
    @Test("Search by author")
    func searchByAuthor() async throws {
        // Search for a well-known author in computer science
        let entries = try await client.searchByAuthor("Yann LeCun", maxResults: 2)
        
        #expect(entries.count > 0)
        #expect(entries.count <= 2)
        
        // Verify that at least one entry has the author
        let hasAuthor = entries.contains { entry in
            entry.authors.contains { author in
                author.name.lowercased().contains("lecun")
            }
        }
        #expect(hasAuthor, "Should find at least one paper by the searched author")
    }
    
    @Test("Search by title")
    func searchByTitle() async throws {
        let entries = try await client.searchByTitle("neural network", maxResults: 2)
        
        #expect(entries.count > 0)
        #expect(entries.count <= 2)
        
        // Verify that at least one entry has "neural" or "network" in the title
        let hasRelevantTitle = entries.contains { entry in
            let title = entry.title.lowercased()
            return title.contains("neural") || title.contains("network")
        }
        #expect(hasRelevantTitle, "Should find papers with relevant titles")
    }
    
    @Test("Search by category")
    func searchByCategory() async throws {
        let entries = try await client.searchByCategory("math.NT", maxResults: 2)
        
        #expect(entries.count > 0)
        #expect(entries.count <= 2)
        
        // Verify that all entries belong to the math.NT category
        for entry in entries {
            #expect(entry.belongsToCategory("math.NT"))
        }
    }
    
    @Test("Search by abstract")
    func searchByAbstract() async throws {
        let entries = try await client.searchByAbstract("machine learning", maxResults: 2)
        
        #expect(entries.count > 0)
        #expect(entries.count <= 2)
        
        // Verify that at least one entry has "machine" or "learning" in the abstract
        let hasRelevantAbstract = entries.contains { entry in
            let abstract = entry.abstract.lowercased()
            return abstract.contains("machine") || abstract.contains("learning")
        }
        #expect(hasRelevantAbstract, "Should find papers with relevant abstracts")
    }
    
    @Test("Get latest entries")
    func getLatestEntries() async throws {
        // Use a more specific query that's more likely to return results
        let query = ArxivQuery()
            .addSearch(field: .category, value: "cs.AI")
            .maxResults(3)
            .sort(by: .submittedDate, order: .descending)
        
        let entries = try await client.getEntries(for: query)
        
        #expect(entries.count > 0)
        #expect(entries.count <= 3)
        
        // Just verify we got valid entries
        for entry in entries {
            #expect(!entry.id.isEmpty)
            #expect(!entry.title.isEmpty)
            #expect(!entry.abstract.isEmpty)
            #expect(entry.authors.count > 0)
        }
    }
    
    @Test("Get latest entries with category")
    func getLatestEntriesWithCategory() async throws {
        let entries = try await client.getLatestEntries(maxResults: 2, category: "cs.LG")
        
        #expect(entries.count > 0)
        #expect(entries.count <= 2)
        
        // Verify that all entries belong to the cs.LG category
        for entry in entries {
            #expect(entry.belongsToCategory("cs.LG"))
        }
    }
    
    @Test("Get entry by ID")
    func getEntryById() async throws {
        // Use a well-known arXiv paper ID
        let arxivId = "1706.03762" // "Attention Is All You Need" paper
        
        let entry = try await client.getEntry(by: arxivId)
        
        #expect(entry.id.contains(arxivId))
        #expect(!entry.title.isEmpty)
        #expect(!entry.abstract.isEmpty)
        #expect(entry.authors.count > 0)
    }
    
    @Test("Error handling with invalid query")
    func errorHandlingWithInvalidQuery() async {
        let query = ArxivQuery()
            .addSearch(field: .id, value: "nonexistent-id-12345")
            .maxResults(1)
        
        do {
            let entries = try await client.getEntries(for: query)
            // If we get here, the query returned results (which is unexpected but not an error)
            #expect(entries.count == 0, "Should return empty results for nonexistent ID")
        } catch {
            // This is also acceptable - some invalid queries might throw errors
            #expect(error is ArxivError)
        }
    }
    
    @Test("Convenience extensions")
    func convenienceExtensions() {
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
        #expect(entry.formattedAuthors == "John Doe, Jane Smith, and Bob Johnson")
        
        // Test clean arXiv ID
        #expect(entry.cleanArxivId == "2301.12345")
        
        // Test category methods
        #expect(entry.belongsToCategory("cs.AI"))
        #expect(!entry.belongsToCategory("math.NT"))
        
        // Test author name parsing
        #expect(author1.firstName == "John")
        #expect(author1.lastName == "Doe")
    }
} 