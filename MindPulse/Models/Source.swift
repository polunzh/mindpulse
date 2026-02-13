import Foundation
import SwiftData

enum SourceType: String, Codable {
    case text
    case url
}

@Model
final class Source {
    @Attribute(.unique) var id: UUID
    var type: SourceType
    var rawContent: String
    var extractedText: String
    var title: String?
    var domain: String?
    var tags: [String]
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Card.source)
    var cards: [Card] = []

    init(
        type: SourceType,
        rawContent: String,
        extractedText: String = "",
        title: String? = nil,
        domain: String? = nil,
        tags: [String] = []
    ) {
        self.id = UUID()
        self.type = type
        self.rawContent = rawContent
        self.extractedText = extractedText
        self.title = title
        self.domain = domain
        self.tags = tags
        self.createdAt = Date()
    }
}
