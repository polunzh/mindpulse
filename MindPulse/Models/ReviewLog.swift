import Foundation
import SwiftData

enum ReviewResult: String, Codable {
    case remembered
    case forgot
}

@Model
final class ReviewLog {
    @Attribute(.unique) var id: UUID
    var card: Card?
    var result: ReviewResult
    var reviewedAt: Date

    init(card: Card, result: ReviewResult) {
        self.id = UUID()
        self.card = card
        self.result = result
        self.reviewedAt = Date()
    }
}
