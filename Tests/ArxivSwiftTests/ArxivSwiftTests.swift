import Testing
@testable import ArxivSwift

@Suite("ArxivSwift Integration Tests")
struct ArxivSwiftTests {
    
    @Test("Library imports and basic functionality")
    func libraryImportsAndBasicFunctionality() async throws {
        // Test that we can create basic objects from the library
        _ = ArxivClient()
        let query = ArxivQuery()
        
        // Verify basic query building works
        let urlString = query.buildURLString()
        #expect(urlString.contains("search_query=all:*"))
        
        // Test that we can create model objects
        let author = ArxivAuthor(name: "Test Author")
        #expect(author.name == "Test Author")
        
        let category = ArxivCategory(term: "cs.AI")
        #expect(category.term == "cs.AI")
    }
}
