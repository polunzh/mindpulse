import Foundation
import SwiftData

enum PromptType: String, Codable {
    case subscription
    case notification
}

enum UserAction: String, Codable {
    case tapped
    case dismissed
    case notInterested
}

@Model
final class PromptLog {
    @Attribute(.unique) var id: UUID
    var type: PromptType
    var shownAt: Date
    var action: UserAction

    init(type: PromptType, action: UserAction) {
        self.id = UUID()
        self.type = type
        self.shownAt = Date()
        self.action = action
    }
}
