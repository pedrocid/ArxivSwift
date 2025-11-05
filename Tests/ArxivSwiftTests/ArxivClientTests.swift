import Foundation
#if os(Linux)
import FoundationNetworking
#endif
import Testing
@testable import ArxivSwift

@Suite("ArxivClient Tests")
struct ArxivClientTests {

    private let sampleFeedXML = """
    <?xml version="1.0" encoding="UTF-8"?>
    <feed xmlns="http://www.w3.org/2005/Atom">
      <entry>
        <id>http://arxiv.org/abs/1234.5678v1</id>
        <updated>2024-01-01T00:00:00Z</updated>
        <published>2024-01-01T00:00:00Z</published>
        <title>Sample Paper One</title>
        <summary>First abstract text.</summary>
        <author>
          <name>Alice Example</name>
        </author>
        <category term="cs.AI" scheme="http://arxiv.org/schemas/atom"/>
      </entry>
      <entry>
        <id>http://arxiv.org/abs/2345.6789v2</id>
        <updated>2024-01-02T12:30:00Z</updated>
        <published>2024-01-02T12:30:00Z</published>
        <title>Sample Paper Two</title>
        <summary>Second abstract text.</summary>
        <author>
          <name>Bob Example</name>
        </author>
        <category term="cs.AI" scheme="http://arxiv.org/schemas/atom"/>
        <category term="stat.ML" scheme="http://arxiv.org/schemas/atom"/>
      </entry>
    </feed>
    """

    private let singleEntryXML = """
    <?xml version="1.0" encoding="UTF-8"?>
    <feed xmlns="http://www.w3.org/2005/Atom">
      <entry>
        <id>http://arxiv.org/abs/9999.0001v1</id>
        <updated>2024-02-10T08:00:00Z</updated>
        <published>2024-02-10T08:00:00Z</published>
        <title>Attention Still Matters</title>
        <summary>Revisiting attention mechanisms.</summary>
        <author>
          <name>Casey Example</name>
        </author>
        <category term="cs.CL" scheme="http://arxiv.org/schemas/atom"/>
      </entry>
    </feed>
    """

    @Test("Get entries parses feed without network access")
    func getEntriesParsesFeed() async throws {
        let data = try #require(sampleFeedXML.data(using: .utf8))
        var capturedURL: URL?

        let query = ArxivQuery()
            .addSearch(field: .category, value: "cs.AI")
            .maxResults(2)
            .sort(by: .submittedDate, order: .descending)

        let expectedURL = query.buildURLString()
        let client = makeClient()
        MockURLProtocol.stub(
            urlString: expectedURL,
            statusCode: 200,
            headers: ["Content-Type": "application/atom+xml"],
            data: data
        ) { request in
            capturedURL = request.url
        }

        let entries = try await client.getEntries(for: query)

        #expect(entries.count == 2)
        #expect(entries[0].id == "1234.5678v1")
        #expect(entries[0].authors.first?.name == "Alice Example")
        #expect(entries[1].categories.map(\.term) == ["cs.AI", "stat.ML"])
        #expect(capturedURL?.absoluteString.contains("search_query=cat:cs.AI") == true)
        #expect(capturedURL?.absoluteString.contains("max_results=2") == true)
    }

    @Test("HTTP errors are surfaced as ArxivError")
    func getEntriesHandlesHTTPError() async {
        let query = ArxivQuery().addSearch(field: .all, value: "test")
        let expectedURL = query.buildURLString()
        var capturedURL: URL?
        let client = makeClient()
        MockURLProtocol.stub(
            urlString: expectedURL,
            statusCode: 500,
            data: Data("Server Error".utf8)
        ) { request in
            capturedURL = request.url
        }

        do {
            _ = try await client.getEntries(for: query)
            Issue.record("Expected getEntries to throw for HTTP 500")
        } catch let error as ArxivError {
            if case .httpError(let code) = error {
                #expect(code == 500)
            } else {
                Issue.record("Expected httpError, got \(error)")
            }
        } catch {
            Issue.record("Expected ArxivError, got \(error)")
        }

        #expect(capturedURL?.absoluteString == expectedURL)
    }

