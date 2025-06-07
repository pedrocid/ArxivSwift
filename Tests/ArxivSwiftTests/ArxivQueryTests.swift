import XCTest
@testable import ArxivSwift

final class ArxivQueryTests: XCTestCase {
    
    func testBasicQueryBuilder() {
        let query = ArxivQuery()
        let urlString = query.buildURLString()
        
        XCTAssertTrue(urlString.contains("search_query=all:*"))
        XCTAssertTrue(urlString.contains("start=0"))
        XCTAssertTrue(urlString.contains("max_results=10"))
        XCTAssertTrue(urlString.contains("sortBy=relevance"))
        XCTAssertTrue(urlString.contains("sortOrder=descending"))
    }
    
    func testSearchByField() {
        let query = ArxivQuery()
            .addSearch(field: .title, value: "quantum computing")
        
        let urlString = query.buildURLString()
        XCTAssertTrue(urlString.contains("search_query=ti:quantum%20computing"))
    }
    
    func testMultipleSearchTerms() {
        let query = ArxivQuery()
            .addSearch(field: .title, value: "quantum")
            .addSearch(field: .author, value: "Einstein")
        
        let urlString = query.buildURLString()
        XCTAssertTrue(urlString.contains("ti:quantum+AND+au:Einstein"))
    }
    
    func testPagination() {
        let query = ArxivQuery()
            .start(20)
            .maxResults(50)
        
        let urlString = query.buildURLString()
        XCTAssertTrue(urlString.contains("start=20"))
        XCTAssertTrue(urlString.contains("max_results=50"))
    }
    
    func testSorting() {
        let query = ArxivQuery()
            .sort(by: .submittedDate, order: .ascending)
        
        let urlString = query.buildURLString()
        XCTAssertTrue(urlString.contains("sortBy=submittedDate"))
        XCTAssertTrue(urlString.contains("sortOrder=ascending"))
    }
    
    func testMaxResultsBounds() {
        // Test lower bound
        let queryLow = ArxivQuery().maxResults(-5)
        let urlStringLow = queryLow.buildURLString()
        XCTAssertTrue(urlStringLow.contains("max_results=1"))
        
        // Test upper bound
        let queryHigh = ArxivQuery().maxResults(5000)
        let urlStringHigh = queryHigh.buildURLString()
        XCTAssertTrue(urlStringHigh.contains("max_results=2000"))
    }
    
    func testStartBounds() {
        let query = ArxivQuery().start(-10)
        let urlString = query.buildURLString()
        XCTAssertTrue(urlString.contains("start=0"))
    }
    
    func testConvenienceMethods() {
        // Test byAuthor
        let authorQuery = ArxivQuery.byAuthor("John Doe")
        let authorURL = authorQuery.buildURLString()
        XCTAssertTrue(authorURL.contains("au:John%20Doe"))
        
        // Test byTitle
        let titleQuery = ArxivQuery.byTitle("Machine Learning")
        let titleURL = titleQuery.buildURLString()
        XCTAssertTrue(titleURL.contains("ti:Machine%20Learning"))
        
        // Test byCategory
        let categoryQuery = ArxivQuery.byCategory("cs.AI")
        let categoryURL = categoryQuery.buildURLString()
        XCTAssertTrue(categoryURL.contains("cat:cs.AI"))
        
        // Test byAbstract
        let abstractQuery = ArxivQuery.byAbstract("neural networks")
        let abstractURL = abstractQuery.buildURLString()
        XCTAssertTrue(abstractURL.contains("abs:neural%20networks"))
    }
    
    func testChainedBuilderPattern() {
        let query = ArxivQuery()
            .addSearch(field: .category, value: "cs.AI")
            .addSearch(field: .title, value: "deep learning")
            .start(10)
            .maxResults(25)
            .sort(by: .lastUpdatedDate, order: .ascending)
        
        let urlString = query.buildURLString()
        
        XCTAssertTrue(urlString.contains("cat:cs.AI+AND+ti:deep%20learning"))
        XCTAssertTrue(urlString.contains("start=10"))
        XCTAssertTrue(urlString.contains("max_results=25"))
        XCTAssertTrue(urlString.contains("sortBy=lastUpdatedDate"))
        XCTAssertTrue(urlString.contains("sortOrder=ascending"))
    }
    
    func testGeneralSearch() {
        let query = ArxivQuery().addSearch("machine learning")
        let urlString = query.buildURLString()
        XCTAssertTrue(urlString.contains("all:machine%20learning"))
    }
    
    func testEnumCases() {
        // Test all SortBy cases
        XCTAssertEqual(SortBy.relevance.rawValue, "relevance")
        XCTAssertEqual(SortBy.lastUpdatedDate.rawValue, "lastUpdatedDate")
        XCTAssertEqual(SortBy.submittedDate.rawValue, "submittedDate")
        
        // Test all SortOrder cases
        XCTAssertEqual(SortOrder.ascending.rawValue, "ascending")
        XCTAssertEqual(SortOrder.descending.rawValue, "descending")
        
        // Test QueryField cases
        XCTAssertEqual(QueryField.title.rawValue, "ti")
        XCTAssertEqual(QueryField.author.rawValue, "au")
        XCTAssertEqual(QueryField.abstract.rawValue, "abs")
        XCTAssertEqual(QueryField.category.rawValue, "cat")
        XCTAssertEqual(QueryField.all.rawValue, "all")
    }
} 