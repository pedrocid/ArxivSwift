import Foundation
#if os(Linux)
import FoundationXML
#endif

/// XML parser delegate for parsing arXiv Atom feed responses
internal class ArxivXMLParserDelegate: NSObject, XMLParserDelegate {
    
    // MARK: - Properties
    
    private var entries: [ArxivEntry] = []
    private var currentEntry: ArxivEntryBuilder?
    private var currentElement: String = ""
    private var currentText: String = ""
    
    // Date formatters for parsing arXiv dates
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
    
    private let alternateDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
    
    // MARK: - Public Interface
    
    /// Parse XML data and return arXiv entries
    /// - Parameter data: The XML data to parse
    /// - Returns: Array of parsed ArxivEntry objects
    /// - Throws: ArxivError if parsing fails
    func parseEntries(from data: Data) throws -> [ArxivEntry] {
        entries.removeAll()
        currentEntry = nil
        
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        guard parser.parse() else {
            if let error = parser.parserError {
                throw ArxivError.parsingError("XML parsing failed: \(error.localizedDescription)")
            } else {
                throw ArxivError.parsingError("Unknown XML parsing error")
            }
        }
        
        return entries
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        currentText = ""
        
        switch elementName {
        case "entry":
            currentEntry = ArxivEntryBuilder()
            
        case "link":
            if let currentEntry = currentEntry {
                let link = ArxivLink(
                    href: attributeDict["href"] ?? "",
                    rel: attributeDict["rel"],
                    type: attributeDict["type"],
                    title: attributeDict["title"]
                )
                currentEntry.addLink(link)
            }
            
        case "category":
            if let currentEntry = currentEntry {
                let category = ArxivCategory(
                    term: attributeDict["term"] ?? "",
                    scheme: attributeDict["scheme"],
                    label: attributeDict["label"]
                )
                currentEntry.addCategory(category)
            }
            
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        defer {
            currentElement = ""
            currentText = ""
        }

        guard let currentEntry = currentEntry else {
            return
        }

        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        case "entry":
            if let entry = currentEntry.build() {
                entries.append(entry)
            }
            self.currentEntry = nil

        case "id":
            // Extract arXiv ID from the full URL
            let arxivId = extractArxivId(from: text)
            currentEntry.setId(arxivId)

        case "title":
            currentEntry.setTitle(text)

        case "summary":
            currentEntry.setAbstract(text)

        case "published":
            if let date = parseDate(text) {
                currentEntry.setPublished(date)
            }

        case "updated":
            if let date = parseDate(text) {
                currentEntry.setUpdated(date)
            }

        case "name":
            // This is an author name within an <author> element
            if currentElement == "name" {
                let author = ArxivAuthor(name: text)
                currentEntry.addAuthor(author)
            }

        case "arxiv:comment":
            currentEntry.setComment(text)

        case "arxiv:journal_ref":
            currentEntry.setJournalReference(text)

        case "arxiv:doi":
            currentEntry.setDoi(text)

        case "arxiv:report_no":
            currentEntry.setReportNumber(text)

        case "arxiv:primary_category":
            // This is handled in didStartElement with attributes
            break
            
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        // Error handling is done in the parseEntries method
    }
    
    // MARK: - Helper Methods
    
    private func extractArxivId(from urlString: String) -> String {
        // Extract arXiv ID from URLs like "http://arxiv.org/abs/hep-ex/0307015v1" or "http://arxiv.org/abs/2301.12345v1"
        if let url = URL(string: urlString) {
            let pathComponents = url.pathComponents
            // Find the "abs" component and take everything after it
            if let absIndex = pathComponents.firstIndex(of: "abs"), absIndex + 1 < pathComponents.count {
                let idComponents = Array(pathComponents[(absIndex + 1)...])
                return idComponents.joined(separator: "/")
            }
        }
        return urlString
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        // Try primary format first
        if let date = dateFormatter.date(from: dateString) {
            return date
        }
        
        // Try alternate format with milliseconds
        if let date = alternateDateFormatter.date(from: dateString) {
            return date
        }
        
        return nil
    }
}

// MARK: - ArxivEntryBuilder

/// Helper class for building ArxivEntry objects during XML parsing
private class ArxivEntryBuilder {
    private var id: String?
    private var title: String?
    private var abstract: String?
    private var authors: [ArxivAuthor] = []
    private var published: Date?
    private var updated: Date?
    private var categories: [ArxivCategory] = []
    private var links: [ArxivLink] = []
    private var comment: String?
    private var journalReference: String?
    private var doi: String?
    private var reportNumber: String?
    
    func setId(_ id: String) {
        self.id = id
    }
    
    func setTitle(_ title: String) {
        self.title = title
    }
    
    func setAbstract(_ abstract: String) {
        self.abstract = abstract
    }
    
    func addAuthor(_ author: ArxivAuthor) {
        authors.append(author)
    }
    
    func setPublished(_ date: Date) {
        self.published = date
    }
    
    func setUpdated(_ date: Date) {
        self.updated = date
    }
    
    func addCategory(_ category: ArxivCategory) {
        categories.append(category)
    }
    
    func addLink(_ link: ArxivLink) {
        links.append(link)
    }
    
    func setComment(_ comment: String) {
        self.comment = comment.isEmpty ? nil : comment
    }
    
    func setJournalReference(_ journalRef: String) {
        self.journalReference = journalRef.isEmpty ? nil : journalRef
    }
    
    func setDoi(_ doi: String) {
        self.doi = doi.isEmpty ? nil : doi
    }
    
    func setReportNumber(_ reportNumber: String) {
        self.reportNumber = reportNumber.isEmpty ? nil : reportNumber
    }
    
    func build() -> ArxivEntry? {
        guard let id = id,
              let title = title,
              let abstract = abstract,
              let published = published,
              let updated = updated else {
            return nil
        }
        
        // Find primary category (usually the first one)
        let primaryCategory = categories.first
        
        return ArxivEntry(
            id: id,
            title: title,
            abstract: abstract,
            authors: authors,
            published: published,
            updated: updated,
            primaryCategory: primaryCategory,
            categories: categories,
            links: links,
            comment: comment,
            journalReference: journalReference,
            doi: doi,
            reportNumber: reportNumber
        )
    }
} 