    @Test("Empty responses surface noData error")
    func getEntriesHandlesEmptyResponse() async {
        let query = ArxivQuery().start(5)
        let expectedURL = query.buildURLString()
        var capturedURL: URL?
        let client = makeClient()
        MockURLProtocol.stub(
            urlString: expectedURL,
            statusCode: 200,
            data: Data()
        ) { request in
            capturedURL = request.url
        }

        do {
            _ = try await client.getEntries(for: query)
            Issue.record("Expected getEntries to throw for empty data")
        } catch let error as ArxivError {
            #expect(error == .noData)
        } catch {
            Issue.record("Expected ArxivError.noData, got \(error)")
        }

        #expect(capturedURL?.absoluteString == expectedURL)
    }

    @Test("Invalid XML surfaces parsing error")
    func getEntriesHandlesInvalidXML() async {
        let query = ArxivQuery().start(10)
        let expectedURL = query.buildURLString()
        var capturedURL: URL?
        let client = makeClient()
        MockURLProtocol.stub(
            urlString: expectedURL,
            statusCode: 200,
            data: Data("not xml".utf8)
        ) { request in
            capturedURL = request.url
        }

        do {
            _ = try await client.getEntries(for: query)
            Issue.record("Expected getEntries to throw for invalid XML")
        } catch let error as ArxivError {
            if case .parsingError = error {
                // Expected path
            } else {
                Issue.record("Expected parsingError, got \(error)")
            }
        } catch {
            Issue.record("Expected ArxivError.parsingError, got \(error)")
        }

        #expect(capturedURL?.absoluteString == expectedURL)
    }

    @Test("getEntry(by:) returns the first parsed entry")
    func getEntryById() async throws {
        let data = try #require(singleEntryXML.data(using: .utf8))
        var capturedURL: URL?

        let queryURL = ArxivQuery().addSearch(field: .id, value: "9999.0001").maxResults(1).buildURLString()
        let client = makeClient()
        MockURLProtocol.stub(
            urlString: queryURL,
            statusCode: 200,
            data: data
        ) { request in
            capturedURL = request.url
        }

        let entry = try await client.getEntry(by: "9999.0001")

        #expect(entry.id == "9999.0001v1")
        #expect(entry.title == "Attention Still Matters")
        #expect(entry.authors.first?.name == "Casey Example")
        #expect(capturedURL?.absoluteString.contains("search_query=id:9999.0001") == true)
        #expect(capturedURL?.absoluteString.contains("max_results=1") == true)
    }

    @Test("Convenience extensions")
    func convenienceExtensions() {
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

        #expect(entry.formattedAuthors == "John Doe, Jane Smith, and Bob Johnson")
        #expect(entry.cleanArxivId == "2301.12345")
        #expect(entry.belongsToCategory("cs.AI"))
        #expect(!entry.belongsToCategory("math.NT"))
        #expect(author1.firstName == "John")
        #expect(author1.lastName == "Doe")
    }

    // MARK: - Helpers

    private func makeClient() -> ArxivClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        return ArxivClient(session: session)
    }
}

private final class MockURLProtocol: URLProtocol {
    private struct Stub {
        let response: HTTPURLResponse
        let data: Data
        let observer: ((URLRequest) -> Void)?
    }

    nonisolated(unsafe) private static var stubs: [String: Stub] = [:]

    static func stub(
        urlString: String,
        statusCode: Int,
        headers: [String: String]? = nil,
        data: Data,
        observer: ((URLRequest) -> Void)? = nil
    ) {
        guard let url = URL(string: urlString) else { return }
        let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: headers)!
        stubs[urlString] = Stub(response: response, data: data, observer: observer)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let urlString = request.url?.absoluteString,
              let stub = Self.stubs.removeValue(forKey: urlString) else {
            client?.urlProtocol(self, didFailWithError: URLError(.fileDoesNotExist))
            return
        }

        stub.observer?(request)

        client?.urlProtocol(self, didReceive: stub.response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
