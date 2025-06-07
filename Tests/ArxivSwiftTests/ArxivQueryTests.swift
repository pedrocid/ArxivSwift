import Testing
@testable import ArxivSwift

@Suite("ArxivQuery Tests")
struct ArxivQueryTests {
    
    @Test("Basic query builder")
    func basicQueryBuilder() {
        let query = ArxivQuery()
        let urlString = query.buildURLString()
        
        #expect(urlString.contains("search_query=all:*"))
        #expect(urlString.contains("start=0"))
        #expect(urlString.contains("max_results=10"))
        #expect(urlString.contains("sortBy=relevance"))
        #expect(urlString.contains("sortOrder=descending"))
    }
    
    @Test("Search by field")
    func searchByField() {
        let query = ArxivQuery()
            .addSearch(field: .title, value: "quantum computing")
        
        let urlString = query.buildURLString()
        #expect(urlString.contains("search_query=ti:quantum%20computing"))
    }
    
    @Test("Multiple search terms")
    func multipleSearchTerms() {
        let query = ArxivQuery()
            .addSearch(field: .title, value: "quantum")
            .addSearch(field: .author, value: "Einstein")
        
        let urlString = query.buildURLString()
        #expect(urlString.contains("ti:quantum+AND+au:Einstein"))
    }
    
    @Test("Pagination")
    func pagination() {
        let query = ArxivQuery()
            .start(20)
            .maxResults(50)
        
        let urlString = query.buildURLString()
        #expect(urlString.contains("start=20"))
        #expect(urlString.contains("max_results=50"))
    }
    
    @Test("Sorting")
    func sorting() {
        let query = ArxivQuery()
            .sort(by: .submittedDate, order: .ascending)
        
        let urlString = query.buildURLString()
        #expect(urlString.contains("sortBy=submittedDate"))
        #expect(urlString.contains("sortOrder=ascending"))
    }
    
    @Test("Max results bounds")
    func maxResultsBounds() {
        // Test lower bound
        let queryLow = ArxivQuery().maxResults(-5)
        let urlStringLow = queryLow.buildURLString()
        #expect(urlStringLow.contains("max_results=1"))
        
        // Test upper bound
        let queryHigh = ArxivQuery().maxResults(5000)
        let urlStringHigh = queryHigh.buildURLString()
        #expect(urlStringHigh.contains("max_results=2000"))
    }
    
    @Test("Start bounds")
    func startBounds() {
        let query = ArxivQuery().start(-10)
        let urlString = query.buildURLString()
        #expect(urlString.contains("start=0"))
    }
    
    @Test("Convenience methods")
    func convenienceMethods() {
        // Test byAuthor
        let authorQuery = ArxivQuery.byAuthor("John Doe")
        let authorURL = authorQuery.buildURLString()
        #expect(authorURL.contains("au:John%20Doe"))
        
        // Test byTitle
        let titleQuery = ArxivQuery.byTitle("Machine Learning")
        let titleURL = titleQuery.buildURLString()
        #expect(titleURL.contains("ti:Machine%20Learning"))
        
        // Test byCategory
        let categoryQuery = ArxivQuery.byCategory("cs.AI")
        let categoryURL = categoryQuery.buildURLString()
        #expect(categoryURL.contains("cat:cs.AI"))
        
        // Test byAbstract
        let abstractQuery = ArxivQuery.byAbstract("neural networks")
        let abstractURL = abstractQuery.buildURLString()
        #expect(abstractURL.contains("abs:neural%20networks"))
    }
    
    @Test("Chained builder pattern")
    func chainedBuilderPattern() {
        let query = ArxivQuery()
            .addSearch(field: .category, value: "cs.AI")
            .addSearch(field: .title, value: "deep learning")
            .start(10)
            .maxResults(25)
            .sort(by: .lastUpdatedDate, order: .ascending)
        
        let urlString = query.buildURLString()
        
        #expect(urlString.contains("cat:cs.AI+AND+ti:deep%20learning"))
        #expect(urlString.contains("start=10"))
        #expect(urlString.contains("max_results=25"))
        #expect(urlString.contains("sortBy=lastUpdatedDate"))
        #expect(urlString.contains("sortOrder=ascending"))
    }
    
    @Test("General search")
    func generalSearch() {
        let query = ArxivQuery().addSearch("machine learning")
        let urlString = query.buildURLString()
        #expect(urlString.contains("all:machine%20learning"))
    }
    
    @Test("Enum cases")
    func enumCases() {
        // Test all SortBy cases
        #expect(SortBy.relevance.rawValue == "relevance")
        #expect(SortBy.lastUpdatedDate.rawValue == "lastUpdatedDate")
        #expect(SortBy.submittedDate.rawValue == "submittedDate")
        
        // Test all SortOrder cases
        #expect(SortOrder.ascending.rawValue == "ascending")
        #expect(SortOrder.descending.rawValue == "descending")
        
        // Test QueryField cases
        #expect(QueryField.title.rawValue == "ti")
        #expect(QueryField.author.rawValue == "au")
        #expect(QueryField.abstract.rawValue == "abs")
        #expect(QueryField.category.rawValue == "cat")
        #expect(QueryField.all.rawValue == "all")
    }
} 