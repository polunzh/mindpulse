import Foundation
import SwiftData

enum SubscriptionStatus: String, Codable {
    case free
    case trial
    case pro
    case expired
}

@Model
final class Subscription {
    @Attribute(.unique) var id: UUID
    var status: SubscriptionStatus
    var trialStart: Date?
    var expiresAt: Date?

    init(status: SubscriptionStatus = .free) {
        self.id = UUID()
        self.status = status
        self.trialStart = nil
        self.expiresAt = nil
    }

    var isPro: Bool {
        status == .pro || (status == .trial && !isExpired)
    }

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return Date() > expiresAt
    }
}
