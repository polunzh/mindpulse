import Foundation
import SwiftData

@Model
final class DailyStatus {
    @Attribute(.unique) var id: UUID
    var date: Date
    var energyLevel: Double
    var keyword: String?
    var cardsReviewed: Int
    var cardsRemembered: Int
    var createdAt: Date

    init(
        date: Date = Calendar.current.startOfDay(for: Date()),
        energyLevel: Double,
        keyword: String? = nil,
        cardsReviewed: Int = 0,
        cardsRemembered: Int = 0
    ) {
        self.id = UUID()
        self.date = date
        self.energyLevel = energyLevel
        self.keyword = keyword
        self.cardsReviewed = cardsReviewed
        self.cardsRemembered = cardsRemembered
        self.createdAt = Date()
    }
}
