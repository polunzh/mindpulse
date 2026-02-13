import Foundation
import SwiftData

@Model
final class Card {
    @Attribute(.unique) var id: UUID
    var source: Source?
    var question: String
    var answer: String
    var sourceQuote: String

    // SM-2 algorithm state
    var repetition: Int
    var easeFactor: Double
    var interval: Int
    var nextReviewDate: Date

    var createdAt: Date
    var isActive: Bool

    @Relationship(deleteRule: .cascade, inverse: \ReviewLog.card)
    var reviewLogs: [ReviewLog] = []

    init(
        question: String,
        answer: String,
        sourceQuote: String,
        source: Source? = nil
    ) {
        self.id = UUID()
        self.source = source
        self.question = question
        self.answer = answer
        self.sourceQuote = sourceQuote
        self.repetition = 0
        self.easeFactor = 2.5
        self.interval = 0
        self.nextReviewDate = Date()
        self.createdAt = Date()
        self.isActive = true
    }
}
