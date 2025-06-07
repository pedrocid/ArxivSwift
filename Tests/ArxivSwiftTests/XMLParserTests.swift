import Testing
@testable import ArxivSwift

@Suite("XMLParser Tests")
struct XMLParserTests {
    
    @Test("XML parser with sample data")
    func xmlParserWithSampleData() throws {
        let sampleXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom">
          <link href="http://arxiv.org/api/query?search_query=all:electron&amp;id_list=&amp;start=0&amp;max_results=1" rel="self" type="application/atom+xml"/>
          <title type="html">ArXiv Query: search_query=all:electron&amp;id_list=&amp;start=0&amp;max_results=1</title>
          <id>http://arxiv.org/api/cHxbiOdZaP56ODnBPIenZhzg5f8</id>
          <updated>2013-05-29T00:00:00-04:00</updated>
          <opensearch:totalResults xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/">1000</opensearch:totalResults>
          <opensearch:startIndex xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/">0</opensearch:startIndex>
          <opensearch:itemsPerPage xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/">1</opensearch:itemsPerPage>
          <entry>
            <id>http://arxiv.org/abs/hep-ex/0307015v1</id>
            <updated>2003-07-07T13:46:39Z</updated>
            <published>2003-07-07T13:46:39Z</published>
            <title>Multi-Electron Production at High Transverse Momenta in ep Collisions at HERA</title>
            <summary>Multi-electron production is studied at high transverse momentum in positron-
        proton collisions using the H1 detector at HERA. The data correspond to an
        integrated luminosity of 115 pb^-1. Di-electron and tri-electron event samples
        are investigated. The results are compared with the Standard Model predictions
        using the DJANGOH Monte Carlo generator and show good agreement. The cross-section
        for inclusive isolated electron production is measured.</summary>
            <author>
              <name>H1 Collaboration</name>
            </author>
            <arxiv:doi xmlns:arxiv="http://arxiv.org/schemas/atom">10.1140/epjc/s2003-01326-x</arxiv:doi>
            <link href="http://arxiv.org/abs/hep-ex/0307015v1" rel="alternate" type="text/html"/>
            <link href="http://arxiv.org/pdf/hep-ex/0307015v1" rel="related" type="application/pdf" title="pdf"/>
            <arxiv:primary_category xmlns:arxiv="http://arxiv.org/schemas/atom" term="hep-ex" scheme="http://arxiv.org/schemas/atom"/>
            <category term="hep-ex" scheme="http://arxiv.org/schemas/atom"/>
            <category term="hep-ph" scheme="http://arxiv.org/schemas/atom"/>
          </entry>
        </feed>
        """
        
        let data = try #require(sampleXML.data(using: .utf8))
        let parser = ArxivXMLParserDelegate()
        
        let entries = try parser.parseEntries(from: data)
        
        #expect(entries.count == 1)
        
        let entry = entries[0]
        #expect(entry.id == "hep-ex/0307015v1")
        #expect(entry.title == "Multi-Electron Production at High Transverse Momenta in ep Collisions at HERA")
        #expect(entry.abstract.contains("Multi-electron production is studied"))
        #expect(entry.authors.count == 1)
        #expect(entry.authors[0].name == "H1 Collaboration")
        #expect(entry.doi == "10.1140/epjc/s2003-01326-x")
        #expect(entry.categories.count == 2)
        #expect(entry.categories[0].term == "hep-ex")
        #expect(entry.categories[1].term == "hep-ph")
        #expect(entry.primaryCategory?.term == "hep-ex")
        #expect(entry.links.count == 2)
    }
    
    @Test("XML parser with multiple entries")
    func xmlParserWithMultipleEntries() throws {
        let sampleXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom">
          <entry>
            <id>http://arxiv.org/abs/2301.12345v1</id>
            <updated>2023-01-29T18:59:59Z</updated>
            <published>2023-01-29T18:59:59Z</published>
            <title>First Paper Title</title>
            <summary>First paper abstract.</summary>
            <author>
              <name>John Doe</name>
            </author>
            <author>
              <name>Jane Smith</name>
            </author>
            <category term="cs.AI" scheme="http://arxiv.org/schemas/atom"/>
          </entry>
          <entry>
            <id>http://arxiv.org/abs/2301.54321v1</id>
            <updated>2023-01-30T10:30:00Z</updated>
            <published>2023-01-30T10:30:00Z</published>
            <title>Second Paper Title</title>
            <summary>Second paper abstract.</summary>
            <author>
              <name>Alice Johnson</name>
            </author>
            <category term="math.NT" scheme="http://arxiv.org/schemas/atom"/>
          </entry>
        </feed>
        """
        
        let data = try #require(sampleXML.data(using: .utf8))
        let parser = ArxivXMLParserDelegate()
        
        let entries = try parser.parseEntries(from: data)
        
        #expect(entries.count == 2)
        
        let firstEntry = entries[0]
        #expect(firstEntry.id == "2301.12345v1")
        #expect(firstEntry.title == "First Paper Title")
        #expect(firstEntry.authors.count == 2)
        #expect(firstEntry.authors[0].name == "John Doe")
        #expect(firstEntry.authors[1].name == "Jane Smith")
        
        let secondEntry = entries[1]
        #expect(secondEntry.id == "2301.54321v1")
        #expect(secondEntry.title == "Second Paper Title")
        #expect(secondEntry.authors.count == 1)
        #expect(secondEntry.authors[0].name == "Alice Johnson")
    }
    
    @Test("XML parser with invalid data")
    func xmlParserWithInvalidData() {
        let invalidXML = "This is not valid XML"
        let data = invalidXML.data(using: .utf8)!
        let parser = ArxivXMLParserDelegate()
        
        #expect(throws: (any Error).self) {
            try parser.parseEntries(from: data)
        }
        
        // More specific error checking
        do {
            _ = try parser.parseEntries(from: data)
            Issue.record("Expected parsing to throw an error")
        } catch {
            #expect(error is ArxivError)
            if case .parsingError = error as! ArxivError {
                // Expected error type
            } else {
                Issue.record("Expected parsing error, got \(error)")
            }
        }
    }
    
    @Test("Date parsing")
    func dateParsing() throws {
        let sampleXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom">
          <entry>
            <id>http://arxiv.org/abs/2301.12345v1</id>
            <updated>2023-01-29T18:59:59Z</updated>
            <published>2023-01-29T18:59:59Z</published>
            <title>Test Paper</title>
            <summary>Test abstract.</summary>
            <author>
              <name>Test Author</name>
            </author>
            <category term="cs.AI" scheme="http://arxiv.org/schemas/atom"/>
          </entry>
        </feed>
        """
        
        let data = try #require(sampleXML.data(using: .utf8))
        let parser = ArxivXMLParserDelegate()
        
        let entries = try parser.parseEntries(from: data)
        
        #expect(entries.count == 1)
        
        let entry = entries[0]
        
        // Create expected date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let expectedDate = try #require(dateFormatter.date(from: "2023-01-29T18:59:59Z"))
        
        #expect(entry.published == expectedDate)
        #expect(entry.updated == expectedDate)
    }
} 